"""One-off check: does every Earth Engine collection ID in config.py actually
resolve and return imagery over the pilot region?

Why this exists (read before trusting config.py's collection IDs again).
The 007 -> 008 SMAP fix made in this repo was a documentation check against
the public Earth Engine Data Catalog pages, not a live query - there were no
credentials available to run one. A catalog page can be stale, and "resolves
in the catalog docs" is not the same claim as "resolves for this account, this
region, this date range." This script closes that gap: it calls
`.getInfo()` against the real Earth Engine backend for every collection this
project depends on, and refuses to report success on anything it could not
verify. It intentionally re-implements the resolution check rather than
reusing `EEClient._resolve_collection` directly, so a bug in that shared
method cannot hide a real catalog problem from this script.

Usage:
    earthengine authenticate                      # one time
    export AAGAHI_EE_PROJECT=your-gcp-project-id
    python scripts/verify_collections.py

Exit code 0 means every collection resolved with a non-zero image count.
Exit code 1 means at least one did not - read the printed detail before
touching config.py. If /008 fails here and /007 succeeds, revert config.py's
SMAP_COLLECTION to /007 and update the comment explaining why; do not guess
between them from documentation alone a second time.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from datetime import date, timedelta

import ee

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent.parent))

from aagahi_signal import config  # noqa: E402


@dataclass(frozen=True)
class CollectionCheck:
    label: str
    collection_id: str
    band: str


# One entry per collection+band this project actually reads, mirroring
# ee_client.py's fetch_* methods exactly - if a fetch method starts reading a
# new band or collection, add it here too, or this script stops being a
# faithful check of what the pipeline depends on.
CHECKS: tuple[CollectionCheck, ...] = (
    CollectionCheck("SMAP surface soil moisture", config.SMAP_COLLECTION, config.SMAP_SURFACE_BAND),
    CollectionCheck("SMAP root-zone soil moisture", config.SMAP_COLLECTION, config.SMAP_ROOTZONE_BAND),
    CollectionCheck("ERA5-Land 2m temperature", config.ERA5_COLLECTION, config.ERA5_TEMP_BAND),
    CollectionCheck("ERA5-Land 2m dewpoint", config.ERA5_COLLECTION, config.ERA5_DEWPOINT_BAND),
    CollectionCheck("CHIRPS precipitation", config.CHIRPS_COLLECTION, config.CHIRPS_PRECIP_BAND),
    CollectionCheck("MODIS NDVI", config.MODIS_NDVI_COLLECTION, config.MODIS_NDVI_BAND),
)

# A recent 30-day window, clear of the provider latency window each dataset
# documents (config.PipelineSettings enforces the same 3-day floor for the
# fetch pipeline). Wide enough that a single missing day cannot produce a
# false failure; MODIS NDVI is a 16-day composite, so 30 days guarantees at
# least one composite falls inside it.
WINDOW_END = date.today() - timedelta(days=5)
WINDOW_START = WINDOW_END - timedelta(days=30)


def _initialise() -> None:
    settings = config.PipelineSettings(
        start_date=date(2024, 1, 1),  # unused by this script; satisfies validation
        end_date=WINDOW_END,
    )
    if settings.service_account_key is not None:
        credentials = ee.ServiceAccountCredentials(
            email=None, key_file=str(settings.service_account_key)
        )
        ee.Initialize(credentials, project=settings.ee_project)
    else:
        ee.Initialize(project=settings.ee_project)


def _pilot_geometry() -> ee.Geometry:
    return ee.Geometry.Rectangle(
        config.PILOT_REGION.bbox, proj="EPSG:4326", geodesic=False
    )


def _check_one(check: CollectionCheck, region: ee.Geometry) -> tuple[bool, str]:
    try:
        collection = (
            ee.ImageCollection(check.collection_id)
            .select(check.band)
            .filterDate(WINDOW_START.isoformat(), (WINDOW_END + timedelta(days=1)).isoformat())
            .filterBounds(region)
        )
        count = collection.size().getInfo()
    except ee.EEException as exc:
        return False, f"EEException: {exc}"

    if count is None or count == 0:
        return False, "resolved but returned zero images for the pilot region/window"
    return True, f"{count} images"


def main() -> int:
    print(f"Pilot region: {config.PILOT_REGION.name} {config.PILOT_REGION.bbox}")
    print(f"Window: {WINDOW_START} .. {WINDOW_END}\n")

    _initialise()
    region = _pilot_geometry()

    all_passed = True
    for check in CHECKS:
        ok, detail = _check_one(check, region)
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {check.label:<32} {check.collection_id} [{check.band}] - {detail}")
        all_passed = all_passed and ok

    if config.SIF_ASSET_ID is not None:
        ok, detail = _check_one(
            CollectionCheck("SIF (custom asset)", config.SIF_ASSET_ID, "SIF"), region
        )
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {'SIF (custom asset)':<32} {config.SIF_ASSET_ID} - {detail}")
        all_passed = all_passed and ok
    else:
        print("[SKIP] SIF (custom asset)               AAGAHI_SIF_ASSET_ID not set - degraded NDVI mode is active, as expected")

    print()
    if all_passed:
        print("All collections verified against a live Earth Engine query.")
        return 0

    print("At least one collection failed to resolve. Do not trust the pilot")
    print("region or any collection ID in config.py until every line above reads PASS.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
