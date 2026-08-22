"""Feature engineering for the rate-of-decline signal.

The design decision that matters here, and the one worth defending: the
rate-of-change terms are computed on the *percentile* series, and the
percentile is computed against a day-of-year climatology. That ordering is
deliberate.

  * Percentile-first removes the seasonal cycle, so a 20-point fall in
    February means the same thing as a 20-point fall in June.
  * Differencing after that measures intensification velocity, which the
    literature identifies as the driver of flash drought, rather than
    absolute dryness, which is what conventional monitoring measures.

Reversing the order (difference the raw values, then normalise) would let the
seasonal amplitude dominate the deltas and would make summer look like a
permanent emergency.

This module is pure pandas. No Earth Engine, no network, so every function
here is unit-testable offline.
"""

from __future__ import annotations

import hashlib
import logging
import math

import numpy as np
import pandas as pd

from . import config

logger = logging.getLogger(__name__)

# Feature columns the model consumes, in a fixed order. The hash of this tuple
# is the feature-schema hash referenced by FR-PRED-003; if you change this
# tuple, previously trained models must not be served against it.
FEATURE_COLUMNS: tuple[str, ...] = (
    "sm_pctile",
    "sm_5day_delta",
    "sm_14day_delta",
    "vpd_anomaly_z",
    "vpd_5day_delta",
    "precip_deficit_30d",
    "ndvi_anomaly_z",
    "doy_sin",
    "doy_cos",
)


class FeatureEngineeringError(ValueError):
    """Raised when input data cannot support feature derivation."""


def feature_schema_hash() -> str:
    """Stable hash of the feature contract (FR-PRED-003, FR-FEAT-011).

    Both the fetch pipeline (`pipeline.run_fetch`) and the training pipeline
    (`train.run_train`) must derive this from the same function. Duplicating
    the hash logic in two places would let them drift silently, which is
    exactly the train-serve mismatch FR-PRED-003 exists to catch.
    """
    payload = "|".join(FEATURE_COLUMNS).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:16]


# --------------------------------------------------------------------------
# Physical transforms
# --------------------------------------------------------------------------


def saturation_vapour_pressure_kpa(temperature_c: pd.Series) -> pd.Series:
    """Saturation vapour pressure via the Tetens equation, in kPa.

    es = 0.6108 * exp(17.27 * T / (T + 237.3))

    Valid for liquid water above 0 C, which covers the Pakistani growing
    season. Below freezing the ice formulation differs, and we clip rather
    than silently extrapolate.
    """
    if temperature_c.isna().all():
        raise FeatureEngineeringError("temperature series is entirely missing")

    clipped = temperature_c.clip(lower=-40.0, upper=60.0)
    return 0.6108 * np.exp((17.27 * clipped) / (clipped + 237.3))


def vapour_pressure_deficit_kpa(
    temperature_c: pd.Series, dewpoint_c: pd.Series
) -> pd.Series:
    """Vapour pressure deficit in kPa.

    VPD = es(T_air) - es(T_dew). Dewpoint cannot physically exceed air
    temperature; where it does (a reanalysis artefact) we clamp to zero
    deficit rather than emitting a negative VPD that would invert the
    model's understanding of evaporative demand.
    """
    es_air = saturation_vapour_pressure_kpa(temperature_c)
    es_dew = saturation_vapour_pressure_kpa(dewpoint_c)
    return (es_air - es_dew).clip(lower=0.0)


# --------------------------------------------------------------------------
# Climatology and percentiles
# --------------------------------------------------------------------------


def day_of_year_percentile(
    series: pd.Series,
    dates: pd.Series,
    window_days: int = config.CLIMATOLOGY_DOY_WINDOW,
) -> pd.Series:
    """Percentile rank of each value against its own day-of-year climatology.

    For each observation we build the reference distribution from every year
    in the record falling within +/- window_days of the same day-of-year, and
    report where the current value sits in it (0-100).

    Leap years are handled by comparing on day-of-year with wraparound, which
    introduces at most a one-day offset after 28 February - immaterial at a
    +/-7 day window and far cheaper than a full calendar alignment.
    """
    if len(series) != len(dates):
        raise FeatureEngineeringError(
            f"series length {len(series)} does not match dates length {len(dates)}"
        )

    frame = pd.DataFrame({"value": series.to_numpy(), "date": pd.to_datetime(dates)})
    frame["doy"] = frame["date"].dt.dayofyear

    percentiles = np.full(len(frame), np.nan, dtype=float)
    values = frame["value"].to_numpy(dtype=float)
    doys = frame["doy"].to_numpy(dtype=int)

    for index in range(len(frame)):
        current = values[index]
        if math.isnan(current):
            continue

        # Circular day-of-year distance, so late December compares with early
        # January instead of falling off the end of the year.
        distance = np.abs(doys - doys[index])
        circular_distance = np.minimum(distance, 366 - distance)
        reference = values[(circular_distance <= window_days) & ~np.isnan(values)]

        if reference.size < 10:
            # Too thin a climatology to rank against honestly. Left as NaN so
            # the completeness ratio reflects it.
            continue

        percentiles[index] = float((reference < current).mean() * 100.0)

    coverage = float(np.isfinite(percentiles).mean()) if len(percentiles) else 0.0
    logger.info("Day-of-year percentile coverage: %.1f%%", coverage * 100.0)
    return pd.Series(percentiles, index=series.index, name="pctile")


def standardised_anomaly(
    series: pd.Series,
    dates: pd.Series,
    window_days: int = config.CLIMATOLOGY_DOY_WINDOW,
) -> pd.Series:
    """Z-score of each value against its day-of-year climatology."""
    if len(series) != len(dates):
        raise FeatureEngineeringError("series and dates lengths differ")

    frame = pd.DataFrame({"value": series.to_numpy(), "date": pd.to_datetime(dates)})
    frame["doy"] = frame["date"].dt.dayofyear

    values = frame["value"].to_numpy(dtype=float)
    doys = frame["doy"].to_numpy(dtype=int)
    anomalies = np.full(len(frame), np.nan, dtype=float)

    for index in range(len(frame)):
        current = values[index]
        if math.isnan(current):
            continue

        distance = np.abs(doys - doys[index])
        circular_distance = np.minimum(distance, 366 - distance)
        reference = values[(circular_distance <= window_days) & ~np.isnan(values)]

        if reference.size < 10:
            continue

        mean = float(reference.mean())
        std = float(reference.std(ddof=1))
        if std <= 1e-9:
            anomalies[index] = 0.0
        else:
            anomalies[index] = (current - mean) / std

    return pd.Series(anomalies, index=series.index, name="anomaly_z")


# --------------------------------------------------------------------------
# Rate-of-change
# --------------------------------------------------------------------------


def rate_of_change(series: pd.Series, window_days: int) -> pd.Series:
    """Change in the series over the preceding window_days.

    Negative values denote decline. This is the core signal: a large negative
    sm_5day_delta means the soil is losing water fast, regardless of whether
    its absolute level is still nominally adequate - which is precisely the
    situation conventional level-based monitoring misses.

    Assumes a daily, gap-free index. Call ensure_daily_index first.
    """
    if window_days < 1:
        raise FeatureEngineeringError(f"window_days must be >= 1, got {window_days}")
    return series - series.shift(window_days)


def ensure_daily_index(frame: pd.DataFrame, date_column: str = "date") -> pd.DataFrame:
    """Reindex to a contiguous daily calendar, inserting NaN for absent days.

    Shifting by N rows only equals shifting by N days if no day is missing.
    Every rate calculation depends on that, so this runs before any diff.
    """
    if date_column not in frame.columns:
        raise FeatureEngineeringError(f"missing {date_column!r} column")

    working = frame.copy()
    working[date_column] = pd.to_datetime(working[date_column])
    working = working.drop_duplicates(subset=[date_column]).sort_values(date_column)

    if working.empty:
        raise FeatureEngineeringError("cannot reindex an empty frame")

    full_index = pd.date_range(
        start=working[date_column].min(),
        end=working[date_column].max(),
        freq="D",
        name=date_column,
    )
    inserted = len(full_index) - len(working)
    if inserted > 0:
        logger.warning("Inserted %d absent calendar days as NaN", inserted)

    return (
        working.set_index(date_column)
        .reindex(full_index)
        .reset_index()
        .rename(columns={"index": date_column})
    )


def carry_forward_limited(
    frame: pd.DataFrame,
    columns: list[str],
    max_days: int = config.MAX_CARRY_FORWARD_DAYS,
) -> pd.DataFrame:
    """Forward-fill gaps, but never beyond max_days (FR-INGE-005, DQ-06).

    Beyond the limit the value stays NaN, which drives completeness below
    threshold and makes the cell report "not enough data" rather than
    inventing a plausible number.
    """
    working = frame.copy()
    for column in columns:
        if column not in working.columns:
            raise FeatureEngineeringError(f"cannot fill missing column {column!r}")
        working[column] = working[column].ffill(limit=max_days)
    return working


# --------------------------------------------------------------------------
# Assembly
# --------------------------------------------------------------------------


def build_feature_frame(
    soil_moisture: pd.DataFrame,
    meteorology: pd.DataFrame,
    precipitation: pd.DataFrame,
    vegetation: pd.DataFrame | None = None,
) -> pd.DataFrame:
    """Join every source and derive the full feature set.

    Returns one row per calendar day with FEATURE_COLUMNS populated, plus a
    completeness_ratio and a scorable flag.
    """
    merged = soil_moisture.copy()
    for other in (meteorology, precipitation):
        merged = merged.merge(other, on="date", how="outer")
    if vegetation is not None:
        merged = merged.merge(vegetation, on="date", how="outer")
    else:
        merged["ndvi"] = np.nan

    merged = ensure_daily_index(merged)
    merged = carry_forward_limited(
        merged, ["sm_surface", "sm_rootzone", "t2m_c", "d2m_c", "ndvi"]
    )

    if merged["sm_surface"].notna().sum() < 30:
        raise FeatureEngineeringError(
            "fewer than 30 valid soil-moisture days; cannot build a climatology"
        )

    # --- soil moisture: smooth, then percentile, then rate ---------------
    # Smoothing before differencing is not cosmetic. Retrieval noise in the
    # raw product propagates into the percentile transform amplified, because
    # a small absolute wobble near the middle of the climatological
    # distribution moves the rank a long way. Differencing an unsmoothed
    # percentile series then manufactures 20-point "drops" from pure noise and
    # floods the label with false positives - observed at a 72% positive rate
    # on noisy input during development, against a true base rate of a few
    # percent. A centred 5-day mean removes that without blunting the
    # multi-week intensification the signal is designed to catch.
    merged["sm_smoothed"] = (
        merged["sm_surface"].rolling(window=5, center=True, min_periods=3).mean()
    )
    merged["sm_pctile"] = day_of_year_percentile(merged["sm_smoothed"], merged["date"])
    for window in config.RATE_WINDOWS_DAYS:
        merged[f"sm_{window}day_delta"] = rate_of_change(merged["sm_pctile"], window)

    # --- evaporative demand ---------------------------------------------
    merged["vpd_kpa"] = vapour_pressure_deficit_kpa(merged["t2m_c"], merged["d2m_c"])
    merged["vpd_anomaly_z"] = standardised_anomaly(merged["vpd_kpa"], merged["date"])
    merged["vpd_5day_delta"] = rate_of_change(merged["vpd_anomaly_z"], 5)

    # --- precipitation deficit -------------------------------------------
    rolling_30d = merged["precip_mm"].rolling(window=30, min_periods=15).sum()
    climatological_30d = rolling_30d.mean()
    merged["precip_deficit_30d"] = climatological_30d - rolling_30d

    # --- vegetation (degraded-mode proxy) --------------------------------
    if merged["ndvi"].notna().sum() >= 30:
        merged["ndvi_anomaly_z"] = standardised_anomaly(merged["ndvi"], merged["date"])
    else:
        logger.warning("Insufficient NDVI; vegetation feature left empty")
        merged["ndvi_anomaly_z"] = np.nan

    # --- seasonal context -------------------------------------------------
    day_of_year = merged["date"].dt.dayofyear
    merged["doy_sin"] = np.sin(2.0 * np.pi * day_of_year / 365.25)
    merged["doy_cos"] = np.cos(2.0 * np.pi * day_of_year / 365.25)

    # --- completeness gate (FR-FEAT-009 / FR-FEAT-010) --------------------
    merged["completeness_ratio"] = (
        merged[list(FEATURE_COLUMNS)].notna().sum(axis=1) / len(FEATURE_COLUMNS)
    )
    merged["scorable"] = merged["completeness_ratio"] >= config.MIN_COMPLETENESS_RATIO

    scorable_count = int(merged["scorable"].sum())
    logger.info(
        "Built %d rows, %d scorable (%.1f%%)",
        len(merged),
        scorable_count,
        100.0 * scorable_count / max(len(merged), 1),
    )
    return merged


def label_rapid_intensification(
    frame: pd.DataFrame,
    horizon_days: int = config.PREDICTION_HORIZON_DAYS,
    drop_threshold: float = config.RAPID_INTENSIFICATION_DROP_PCTILE,
) -> pd.DataFrame:
    """Attach the supervised target: does soil moisture crash within the horizon?

    Label is True when the minimum percentile over the forward horizon falls
    at least `drop_threshold` points below today's percentile.

    LEAKAGE WARNING (DQ-04). The label looks forward; the features look
    backward. They must never share a window. Any split of this frame for
    training must be temporal - a random shuffle places tomorrow's label
    beside today's features in the training set and produces validation scores
    that collapse the moment the model is deployed. See train.py, which
    refuses to run on a shuffled split.
    """
    if horizon_days < 1:
        raise FeatureEngineeringError(f"horizon_days must be >= 1, got {horizon_days}")
    if "sm_pctile" not in frame.columns:
        raise FeatureEngineeringError("sm_pctile is required to derive the label")

    working = frame.copy()

    # Minimum of the strictly-future window [t+1, t+horizon].
    future_minimum = (
        working["sm_pctile"]
        .shift(-1)
        .rolling(window=horizon_days, min_periods=horizon_days // 2)
        .min()
        .shift(-(horizon_days - 1))
    )

    working["future_min_pctile"] = future_minimum
    working["pctile_drop"] = working["sm_pctile"] - future_minimum

    # Three conditions, not one. A bare "fell 20 points" criterion also fires
    # on ordinary seasonal dry-down: measured against a realistic
    # autocorrelated soil-water series it labelled 40% of all days positive,
    # against a true flash-drought base rate of a few percent. A model trained
    # on that learns "it is usually drying", which is useless as a warning.
    #
    # The two-sided form below follows the standard definition in the flash
    # drought literature (Otkin et al.): the cell must *start* in a
    # non-drought state, *end* in drought, and get there fast.
    started_wet = working["sm_pctile"] >= config.LABEL_START_ABOVE_PCTILE
    ended_dry = future_minimum <= config.LABEL_END_BELOW_PCTILE
    fell_fast = working["pctile_drop"] >= drop_threshold

    # Nullable boolean, not plain bool. Rows whose forward window extends past
    # the end of the record have no honest label; they must be excluded from
    # training rather than silently defaulted to False, which would teach the
    # model that the most recent period is always safe.
    label = (started_wet & ended_dry & fell_fast).astype("boolean")
    label[future_minimum.isna() | working["sm_pctile"].isna()] = pd.NA
    working["is_rapid_intensification"] = label

    labelled = working["is_rapid_intensification"].notna()
    positives = int((working["is_rapid_intensification"] == True).sum())  # noqa: E712
    logger.info(
        "Labelled %d rows, %d positive (%.2f%% positive rate)",
        int(labelled.sum()),
        positives,
        100.0 * positives / max(int(labelled.sum()), 1),
    )
    return working
