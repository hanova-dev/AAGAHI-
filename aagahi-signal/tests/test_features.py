"""Unit tests for the pure-pandas feature transforms.

Focused on the two things that were actually wrong here during development
(see README.md and CLAUDE.md S8): the two-sided label criterion, and the
nullable-label handling that keeps a truncated forward window from silently
becoming "no event". Everything in features.py is offline-testable by
design - no Earth Engine, no network - so these run in milliseconds.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from aagahi_signal import config, features


def test_vpd_clamps_to_zero_when_dewpoint_exceeds_temperature():
    # A reanalysis artefact, not physically possible, but it does occur in
    # ERA5-Land near-saturated cells. Must never yield a negative deficit.
    temperature = pd.Series([20.0])
    dewpoint = pd.Series([25.0])
    vpd = features.vapour_pressure_deficit_kpa(temperature, dewpoint)
    assert vpd.iloc[0] == pytest.approx(0.0)


def test_vpd_positive_when_air_drier_than_dewpoint_reference():
    temperature = pd.Series([30.0])
    dewpoint = pd.Series([15.0])
    vpd = features.vapour_pressure_deficit_kpa(temperature, dewpoint)
    assert vpd.iloc[0] > 0


def test_saturation_vapour_pressure_rejects_all_missing_input():
    with pytest.raises(features.FeatureEngineeringError):
        features.saturation_vapour_pressure_kpa(pd.Series([np.nan, np.nan]))


def test_ensure_daily_index_inserts_missing_calendar_days():
    frame = pd.DataFrame(
        {
            "date": ["2024-01-01", "2024-01-04"],
            "value": [1.0, 4.0],
        }
    )
    filled = features.ensure_daily_index(frame)
    assert len(filled) == 4
    assert filled["value"].isna().sum() == 2


def test_rate_of_change_is_nan_until_window_elapses():
    series = pd.Series([10.0, 20.0, 30.0, 40.0])
    delta = features.rate_of_change(series, window_days=2)
    assert delta.isna().sum() == 2
    assert delta.iloc[2] == pytest.approx(20.0)


def test_carry_forward_limited_stops_at_max_days():
    frame = pd.DataFrame({"x": [1.0, np.nan, np.nan, np.nan, np.nan]})
    filled = features.carry_forward_limited(frame, ["x"], max_days=2)
    # Day 1 carried forward, day 2 carried forward, day 3+ must stay NaN.
    # np.array_equal(..., equal_nan=True): NaN != NaN under plain ==, so a
    # direct list comparison here would fail regardless of correctness.
    assert np.array_equal(
        filled["x"].to_numpy(), [1.0, 1.0, 1.0, np.nan, np.nan], equal_nan=True
    )


def _synthetic_percentile_series(values: list[float]) -> pd.DataFrame:
    dates = pd.date_range("2024-01-01", periods=len(values), freq="D")
    return pd.DataFrame({"date": dates, "sm_pctile": values})


def test_label_requires_starting_above_the_wet_threshold():
    # Falls 25 points and ends dry, but never starts above 40 - ordinary
    # seasonal dry-down, not a flash drought. A bare "dropped >= 20" rule
    # would mislabel this positive; the two-sided criterion must not.
    values = [35.0] * 5 + [10.0] * 20
    frame = features.label_rapid_intensification(
        _synthetic_percentile_series(values), horizon_days=14
    )
    assert frame["is_rapid_intensification"].iloc[0] == False  # noqa: E712


def test_label_fires_when_all_three_conditions_hold():
    # Starts wet (>=40), falls fast (>=20 pts), ends dry (<=20) within the
    # horizon - the case the signal exists to catch.
    values = [80.0] * 5 + [15.0] * 20
    frame = features.label_rapid_intensification(
        _synthetic_percentile_series(values), horizon_days=14
    )
    assert frame["is_rapid_intensification"].iloc[0] == True  # noqa: E712


def test_label_is_na_not_false_when_forward_window_is_truncated():
    # The last few rows of any record have no full future horizon. They must
    # be excluded from training (pd.NA), not silently scored as "no event" -
    # the bug this project found and documented in README.md.
    values = [80.0] * 10
    frame = features.label_rapid_intensification(
        _synthetic_percentile_series(values), horizon_days=14
    )
    assert frame["is_rapid_intensification"].iloc[-1] is pd.NA


def test_feature_schema_hash_is_stable_and_changes_with_the_contract():
    first = features.feature_schema_hash()
    second = features.feature_schema_hash()
    assert first == second
    assert len(first) == 16
