"""Configuration for the AAGAHI rate-of-decline signal pipeline.

All values are read from the environment where they are deployment-specific,
with defaults suitable for a single-district pilot. Nothing secret is stored
here; credentials come from the environment or from Earth Engine's own
service-account file, never from source control.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path
from typing import Final

# --------------------------------------------------------------------------
# Earth Engine dataset identifiers
# --------------------------------------------------------------------------
# Verified against the Earth Engine Data Catalog. If a collection ID changes
# upstream, the ingestion will fail loudly at asset-resolution time rather
# than silently returning empty imagery - see EEClient._resolve_collection.

# v008 supersedes the deprecated v007 asset (confirmed against the GEE
# catalog, Aug 2026 - v007 is no longer resolvable; scoring would fail at
# first ingestion run on that ID).
SMAP_COLLECTION: Final[str] = "NASA/SMAP/SPL4SMGP/008"
SMAP_SURFACE_BAND: Final[str] = "sm_surface"
SMAP_ROOTZONE_BAND: Final[str] = "sm_rootzone"

ERA5_COLLECTION: Final[str] = "ECMWF/ERA5_LAND/DAILY_AGGR"
ERA5_TEMP_BAND: Final[str] = "temperature_2m"
ERA5_DEWPOINT_BAND: Final[str] = "dewpoint_temperature_2m"

CHIRPS_COLLECTION: Final[str] = "UCSB-CHG/CHIRPS/DAILY"
CHIRPS_PRECIP_BAND: Final[str] = "precipitation"

MODIS_NDVI_COLLECTION: Final[str] = "MODIS/061/MOD13Q1"
MODIS_NDVI_BAND: Final[str] = "NDVI"
MODIS_NDVI_SCALE: Final[float] = 1e-4

# NOTE ON SIF - read before citing this in the submission.
# TROPOMI solar-induced fluorescence is NOT available as a standard Earth
# Engine collection. The SRS lists SIF as the primary vegetation-stress proxy
# because the literature supports it, but this pipeline cannot source it from
# GEE. Two honest options:
#   (a) ingest TROPOMI SIF separately from NASA GES DISC and upload as an EE
#       asset, then set SIF_ASSET_ID below;
#   (b) run in degraded mode on MODIS NDVI, which lags plant water stress.
# Degraded mode is the default and is recorded on every prediction so the
# confidence penalty is visible. Do not claim SIF in the submission unless
# option (a) has actually been implemented.
SIF_ASSET_ID: Final[str | None] = os.getenv("AAGAHI_SIF_ASSET_ID") or None

# --------------------------------------------------------------------------
# Analysis parameters
# --------------------------------------------------------------------------

GRID_RESOLUTION_M: Final[int] = 5_000          # 5 km analysis cell
CLIMATOLOGY_START_YEAR: Final[int] = 2015      # SMAP L4 record begins 2015-03
CLIMATOLOGY_DOY_WINDOW: Final[int] = 7         # +/- days around day-of-year
RATE_WINDOWS_DAYS: Final[tuple[int, ...]] = (5, 14)
PREDICTION_HORIZON_DAYS: Final[int] = 14

# The target event definition, from the SRS (FR-PRED-002). A decline of this
# many soil-moisture percentile points inside the horizon is "rapid
# intensification". Changing this changes the label definition and therefore
# invalidates any trained model - bump the feature schema hash if you touch it.
RAPID_INTENSIFICATION_DROP_PCTILE: Final[float] = 20.0

# The drop threshold alone is not a sufficient definition - see
# features.label_rapid_intensification. A flash drought must also begin from a
# non-drought state and end in drought. These two bounds supply that, and
# follow the standard two-sided criterion used in the flash-drought
# literature.
LABEL_START_ABOVE_PCTILE: Final[float] = 40.0   # must not already be in drought
LABEL_END_BELOW_PCTILE: Final[float] = 20.0     # must reach drought conditions

# Minimum proportion of required features that must be derivable before a cell
# is scorable (FR-FEAT-010). Below this the cell reports "not enough data"
# rather than a fabricated low-risk score.
MIN_COMPLETENESS_RATIO: Final[float] = 0.70

# Maximum consecutive days a missing observation may be carried forward
# (FR-INGE-005 / DQ-06).
MAX_CARRY_FORWARD_DAYS: Final[int] = 3

# --------------------------------------------------------------------------
# Retry / networking
# --------------------------------------------------------------------------

EE_MAX_RETRIES: Final[int] = 5
EE_BACKOFF_BASE_SECONDS: Final[float] = 2.0
EE_REQUEST_TIMEOUT_SECONDS: Final[int] = 300


@dataclass(frozen=True)
class RegionOfInterest:
    """A named study area expressed as a WGS84 bounding box.

    Coordinates are (west, south, east, north) in decimal degrees.
    """

    name: str
    west: float
    south: float
    east: float
    north: float

    def __post_init__(self) -> None:
        if not (-180.0 <= self.west < self.east <= 180.0):
            raise ValueError(
                f"{self.name}: longitudes must satisfy -180 <= west < east <= 180, "
                f"got west={self.west}, east={self.east}"
            )
        if not (-90.0 <= self.south < self.north <= 90.0):
            raise ValueError(
                f"{self.name}: latitudes must satisfy -90 <= south < north <= 90, "
                f"got south={self.south}, north={self.north}"
            )

    @property
    def bbox(self) -> list[float]:
        return [self.west, self.south, self.east, self.north]


# Pilot district. Faisalabad / Jhang belt in Punjab - mixed rain-fed and canal
# wheat, well covered by SMAP, and a region with documented dry spells.
# Confirmed suitable for the pilot (see project notes, Aug 2026): flat
# alluvial Indus plain at 30.9-31.9 N, no permanent snow/ice or ocean, no
# dense-canopy attenuation of the kind that degrades SMAP L-band retrievals -
# both SMAP L4 (SPL4SMGP) and ERA5-Land are global 9 km products with
# continuous coverage here and no documented regional gap.
PILOT_REGION: Final[RegionOfInterest] = RegionOfInterest(
    name="Faisalabad-Jhang",
    west=72.30,
    south=30.90,
    east=73.60,
    north=31.90,
)


@dataclass(frozen=True)
class PipelineSettings:
    """Runtime settings for a single pipeline execution."""

    region: RegionOfInterest = PILOT_REGION
    start_date: date = field(default_factory=lambda: date(2024, 1, 1))
    end_date: date = field(default_factory=lambda: date.today() - timedelta(days=4))
    output_dir: Path = field(
        default_factory=lambda: Path(os.getenv("AAGAHI_OUTPUT_DIR", "./output"))
    )
    ee_project: str | None = field(
        default_factory=lambda: os.getenv("AAGAHI_EE_PROJECT") or None
    )
    service_account_key: Path | None = field(
        default_factory=lambda: (
            Path(p) if (p := os.getenv("AAGAHI_EE_KEY_FILE")) else None
        )
    )

    def __post_init__(self) -> None:
        if self.start_date >= self.end_date:
            raise ValueError(
                f"start_date ({self.start_date}) must precede end_date ({self.end_date})"
            )
        if self.start_date.year < CLIMATOLOGY_START_YEAR:
            raise ValueError(
                f"start_date {self.start_date} precedes the SMAP record "
                f"({CLIMATOLOGY_START_YEAR}); no soil moisture is available"
            )
        # ERA5-Land and SMAP both lag real time. Requesting the last few days
        # returns partial or empty imagery, which is worse than not asking.
        latest_safe = date.today() - timedelta(days=3)
        if self.end_date > latest_safe:
            raise ValueError(
                f"end_date {self.end_date} is within the provider latency window; "
                f"use {latest_safe} or earlier"
            )
