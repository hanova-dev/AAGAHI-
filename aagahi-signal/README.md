# AAGAHI — rate-of-decline signal

Detects **rapid soil-moisture intensification** (flash drought) from free
satellite and reanalysis data, and reports how many days of warning the signal
would have given before a known historical event.

## Install

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
earthengine authenticate          # one time, opens a browser
export AAGAHI_EE_PROJECT=your-gcp-project-id
```

## Run

```bash
# 1. Pull EO data and build the feature table (slow; ~10-20 min for 6 years)
python -m aagahi_signal.pipeline fetch --start 2018-01-01 --end 2025-06-30

# 2. Render the lead-time chart for a known drying event
python -m aagahi_signal.pipeline validate \
    --data output/faisalabad-jhang_2018-01-01_2025-06-30.parquet \
    --event-start 2024-05-10 --event-end 2024-06-25 \
    --out output/lead_time.png

# 3. Train and evaluate the classifier (temporal split only - see train.py)
python -m aagahi_signal.train \
    --data output/faisalabad-jhang_2018-01-01_2025-06-30.parquet \
    --train-end 2022-12-31 --validate-end 2023-12-31 \
    --out-dir output/model
```

`validate` needs no Earth Engine and no credentials — a reviewer can reproduce
the chart from the shipped Parquet file alone.

## Development

```bash
pytest              # unit tests over the pure-pandas transforms in features.py
```

`ee_client.py` and `pipeline.py fetch` are not unit-tested here — they require
live Earth Engine credentials. `features.py` is pure pandas by design
specifically so its logic (climatology, rate-of-change, the label criterion)
can be verified offline.

## Pilot district

Faisalabad–Jhang, Punjab (72.30–73.60° E, 30.90–31.90° N) — see
`config.PILOT_REGION`. Flat alluvial Indus-plain agricultural belt, mixed
rain-fed and canal-irrigated wheat, no permanent snow/ice or open water, no
dense-canopy attenuation of the kind that degrades SMAP L-band retrievals.
Both SMAP L4 (`NASA/SMAP/SPL4SMGP`) and ERA5-Land
(`ECMWF/ERA5_LAND/DAILY_AGGR`) are global 9 km products with continuous
coverage over this region and no documented gap. Confirmed against the
Earth Engine Data Catalog, August 2026 — that check also caught that
`SPL4SMGP/007` (the version this file previously pointed at) is deprecated;
the collection ID here is `/008`.

## What the signal is

Ordinary drought monitoring watches the **level** of soil moisture and the
**deficit** of rainfall. This watches the **rate of decline**, because the
published literature identifies evaporative demand and rapid intensification —
not precipitation deficit — as the driver of flash drought, and finds that
current-generation models underestimate soil-moisture sensitivity at short
timescales.

Two ordering decisions carry the method:

1. **Percentile before differencing.** Soil moisture is ranked against a
   day-of-year climatology first, then differenced. This removes the seasonal
   cycle, so a 20-point fall in February means the same as one in June.
2. **Smoothing before differencing.** A centred 5-day mean is applied before
   the percentile transform. Without it, retrieval noise is amplified by the
   ranking step and manufactures false "drops" — measured at a 40 %+ spurious
   positive rate during development.

## Two things found while building this

**The obvious label definition is wrong.** A bare "soil moisture fell 20
percentile points in 14 days" also fires on ordinary seasonal dry-down. Against
a realistic autocorrelated soil-water series it labelled **40 % of all days
positive**. A model trained on that learns "it is usually drying", which is
useless as a warning. The label now uses the standard two-sided criterion from
the flash-drought literature: the cell must start above the 40th percentile,
end below the 20th, and get there within the horizon. That yields **2–6 %**,
matching the expected base rate.

**SIF is not available in Earth Engine.** The SRS specifies TROPOMI
solar-induced fluorescence as the primary vegetation-stress proxy, on good
evidence — it responds to water stress faster than NDVI. But there is no
standard SIF collection in the GEE catalog. This pipeline therefore runs on
MODIS NDVI in **degraded mode** and records that fact on every prediction.
**Do not claim SIF in the submission** unless TROPOMI SIF has actually been
ingested from NASA GES DISC and uploaded as an EE asset
(`AAGAHI_SIF_ASSET_ID`).

## Honest reporting

- Never report bare accuracy. The positive class is 2–6 % of days, so a model
  predicting "no drought" always scores ~95 % accurate and is worthless.
  Report **precision, recall, and PR-AUC**.
- If `validate` reports `signal_fired_before_event: false`, publish that. A
  negative result reported honestly is worth more than a positive one that
  does not replicate.
- The warning threshold is derived from the observed delta distribution (15th
  percentile), not chosen as a round number.

## Data sources

| Source | Variable | Licence |
|---|---|---|
| NASA SMAP L4 | Soil moisture | Public domain |
| ERA5-Land (Copernicus) | Temperature, dewpoint | Copernicus, attribution required |
| CHIRPS (UCSB/USGS) | Precipitation | Public domain |
| MODIS MOD13Q1 | NDVI (degraded-mode proxy) | Public domain |
