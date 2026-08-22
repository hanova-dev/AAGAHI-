"""Pipeline orchestration and the validation chart.

Two entry points:

    python -m aagahi_signal.pipeline fetch
        Pull Earth Observation data, build features, write Parquet + CSV.

    python -m aagahi_signal.pipeline validate --event-start 2024-05-01 \
            --event-end 2024-06-15
        Render the chart that is the entire technical claim of the submission:
        does the rate-of-decline signal turn down *before* a known event?

The validate step is what goes in the competition video. One chart, one real
event, one honest lead time.
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from dataclasses import asdict
from datetime import date, datetime
from pathlib import Path

import pandas as pd

from . import config, features

# NOTE: ee_client is imported lazily inside run_fetch. The `validate` command
# operates entirely on a local feature file and must not require the
# earthengine-api package to be installed, so that a reviewer can reproduce
# the chart from the shipped Parquet without any Google credentials.

logger = logging.getLogger(__name__)


def _configure_logging(verbose: bool) -> None:
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
        stream=sys.stderr,
    )


def _parse_date(value: str) -> date:
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"{value!r} is not a valid date; expected YYYY-MM-DD"
        ) from exc


# --------------------------------------------------------------------------
# Fetch
# --------------------------------------------------------------------------


def run_fetch(settings: config.PipelineSettings) -> Path:
    """Fetch, derive, label, and persist. Returns the Parquet path."""
    from .ee_client import EarthEngineError, EEClient

    settings.output_dir.mkdir(parents=True, exist_ok=True)

    client = EEClient(settings)
    client.initialise()

    start, end = settings.start_date, settings.end_date
    logger.info("Fetching %s from %s to %s", settings.region.name, start, end)

    soil_moisture = client.fetch_soil_moisture(start, end)
    meteorology = client.fetch_temperature_and_dewpoint(start, end)
    precipitation = client.fetch_precipitation(start, end)

    try:
        vegetation = client.fetch_ndvi(start, end)
    except EarthEngineError as exc:
        # Vegetation is a supporting feature, not a blocking one. The model
        # handles its absence natively; the confidence penalty is recorded.
        logger.warning("NDVI unavailable, continuing in reduced-feature mode: %s", exc)
        vegetation = None

    frame = features.build_feature_frame(
        soil_moisture=soil_moisture,
        meteorology=meteorology,
        precipitation=precipitation,
        vegetation=vegetation,
    )
    frame = features.label_rapid_intensification(frame)
    frame["region"] = settings.region.name

    stem = f"{settings.region.name.lower().replace(' ', '-')}_{start}_{end}"
    parquet_path = settings.output_dir / f"{stem}.parquet"
    csv_path = settings.output_dir / f"{stem}.csv"

    try:
        frame.to_parquet(parquet_path, index=False)
    except (ImportError, ValueError) as exc:
        logger.warning("Parquet write failed (%s); CSV only", exc)
        parquet_path = csv_path
    frame.to_csv(csv_path, index=False)

    manifest = {
        "region": asdict(settings.region),
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
        "rows": int(len(frame)),
        "scorable_rows": int(frame["scorable"].sum()),
        "positive_labels": int((frame["is_rapid_intensification"] == True).sum()),  # noqa: E712
        "feature_columns": list(features.FEATURE_COLUMNS),
        "feature_schema_hash": features.feature_schema_hash(),
        "vegetation_mode": "ndvi" if vegetation is not None else "absent",
        "sif_available": config.SIF_ASSET_ID is not None,
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
    }
    (settings.output_dir / f"{stem}_manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )

    logger.info("Wrote %s (%d rows)", parquet_path, len(frame))
    return parquet_path


# --------------------------------------------------------------------------
# Validate
# --------------------------------------------------------------------------


def run_validate(
    data_path: Path,
    event_start: date,
    event_end: date,
    output_path: Path,
    context_days: int = 120,
) -> dict[str, object]:
    """Render the lead-time chart and return the measured lead time.

    The claim being tested: on a real historical drying event, did the
    5-day rate-of-decline term cross its warning threshold before the event
    window opened? If it did not, say so - a negative result reported
    honestly is worth more than a positive one that does not replicate.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.dates as mdates
    import matplotlib.pyplot as plt

    if not data_path.is_file():
        raise FileNotFoundError(f"No feature file at {data_path}; run `fetch` first")

    frame = (
        pd.read_parquet(data_path)
        if data_path.suffix == ".parquet"
        else pd.read_csv(data_path, parse_dates=["date"])
    )
    frame["date"] = pd.to_datetime(frame["date"])
    frame = frame.sort_values("date").reset_index(drop=True)

    required = {"date", "sm_pctile", "sm_5day_delta", "vpd_anomaly_z"}
    missing = required - set(frame.columns)
    if missing:
        raise ValueError(f"Feature file is missing columns: {sorted(missing)}")

    event_start_ts = pd.Timestamp(event_start)
    event_end_ts = pd.Timestamp(event_end)
    if event_start_ts >= event_end_ts:
        raise ValueError("event_start must precede event_end")

    # Warning threshold: the 15th percentile of the observed delta
    # distribution. Derived from the data, not chosen as a round number
    # (FR-PRED-004).
    delta = frame["sm_5day_delta"].dropna()
    if delta.empty:
        raise ValueError("sm_5day_delta is entirely missing; cannot validate")
    warning_threshold = float(delta.quantile(0.15))

    # First threshold crossing in the 60 days before the event opens.
    lookback = frame[
        (frame["date"] >= event_start_ts - pd.Timedelta(days=60))
        & (frame["date"] < event_start_ts)
        & (frame["sm_5day_delta"] <= warning_threshold)
    ]
    if lookback.empty:
        first_warning = None
        lead_time_days = None
        logger.warning(
            "Signal did NOT cross the warning threshold before %s. "
            "Report this result as-is.",
            event_start,
        )
    else:
        first_warning = lookback["date"].iloc[0]
        lead_time_days = int((event_start_ts - first_warning).days)
        logger.info("First warning %s, lead time %d days", first_warning.date(), lead_time_days)

    # ---- figure -------------------------------------------------------
    plt.rcParams.update(
        {
            "figure.facecolor": "#0B140F",
            "axes.facecolor": "#0F1E16",
            "savefig.facecolor": "#0B140F",
            "text.color": "#EDF5EF",
            "axes.labelcolor": "#B6CCBE",
            "xtick.color": "#87A091",
            "ytick.color": "#87A091",
            "axes.edgecolor": "#2A3B31",
            "font.size": 10,
        }
    )
    figure, (upper, lower) = plt.subplots(
        2, 1, figsize=(11, 7), sharex=True, gridspec_kw={"height_ratios": [2, 1.4]}
    )

    upper.plot(
        frame["date"], frame["sm_pctile"], color="#9BDCAE", linewidth=1.9,
        label="Soil moisture percentile",
    )
    upper.axvspan(
        event_start_ts, event_end_ts, color="#CB4830", alpha=0.18,
        label="Observed drying event",
    )
    if first_warning is not None:
        upper.axvline(first_warning, color="#E2934A", linestyle="--", linewidth=1.8)
        upper.annotate(
            f"Signal fires\n{lead_time_days} days early",
            xy=(first_warning, 88),
            xytext=(8, 0),
            textcoords="offset points",
            color="#E2934A",
            fontsize=9,
            fontweight="bold",
        )
    upper.set_ylabel("Percentile (0-100)")
    upper.set_ylim(0, 100)
    upper.set_title(
        "AAGAHI rate-of-decline signal against a known drying event",
        color="#EDF5EF", fontsize=13, fontweight="bold", pad=14,
    )
    upper.legend(loc="lower left", framealpha=0.2, facecolor="#16281E", edgecolor="#2A3B31")
    upper.grid(alpha=0.12)

    lower.plot(
        frame["date"], frame["sm_5day_delta"], color="#E2934A", linewidth=1.7,
        label="5-day change in percentile",
    )
    lower.axhline(
        warning_threshold, color="#E7CB7E", linestyle=":", linewidth=1.6,
        label=f"Warning threshold ({warning_threshold:.1f} pts / 5 d)",
    )
    lower.axhline(0, color="#2A3B31", linewidth=1)
    lower.axvspan(event_start_ts, event_end_ts, color="#CB4830", alpha=0.18)
    lower.set_ylabel("Change (pts / 5 d)")
    lower.set_xlabel("Date")
    lower.legend(loc="lower left", framealpha=0.2, facecolor="#16281E", edgecolor="#2A3B31")
    lower.grid(alpha=0.12)
    lower.xaxis.set_major_formatter(mdates.DateFormatter("%d %b %Y"))

    # Zoom to the event plus surrounding context. Showing the whole record
    # buries the one thing the chart exists to demonstrate.
    if context_days > 0:
        lower.set_xlim(
            event_start_ts - pd.Timedelta(days=context_days),
            event_end_ts + pd.Timedelta(days=context_days // 3),
        )
        figure.autofmt_xdate(rotation=25)

    figure.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output_path, dpi=170)
    plt.close(figure)

    result: dict[str, object] = {
        "event_start": event_start.isoformat(),
        "event_end": event_end.isoformat(),
        "warning_threshold_pts_per_5d": round(warning_threshold, 2),
        "first_warning": first_warning.date().isoformat() if first_warning is not None else None,
        "lead_time_days": lead_time_days,
        "signal_fired_before_event": first_warning is not None,
        "chart": str(output_path),
    }
    logger.info("Validation result: %s", json.dumps(result, indent=2))
    return result


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="aagahi_signal.pipeline",
        description="AAGAHI flash-drought rate-of-decline signal pipeline",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    subparsers = parser.add_subparsers(dest="command", required=True)

    fetch = subparsers.add_parser("fetch", help="Fetch EO data and build features")
    fetch.add_argument("--start", type=_parse_date, default=date(2018, 1, 1))
    fetch.add_argument(
        "--end", type=_parse_date, default=date.today().replace(day=1)
    )
    fetch.add_argument("--output-dir", type=Path, default=Path("./output"))

    validate = subparsers.add_parser("validate", help="Render the lead-time chart")
    validate.add_argument("--data", type=Path, required=True)
    validate.add_argument("--event-start", type=_parse_date, required=True)
    validate.add_argument("--event-end", type=_parse_date, required=True)
    validate.add_argument("--out", type=Path, default=Path("./output/lead_time.png"))
    validate.add_argument(
        "--context-days",
        type=int,
        default=120,
        help="Days of context either side of the event; 0 plots the full record",
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    _configure_logging(args.verbose)

    try:
        if args.command == "fetch":
            settings = config.PipelineSettings(
                start_date=args.start,
                end_date=args.end,
                output_dir=args.output_dir,
            )
            path = run_fetch(settings)
            print(path)
        elif args.command == "validate":
            result = run_validate(
                data_path=args.data,
                event_start=args.event_start,
                event_end=args.event_end,
                output_path=args.out,
                context_days=args.context_days,
            )
            print(json.dumps(result, indent=2))
        else:  # pragma: no cover - argparse enforces this
            raise ValueError(f"unknown command {args.command!r}")
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        logger.error("%s", exc)
        return 1
    except KeyboardInterrupt:
        logger.warning("Interrupted")
        return 130

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
