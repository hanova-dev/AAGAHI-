# AAGAHI

Flash-drought early warning for smallholder farmers in Pakistan
(VIICER 2026, Institut Ekosains Borneo). Two independent projects in this
monorepo:

| Project | What it is | Start here |
|---|---|---|
| [`aagahi-app/`](aagahi-app) | Offline-first, voice-native Flutter client | [`aagahi-app/pubspec.yaml`](aagahi-app/pubspec.yaml) |
| [`aagahi-signal/`](aagahi-signal) | Python Earth-observation pipeline + model training | [`aagahi-signal/README.md`](aagahi-signal/README.md) |

[`CLAUDE.md`](CLAUDE.md) is the project constitution — read it before writing
code in either project. The full requirements are in
`../documents/AAGAHI_SRS.docx`, the 46 reference screens in
`../documents/AAGAHI_screens_v2.html`, and the twelve UML diagrams as
`../documents/0*.png`.

## Status

This scaffold is a folder architecture, not a working app: it places every
file that was already written, fills in the interfaces and models those files
import but that didn't exist yet, and adds the two files that were referenced
but missing (`aagahi_signal/train.py`, and this layout itself). It has not had
`flutter create`'s platform folders generated, has no composition-root wiring
(`riskRepositoryProvider` / `localisationProvider` still throw
`UnimplementedError` by design — see `aagahi-app/lib/main.dart`), and the
Python side has not been run against live Earth Engine credentials. Those are
Phase 1 of the kickoff plan, not this step.

## Layout

```
CLAUDE.md                   project constitution (Flutter-focused; S9 covers the Python side)
aagahi-app/                 Flutter client, Clean Architecture per feature
  lib/core/                 theme, error types (Failure/Exception)
  lib/features/risk/        domain -> data -> presentation, the one feature built so far
  lib/shared_widgets/       GlassCard, ListenPill, RiskRing - cross-feature widgets
  test/                     mirrors lib/ structure
aagahi-signal/               Python EO pipeline
  aagahi_signal/config.py    dataset IDs, pilot region, thresholds
  aagahi_signal/ee_client.py Earth Engine access, retries, quality flags
  aagahi_signal/features.py  pure-pandas rate-of-decline features + label
  aagahi_signal/pipeline.py  fetch + validate CLI
  aagahi_signal/train.py     LightGBM training, temporal split, SHAP, metrics
  tests/                     unit tests over features.py (no EE credentials needed)
```
