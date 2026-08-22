"""Earth Engine access layer.

Responsibilities:
  * authenticate (service account in CI, interactive locally);
  * resolve and validate collection IDs so a renamed upstream asset fails
    loudly instead of returning empty imagery;
  * reduce daily imagery to a per-grid-cell spatial mean;
  * retry transient failures with exponential backoff, and refuse to retry
    permanent ones.

Everything returned from this module is a plain pandas DataFrame. No Earth
Engine object escapes, which keeps the feature layer testable offline.
"""

from __future__ import annotations

import logging
import time
from collections.abc import Callable
from datetime import date, timedelta
from typing import Any, TypeVar

import ee
import pandas as pd

from . import config

logger = logging.getLogger(__name__)

T = TypeVar("T")

# Earth Engine surfaces permanent problems (bad asset, bad geometry, quota
# exhaustion) and transient ones (timeout, 5xx) through the same exception
# type, so we discriminate on the message. Anything not matching these
# fragments is treated as permanent and re-raised immediately.
_TRANSIENT_FRAGMENTS: tuple[str, ...] = (
    "timed out",
    "timeout",
    "internal error",
    "backend error",
    "temporarily unavailable",
    "too many concurrent",
    "503",
    "429",
)


class EarthEngineError(RuntimeError):
    """Raised when Earth Engine fails in a way the caller cannot recover from."""


class DatasetUnavailableError(EarthEngineError):
    """Raised when a required collection is missing, renamed, or empty."""


def _is_transient(exc: Exception) -> bool:
    message = str(exc).lower()
    return any(fragment in message for fragment in _TRANSIENT_FRAGMENTS)


def _with_retries(operation: Callable[[], T], description: str) -> T:
    """Run an Earth Engine call, retrying only transient failures."""
    last_error: Exception | None = None

    for attempt in range(1, config.EE_MAX_RETRIES + 1):
        try:
            return operation()
        except ee.EEException as exc:
            last_error = exc
            if not _is_transient(exc):
                logger.error("%s failed permanently: %s", description, exc)
                raise EarthEngineError(f"{description} failed: {exc}") from exc
            if attempt == config.EE_MAX_RETRIES:
                break
            delay = config.EE_BACKOFF_BASE_SECONDS * (2 ** (attempt - 1))
            logger.warning(
                "%s failed (attempt %d/%d), retrying in %.1fs: %s",
                description,
                attempt,
                config.EE_MAX_RETRIES,
                delay,
                exc,
            )
            time.sleep(delay)
        except Exception as exc:  # noqa: BLE001 - surface unexpected types intact
            logger.exception("%s raised an unexpected error", description)
            raise EarthEngineError(f"{description} failed: {exc}") from exc

    raise EarthEngineError(
        f"{description} failed after {config.EE_MAX_RETRIES} attempts: {last_error}"
    )


class EEClient:
    """Thin, defensive wrapper over the Earth Engine Python API."""

    def __init__(self, settings: config.PipelineSettings) -> None:
        self._settings = settings
        self._initialised = False

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def initialise(self) -> None:
        """Authenticate and initialise Earth Engine.

        Uses a service account when AAGAHI_EE_KEY_FILE is set (the CI path),
        otherwise falls back to stored user credentials. Never prompts
        interactively inside a scheduled job.
        """
        if self._initialised:
            return

        key_file = self._settings.service_account_key
        project = self._settings.ee_project

        try:
            if key_file is not None:
                if not key_file.is_file():
                    raise DatasetUnavailableError(
                        f"Service account key not found at {key_file}"
                    )
                # The service account email is embedded in the key file; the
                # API reads it from there when we pass an empty identifier.
                credentials = ee.ServiceAccountCredentials(
                    email=None, key_file=str(key_file)
                )
                ee.Initialize(credentials, project=project)
                logger.info("Earth Engine initialised with service account")
            else:
                ee.Initialize(project=project)
                logger.info("Earth Engine initialised with stored user credentials")
        except ee.EEException as exc:
            raise EarthEngineError(
                "Earth Engine initialisation failed. Run `earthengine authenticate` "
                "locally, or set AAGAHI_EE_KEY_FILE and AAGAHI_EE_PROJECT. "
                f"Underlying error: {exc}"
            ) from exc

        self._initialised = True

    def _require_initialised(self) -> None:
        if not self._initialised:
            raise EarthEngineError("EEClient.initialise() must be called first")

    # ------------------------------------------------------------------
    # Collection resolution
    # ------------------------------------------------------------------

    def _resolve_collection(
        self,
        collection_id: str,
        band: str,
        start: date,
        end: date,
        region: ee.Geometry,
    ) -> ee.ImageCollection:
        """Return a filtered collection, or raise if it is missing or empty.

        Silent empties are the dangerous failure mode here: an empty collection
        reduces to null, which downstream would look like "no drought" rather
        than "no data". We check the size eagerly and fail instead.
        """
        self._require_initialised()

        def _build() -> ee.ImageCollection:
            collection = (
                ee.ImageCollection(collection_id)
                .select(band)
                .filterDate(start.isoformat(), (end + timedelta(days=1)).isoformat())
                .filterBounds(region)
            )
            size = collection.size().getInfo()
            if size is None or size == 0:
                raise DatasetUnavailableError(
                    f"Collection {collection_id} band {band!r} returned no images "
                    f"for {start}..{end} over the region. Check the collection ID "
                    f"against the Earth Engine catalog and the provider latency."
                )
            logger.info(
                "Resolved %s band %s: %d images (%s..%s)",
                collection_id,
                band,
                size,
                start,
                end,
            )
            return collection

        return _with_retries(_build, f"resolve {collection_id}")

    # ------------------------------------------------------------------
    # Reduction
    # ------------------------------------------------------------------

    def _daily_regional_mean(
        self,
        collection: ee.ImageCollection,
        band: str,
        region: ee.Geometry,
        value_name: str,
        scale_factor: float = 1.0,
    ) -> pd.DataFrame:
        """Reduce each image to a single regional mean and return a DataFrame.

        This is the pilot-scale reduction: one value per day for the whole
        region of interest. For the production multi-cell pipeline, swap
        reduceRegion for reduceRegions over a grid FeatureCollection - the
        feature-engineering layer downstream is already keyed by cell.
        """
        self._require_initialised()

        def _reduce_image(image: ee.Image) -> ee.Feature:
            stats = image.reduceRegion(
                reducer=ee.Reducer.mean(),
                geometry=region,
                scale=config.GRID_RESOLUTION_M,
                maxPixels=1e9,
                bestEffort=True,
            )
            return ee.Feature(
                None,
                {
                    "date": image.date().format("YYYY-MM-dd"),
                    "value": stats.get(band),
                },
            )

        def _fetch() -> list[dict[str, Any]]:
            features = collection.map(_reduce_image).getInfo()
            return features.get("features", []) if features else []

        raw = _with_retries(_fetch, f"reduce {value_name}")

        records: list[dict[str, Any]] = []
        for feature in raw:
            properties = feature.get("properties", {})
            raw_value = properties.get("value")
            if raw_value is None:
                # Masked out (cloud, quality flag, ocean). Recorded as NaN so
                # the completeness ratio downstream reflects the real gap.
                value: float | None = None
            else:
                value = float(raw_value) * scale_factor
            records.append({"date": properties.get("date"), value_name: value})

        if not records:
            raise DatasetUnavailableError(
                f"Reduction for {value_name} produced no records; the collection "
                "resolved but every image was masked over this region."
            )

        frame = pd.DataFrame.from_records(records)
        frame["date"] = pd.to_datetime(frame["date"], errors="coerce")
        frame = frame.dropna(subset=["date"])

        # Sub-daily products (SMAP L4 is 3-hourly) collapse to a daily mean.
        frame = frame.groupby(frame["date"].dt.normalize(), as_index=False).mean(
            numeric_only=True
        )
        frame = frame.rename(columns={frame.columns[0]: "date"}).sort_values("date")

        missing = int(frame[value_name].isna().sum())
        if missing:
            logger.warning(
                "%s: %d of %d days are masked/missing",
                value_name,
                missing,
                len(frame),
            )
        return frame.reset_index(drop=True)

    # ------------------------------------------------------------------
    # Public fetches
    # ------------------------------------------------------------------

    def geometry(self) -> ee.Geometry:
        self._require_initialised()
        return ee.Geometry.Rectangle(self._settings.region.bbox, proj="EPSG:4326", geodesic=False)

    def fetch_soil_moisture(self, start: date, end: date) -> pd.DataFrame:
        """Daily mean surface and root-zone soil moisture (m3/m3)."""
        region = self.geometry()
        surface = self._daily_regional_mean(
            self._resolve_collection(
                config.SMAP_COLLECTION, config.SMAP_SURFACE_BAND, start, end, region
            ),
            config.SMAP_SURFACE_BAND,
            region,
            "sm_surface",
        )
        rootzone = self._daily_regional_mean(
            self._resolve_collection(
                config.SMAP_COLLECTION, config.SMAP_ROOTZONE_BAND, start, end, region
            ),
            config.SMAP_ROOTZONE_BAND,
            region,
            "sm_rootzone",
        )
        return surface.merge(rootzone, on="date", how="outer").sort_values("date")

    def fetch_temperature_and_dewpoint(self, start: date, end: date) -> pd.DataFrame:
        """Daily mean 2 m air temperature and dewpoint, converted to Celsius."""
        region = self.geometry()
        temperature = self._daily_regional_mean(
            self._resolve_collection(
                config.ERA5_COLLECTION, config.ERA5_TEMP_BAND, start, end, region
            ),
            config.ERA5_TEMP_BAND,
            region,
            "t2m_kelvin",
        )
        dewpoint = self._daily_regional_mean(
            self._resolve_collection(
                config.ERA5_COLLECTION, config.ERA5_DEWPOINT_BAND, start, end, region
            ),
            config.ERA5_DEWPOINT_BAND,
            region,
            "d2m_kelvin",
        )
        merged = temperature.merge(dewpoint, on="date", how="outer")
        merged["t2m_c"] = merged["t2m_kelvin"] - 273.15
        merged["d2m_c"] = merged["d2m_kelvin"] - 273.15
        return merged[["date", "t2m_c", "d2m_c"]].sort_values("date")

    def fetch_precipitation(self, start: date, end: date) -> pd.DataFrame:
        """Daily precipitation total (mm)."""
        region = self.geometry()
        return self._daily_regional_mean(
            self._resolve_collection(
                config.CHIRPS_COLLECTION, config.CHIRPS_PRECIP_BAND, start, end, region
            ),
            config.CHIRPS_PRECIP_BAND,
            region,
            "precip_mm",
        )

    def fetch_ndvi(self, start: date, end: date) -> pd.DataFrame:
        """16-day composite NDVI, forward-filled to daily.

        This is the degraded-mode vegetation proxy. NDVI lags plant water
        stress by days to weeks, which is exactly the weakness SIF would
        address - see the SIF note in config.py.
        """
        region = self.geometry()
        # Widen the window so the first composite before `start` is available
        # to fill the leading edge.
        composite = self._daily_regional_mean(
            self._resolve_collection(
                config.MODIS_NDVI_COLLECTION,
                config.MODIS_NDVI_BAND,
                start - timedelta(days=32),
                end,
                region,
            ),
            config.MODIS_NDVI_BAND,
            region,
            "ndvi",
            scale_factor=config.MODIS_NDVI_SCALE,
        )
        daily_index = pd.date_range(start=start, end=end, freq="D", name="date")
        daily = (
            composite.set_index("date")
            .reindex(composite.set_index("date").index.union(daily_index))
            .sort_index()
            .ffill(limit=16)
            .reindex(daily_index)
            .reset_index()
        )
        return daily
