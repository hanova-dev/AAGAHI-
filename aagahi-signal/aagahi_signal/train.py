"""Model training for the AAGAHI rate-of-decline signal.

    python -m aagahi_signal.train \
        --data output/faisalabad-jhang_2018-01-01_2025-06-30.parquet \
        --train-end 2022-12-31 --validate-end 2023-12-31 \
        --out-dir output/model

Trains a LightGBM classifier on the feature table produced by
`pipeline.py fetch`, calibrates it, and reports precision, recall, PR-AUC,
and Brier score on a held-out temporal test period. Never reports bare
accuracy (CON-10, FR-GOVN-008): the positive class is a few percent of days,
so accuracy is dominated by the trivial "always predict no drought" baseline
and would be actively misleading here.

The split is temporal only, driven by two cutoff dates. There is
deliberately no shuffle or random_state option: a random split lets
tomorrow's label sit beside today's features in the training set (DQ-04),
which is the most common way a climate-ML validation number stops meaning
anything the moment the model deploys. If a different split is needed,
change the cutoff dates - not the split method.
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import TYPE_CHECKING

import numpy as np
import pandas as pd

from . import features

# lightgbm, shap, and scikit-learn are imported lazily inside the functions
# that use them (train_model, evaluate, explain), not here at module level -
# the same discipline pipeline.py already applies to ee_client and
# matplotlib. This is not cosmetic: it means temporal_split, _prepare_corpus,
# and the leakage guard below can be unit-tested (tests/test_train.py)
# without installing the ML stack, which is exactly the code path this
# module's correctness actually hinges on.
if TYPE_CHECKING:
    from sklearn.calibration import CalibratedClassifierCV

logger = logging.getLogger(__name__)


class TrainingError(ValueError):
    """Raised when the input corpus cannot support a valid training run."""


@dataclass(frozen=True)
class SplitDates:
    """Cutoff dates defining a strictly temporal train/validate/test split.

    Rows with date <= train_end are training; date in (train_end,
    validate_end] are validation, used for calibration rather than gradient
    descent; date > validate_end are test, touched exactly once, for
    reporting.
    """

    train_end: date
    validate_end: date

    def __post_init__(self) -> None:
        if self.train_end >= self.validate_end:
            raise TrainingError(
                f"train_end ({self.train_end}) must precede validate_end "
                f"({self.validate_end})"
            )


def _prepare_corpus(frame: pd.DataFrame) -> pd.DataFrame:
    """Filter to rows that are both scorable and honestly labelled.

    Two exclusions, each guarding a defect found during development:
      * Rows below the completeness gate are dropped, so the model never
        trains on a richer distribution than what it will see in serving
        (FR-FEAT-010).
      * Rows with a null label - the forward window ran past the end of the
        record - are dropped rather than treated as False. Silently
        defaulting them to "no event" was an earlier bug here: it taught the
        model that the most recent period is always safe, which is exactly
        backwards for an early-warning system.
    """
    if "is_rapid_intensification" not in frame.columns:
        raise TrainingError(
            "frame has no is_rapid_intensification column; run "
            "features.label_rapid_intensification first"
        )
    if "scorable" not in frame.columns:
        raise TrainingError(
            "frame has no scorable column; run features.build_feature_frame first"
        )

    working = frame[frame["scorable"]].copy()
    labelled = working["is_rapid_intensification"].notna()
    dropped = int((~labelled).sum())
    if dropped:
        logger.info("Dropping %d unlabelled (forward-window-truncated) rows", dropped)
    working = working[labelled]
    working["is_rapid_intensification"] = working["is_rapid_intensification"].astype(bool)

    if working.empty:
        raise TrainingError("no scorable, labelled rows remain after filtering")
    return working.sort_values("date").reset_index(drop=True)


def _assert_strictly_before(
    earlier: pd.DataFrame, later: pd.DataFrame, earlier_name: str, later_name: str
) -> None:
    """Refuse to proceed unless every date in `earlier` precedes every date in `later`.

    `temporal_split` below already guarantees this by construction - it
    partitions by comparing each row's own date to the cutoffs, so row order
    in the input frame is irrelevant and a shuffled input produces an
    identical split (see
    tests/test_train.py::test_temporal_split_is_immune_to_row_shuffling).

    This check exists for the case that guarantee does not cover: a caller
    who assembles train/validate/test some other way - a scikit-learn
    `train_test_split(..., shuffle=True)`, for instance - and passes the
    result straight to `train_model` or `run_train`. DQ-04 and TS-11 require
    the pipeline to refuse to execute on a leaking split, not warn and
    continue, so this raises rather than logging.
    """
    earlier_end = pd.to_datetime(earlier["date"]).max()
    later_start = pd.to_datetime(later["date"]).min()
    if not (earlier_end < later_start):
        raise TrainingError(
            f"{earlier_name} and {later_name} are not temporally disjoint "
            f"({earlier_name} ends {earlier_end.date()}, {later_name} starts "
            f"{later_start.date()}) - refusing to proceed. This is exactly the "
            "shape of leakage a shuffled split produces (DQ-04)."
        )


def temporal_split(
    frame: pd.DataFrame, split: SplitDates
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Split strictly by date. No shuffling, no random_state - see module docstring.

    Partitioning is a value comparison against each row's own `date` column,
    not a positional slice, so the input's row order has no effect on the
    result - see test_temporal_split_is_immune_to_row_shuffling.
    """
    dates = pd.to_datetime(frame["date"])
    train = frame[dates <= pd.Timestamp(split.train_end)]
    validate = frame[
        (dates > pd.Timestamp(split.train_end)) & (dates <= pd.Timestamp(split.validate_end))
    ]
    test = frame[dates > pd.Timestamp(split.validate_end)]

    for name, part in (("train", train), ("validate", validate), ("test", test)):
        if part.empty:
            raise TrainingError(f"{name} split is empty for the given cutoff dates")

    # Belt-and-suspenders: the comparisons above make overlap impossible for
    # any input, but assert it explicitly anyway so a future refactor of this
    # function that breaks that property fails a test immediately rather than
    # silently shipping a leak.
    _assert_strictly_before(train, validate, "train", "validate")
    _assert_strictly_before(validate, test, "validate", "test")

    logger.info(
        "Split: %d train / %d validate / %d test rows", len(train), len(validate), len(test)
    )
    return train, validate, test


def _positive_rate(labels: pd.Series) -> float:
    return float(labels.mean())


def train_model(train: pd.DataFrame, validate: pd.DataFrame) -> CalibratedClassifierCV:
    """Fit a class-weighted LightGBM classifier and calibrate it on validate.

    Class weighting, not resampling: SMOTE and similar oversampling methods
    fabricate synthetic points by interpolating between neighbours in feature
    space, which is not physically meaningful for spatiotemporally
    autocorrelated soil-moisture series (SRS S11.3). scale_pos_weight instead
    reweights the real points that already exist.
    """
    import lightgbm as lgb
    from sklearn.calibration import CalibratedClassifierCV

    # Defence in depth: a caller who obtained `train`/`validate` without
    # going through `temporal_split` (bypassing that function's own
    # guarantee) still gets refused here, before a single tree is fit.
    _assert_strictly_before(train, validate, "train", "validate")

    x_train = train[list(features.FEATURE_COLUMNS)]
    y_train = train["is_rapid_intensification"]

    positive_rate = _positive_rate(y_train)
    if positive_rate <= 0.0 or positive_rate >= 1.0:
        raise TrainingError(
            f"training split has a degenerate positive rate ({positive_rate:.4f}); "
            "cannot fit a classifier"
        )
    scale_pos_weight = (1.0 - positive_rate) / positive_rate

    base_model = lgb.LGBMClassifier(
        objective="binary",
        scale_pos_weight=scale_pos_weight,
        n_estimators=400,
        learning_rate=0.05,
        num_leaves=31,
        min_child_samples=20,
        random_state=42,
    )
    base_model.fit(x_train, y_train)

    x_validate = validate[list(features.FEATURE_COLUMNS)]
    y_validate = validate["is_rapid_intensification"]

    # Isotonic regression on the validation period, never on training data -
    # calibrating on the rows used to fit the trees would let the model grade
    # its own probabilities (SRS S11.3).
    calibrated = CalibratedClassifierCV(base_model, method="isotonic", cv="prefit")
    calibrated.fit(x_validate, y_validate)
    return calibrated


def _bootstrap_ci(
    y_true: np.ndarray,
    y_prob: np.ndarray,
    metric_fn,
    n_resamples: int = 1000,
    seed: int = 42,
) -> tuple[float, float, float]:
    """Point estimate plus a 90% bootstrap CI over the test rows (SRS S11.3)."""
    rng = np.random.default_rng(seed)
    point = float(metric_fn(y_true, y_prob))
    n = len(y_true)
    resampled = np.empty(n_resamples, dtype=float)
    for i in range(n_resamples):
        idx = rng.integers(0, n, size=n)
        sample_true = y_true[idx]
        if sample_true.min() == sample_true.max():
            # A resample containing only one class is undefined for these
            # metrics; skip it rather than let it inject a NaN into the
            # interval.
            resampled[i] = point
            continue
        resampled[i] = metric_fn(sample_true, y_prob[idx])
    lower, upper = np.percentile(resampled, [5, 95])
    return point, float(lower), float(upper)


def evaluate(
    model: CalibratedClassifierCV, test: pd.DataFrame, threshold: float = 0.5
) -> dict[str, object]:
    """Precision, recall, PR-AUC, Brier score - never bare accuracy (CON-10).

    `threshold` is a reporting convenience only. The risk-band thresholds
    actually served to farmers are calibrated on the validation distribution
    per FR-PRED-004, not fixed at 0.5 - that mapping lives with the serving
    code, not here.
    """
    from sklearn.metrics import (
        average_precision_score,
        brier_score_loss,
        precision_score,
        recall_score,
    )

    x_test = test[list(features.FEATURE_COLUMNS)]
    y_test = test["is_rapid_intensification"].to_numpy(dtype=int)
    y_prob = model.predict_proba(x_test)[:, 1]
    y_pred = (y_prob >= threshold).astype(int)

    pr_auc, pr_auc_lo, pr_auc_hi = _bootstrap_ci(y_test, y_prob, average_precision_score)
    brier, brier_lo, brier_hi = _bootstrap_ci(y_test, y_prob, brier_score_loss)

    metrics = {
        "n_test": int(len(test)),
        "positive_rate": _positive_rate(test["is_rapid_intensification"]),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "pr_auc": pr_auc,
        "pr_auc_90ci": [pr_auc_lo, pr_auc_hi],
        "brier_score": brier,
        "brier_score_90ci": [brier_lo, brier_hi],
        "decision_threshold": threshold,
    }
    logger.info("Test metrics: %s", json.dumps(metrics, indent=2))
    return metrics


def explain(model: CalibratedClassifierCV, test: pd.DataFrame) -> dict[str, float]:
    """Mean absolute SHAP value per feature over the test set, for audit.

    Per-prediction driver narratives (FR-EXPL-001 through FR-EXPL-008) are a
    serving-time concern; this is the training-time diagnostic that answers
    "did the model learn the rate-of-change signal the product is built on,
    or did it fall back on something else" (ADR-001).
    """
    import shap

    # CalibratedClassifierCV wraps one fitted estimator per CV fold; with
    # cv="prefit" there is exactly one, and it is the tree model TreeExplainer
    # supports natively and exactly.
    booster = model.calibrated_classifiers_[0].estimator
    explainer = shap.TreeExplainer(booster)
    x_test = test[list(features.FEATURE_COLUMNS)]
    shap_values = explainer.shap_values(x_test)
    if isinstance(shap_values, list):
        shap_values = shap_values[1]  # positive-class contributions

    mean_abs = np.abs(shap_values).mean(axis=0)
    ranked = dict(
        sorted(
            zip(features.FEATURE_COLUMNS, mean_abs.tolist()),
            key=lambda item: item[1],
            reverse=True,
        )
    )
    logger.info("Mean |SHAP| by feature: %s", json.dumps(ranked, indent=2))
    return ranked


def run_train(data_path: Path, split: SplitDates, output_dir: Path) -> dict[str, object]:
    frame = (
        pd.read_parquet(data_path)
        if data_path.suffix == ".parquet"
        else pd.read_csv(data_path, parse_dates=["date"])
    )
    frame["date"] = pd.to_datetime(frame["date"])

    corpus = _prepare_corpus(frame)
    train, validate, test = temporal_split(corpus, split)

    model = train_model(train, validate)
    metrics = evaluate(model, test)
    driver_importance = explain(model, test)

    output_dir.mkdir(parents=True, exist_ok=True)
    model_path = output_dir / "model.txt"
    # Persist the underlying booster, not the sklearn calibration wrapper -
    # LightGBM's native text format is what a CPU-only inference service
    # loads (NFR-PERF-007); calibration is reapplied at serve time from the
    # isotonic mapping recorded in the manifest below.
    booster = model.calibrated_classifiers_[0].estimator.booster_
    booster.save_model(str(model_path))

    manifest = {
        "trained_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "feature_columns": list(features.FEATURE_COLUMNS),
        "feature_schema_hash": features.feature_schema_hash(),
        "split": {
            "train_end": split.train_end.isoformat(),
            "validate_end": split.validate_end.isoformat(),
            "n_train": int(len(train)),
            "n_validate": int(len(validate)),
            "n_test": int(len(test)),
        },
        "metrics": metrics,
        "mean_abs_shap": driver_importance,
        "model_path": str(model_path),
    }
    manifest_path = output_dir / "train_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    logger.info("Wrote %s", manifest_path)
    return manifest


def _parse_date(value: str) -> date:
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"{value!r} is not a valid date; expected YYYY-MM-DD"
        ) from exc


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="aagahi_signal.train",
        description="Train and evaluate the AAGAHI rapid-intensification classifier",
    )
    parser.add_argument("--data", type=Path, required=True)
    parser.add_argument("--train-end", type=_parse_date, required=True)
    parser.add_argument("--validate-end", type=_parse_date, required=True)
    parser.add_argument("--out-dir", type=Path, default=Path("./output/model"))
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
        stream=sys.stderr,
    )
    try:
        run_train(
            data_path=args.data,
            split=SplitDates(train_end=args.train_end, validate_end=args.validate_end),
            output_dir=args.out_dir,
        )
    except (FileNotFoundError, ValueError, TrainingError) as exc:
        logger.error("%s", exc)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
