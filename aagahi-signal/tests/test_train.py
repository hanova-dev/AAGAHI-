"""Tests for the temporal-split machinery in train.py - the part that
determines whether any metric this module reports is trustworthy.

These deliberately exercise only `SplitDates`, `_prepare_corpus`,
`temporal_split`, and `_assert_strictly_before`: none of them touch
lightgbm, shap, or scikit-learn (those are lazily imported inside
`train_model`/`evaluate`/`explain` specifically so this file can run without
installing the ML stack). What's tested here is the actual leakage-safety
property, not the model.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from aagahi_signal.train import (
    SplitDates,
    TrainingError,
    _assert_strictly_before,
    _prepare_corpus,
    temporal_split,
)


def _labelled_frame(n_days: int = 120, start: str = "2024-01-01") -> pd.DataFrame:
    dates = pd.date_range(start, periods=n_days, freq="D")
    rng = np.random.default_rng(0)
    return pd.DataFrame(
        {
            "date": dates,
            "scorable": True,
            "is_rapid_intensification": rng.random(n_days) < 0.1,
        }
    )


# ---------------------------------------------------------------------------
# SplitDates
# ---------------------------------------------------------------------------


def test_split_dates_rejects_inverted_cutoffs():
    with pytest.raises(TrainingError):
        SplitDates(train_end=pd.Timestamp("2024-06-01").date(), validate_end=pd.Timestamp("2024-01-01").date())


def test_split_dates_rejects_equal_cutoffs():
    same = pd.Timestamp("2024-06-01").date()
    with pytest.raises(TrainingError):
        SplitDates(train_end=same, validate_end=same)


# ---------------------------------------------------------------------------
# temporal_split: the actual split logic
# ---------------------------------------------------------------------------


def test_temporal_split_produces_disjoint_time_ordered_partitions():
    frame = _labelled_frame()
    split = SplitDates(
        train_end=pd.Timestamp("2024-03-01").date(),
        validate_end=pd.Timestamp("2024-04-01").date(),
    )
    train, validate, test = temporal_split(frame, split)

    assert pd.to_datetime(train["date"]).max() <= pd.Timestamp(split.train_end)
    assert pd.to_datetime(validate["date"]).min() > pd.Timestamp(split.train_end)
    assert pd.to_datetime(validate["date"]).max() <= pd.Timestamp(split.validate_end)
    assert pd.to_datetime(test["date"]).min() > pd.Timestamp(split.validate_end)
    # No row lost, none duplicated across partitions.
    assert len(train) + len(validate) + len(test) == len(frame)


def test_temporal_split_is_immune_to_row_shuffling():
    """The direct answer to "what happens if I pass it a shuffled split":
    nothing - `temporal_split` partitions by each row's own date value, not
    by position, so scrambling row order changes nothing about the result.
    """
    frame = _labelled_frame()
    shuffled = frame.sample(frac=1.0, random_state=7).reset_index(drop=True)
    split = SplitDates(
        train_end=pd.Timestamp("2024-03-01").date(),
        validate_end=pd.Timestamp("2024-04-01").date(),
    )

    train_a, validate_a, test_a = temporal_split(frame, split)
    train_b, validate_b, test_b = temporal_split(shuffled, split)

    assert set(train_a["date"]) == set(train_b["date"])
    assert set(validate_a["date"]) == set(validate_b["date"])
    assert set(test_a["date"]) == set(test_b["date"])


def test_temporal_split_refuses_a_cutoff_that_empties_a_partition():
    frame = _labelled_frame(n_days=30)
    # validate_end beyond the last date in the frame -> test partition empty.
    split = SplitDates(
        train_end=pd.Timestamp("2024-01-10").date(),
        validate_end=pd.Timestamp("2024-12-31").date(),
    )
    with pytest.raises(TrainingError, match="test split is empty"):
        temporal_split(frame, split)


# ---------------------------------------------------------------------------
# _assert_strictly_before: the explicit leakage guard, tested directly
# ---------------------------------------------------------------------------


def test_assert_strictly_before_passes_for_genuinely_disjoint_frames():
    earlier = pd.DataFrame({"date": pd.date_range("2024-01-01", periods=10)})
    later = pd.DataFrame({"date": pd.date_range("2024-02-01", periods=10)})
    _assert_strictly_before(earlier, later, "train", "validate")  # must not raise


def test_assert_strictly_before_refuses_overlapping_frames():
    """Simulates exactly what a shuffled scikit-learn train_test_split would
    hand this code: two partitions whose date ranges overlap. Per CLAUDE.md
    and TS-11 this must raise, not log a warning and continue.
    """
    earlier = pd.DataFrame({"date": pd.date_range("2024-01-01", periods=20)})
    # Overlaps earlier's last 5 days.
    later = pd.DataFrame({"date": pd.date_range("2024-01-16", periods=20)})

    with pytest.raises(TrainingError, match="not temporally disjoint"):
        _assert_strictly_before(earlier, later, "train", "validate")


def test_assert_strictly_before_refuses_reversed_frames():
    earlier_by_name = pd.DataFrame({"date": pd.date_range("2024-06-01", periods=10)})
    later_by_name = pd.DataFrame({"date": pd.date_range("2024-01-01", periods=10)})

    with pytest.raises(TrainingError, match="not temporally disjoint"):
        _assert_strictly_before(earlier_by_name, later_by_name, "train", "validate")


# ---------------------------------------------------------------------------
# _prepare_corpus: the null-label / completeness filtering
# ---------------------------------------------------------------------------


def test_prepare_corpus_drops_unscorable_and_unlabelled_rows():
    frame = pd.DataFrame(
        {
            "date": pd.date_range("2024-01-01", periods=5),
            "scorable": [True, True, False, True, True],
            "is_rapid_intensification": [True, pd.NA, False, False, pd.NA],
        }
    )
    corpus = _prepare_corpus(frame)
    # Row 0 (True, True), row 3 (True, False) survive; row 1 fails
    # labelling, row 2 fails scorability, row 4 fails labelling.
    assert len(corpus) == 2
    assert corpus["is_rapid_intensification"].dtype == bool


def test_prepare_corpus_rejects_a_frame_with_no_survivors():
    frame = pd.DataFrame(
        {
            "date": pd.date_range("2024-01-01", periods=3),
            "scorable": [False, False, False],
            "is_rapid_intensification": [True, False, True],
        }
    )
    with pytest.raises(TrainingError):
        _prepare_corpus(frame)


def test_prepare_corpus_requires_the_label_column():
    frame = pd.DataFrame({"date": pd.date_range("2024-01-01", periods=3), "scorable": True})
    with pytest.raises(TrainingError):
        _prepare_corpus(frame)
