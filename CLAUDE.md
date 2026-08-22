# CLAUDE.md — AAGAHI
Flash-drought early warning for smallholder farmers in Pakistan. Flutter app +
Python signal pipeline. Read this before writing any code.
---
## 1. The one rule that outranks everything
**Never render an absence of knowledge as a low-risk reading.**
If satellite coverage is insufficient, if the cache is stale, if the model
fails schema validation — the app says so, out loud, in Urdu. It does not show
a default, a zero, a placeholder, or a greyed-out gauge that a farmer could
mistake for "you are fine."
This is not a style preference. A farmer who sees a fabricated low-risk score
does not irrigate, and loses a crop. Any code change that makes ignorance look
like safety is a defect regardless of how clean it is.
Concretely:
- `RiskBand` has **no** `unknown` member. Do not add one.
- Unscorable cells return `NotScorableFailure`, never a `RiskAssessment`.
- An unknown risk band from the server **throws**. It does not default.
- Stale cached data renders with its age, visibly and audibly.
---
## 2. Minimalism — the standard for "is this code worth writing"
The bar for adding code is: **could a well-maintained package do this?**
If yes, use the package. We are not building a framework.
**Use the library. Do not hand-roll:**
| Need | Use | Do not write |
|---|---|---|
| State management | `flutter_riverpod` | A custom InheritedWidget or singleton bus |
| Local DB | `drift` + `sqlcipher_flutter_libs` | Raw SQL strings, a custom ORM, a JSON-file store |
| HTTP | `dio` with interceptors | A custom retry loop or `HttpClient` wrapper |
| Secure storage | `flutter_secure_storage` | Anything touching Keystore directly |
| Background work | `workmanager` | A custom isolate scheduler or timer |
| Connectivity | `connectivity_plus` | Pinging a URL on a timer |
| Audio | `just_audio` | A platform channel |
| TTS / STT | `flutter_tts`, `speech_to_text` | A platform channel |
| Dates / numbers / plurals | `intl` | Manual formatting or string interpolation |
| Equality / hashing | `equatable` | Hand-written `==` and `hashCode` |
| Result types | `dartz` `Either` | A custom `Result<T>` sealed class |
| Charts, if ever needed | `fl_chart` | A CustomPainter |
**The exception, and the only one:** `RiskRing` is a hand-written
`CustomPainter` because no chart package draws a trace *inside* a gauge arc,
and that composition is the product's signature. If you find yourself writing
a second CustomPainter, stop and justify it first.
**Also do not add:**
- Abstraction with one implementation and no test double. An interface exists
  to be faked in a test or swapped in production. If it is neither, delete it.
- Wrapper classes that only forward calls.
- `AppConstants` god-files. Put a constant next to what uses it.
- Config for things nobody will configure.
- Defensive null checks on values the type system already guarantees.
- Comments restating the code. Comment **why**, never **what**.
**Before adding a package**, check it: pub.dev score, last publish within
~12 months, null-safe, and it actually reduces our code. Adding a 400 KB
dependency to save 20 lines fails on APK budget (CON-03, ≤ 40 MB).
---
## 3. Architecture
Clean architecture, one folder per feature. **The dependency arrow always
points inward.**
```
lib/
  core/            theme, errors, network, shared utils
  features/<name>/
    domain/        entities, repository interfaces, use cases  ← no Flutter
    data/          models, data sources, repository impls
    presentation/  providers, screens, feature widgets
  shared_widgets/  cross-feature widgets
```
Hard rules, enforced in CI:
- **`domain/` imports zero Flutter.** No `material.dart`, no `BuildContext`.
  Use cases must be testable with `dart test`, no widget harness, no device.
- `presentation/` depends on `domain/`. `data/` depends on `domain/`.
  `domain/` depends on **nothing** in this project.
- Widgets never construct dependencies. Everything arrives via Riverpod
  overrides wired in `main.dart` (composition root).
- Repositories return `Either<Failure, T>`. Never `null` to mean "it failed",
  never a thrown exception crossing the repository boundary.
- Exceptions live in `data/`. `Failure`s live in `domain/`. Convert at the
  repository, nowhere else.
**Do not create a feature folder until there are at least two files for it.**
Premature structure is as expensive as no structure.
---
## 4. Quality gates
Every one of these must pass before you report a task complete.
```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos      # zero warnings, zero infos
flutter test                       # all green
```
**Maintainability targets:**
| Property | Target | How it's checked |
|---|---|---|
| Domain + use case line coverage | ≥ 80 % | `flutter test --coverage` |
| Cyclomatic complexity per function | ≤ 15 | review; split if exceeded |
| Function length | ≤ 40 lines | review |
| File length | ≤ 400 lines | split by responsibility |
| Public API documented | 100 % of `domain/` | `///` comments |
| Analyzer warnings | 0 | `--fatal-infos` |
| Nesting depth | ≤ 4 | extract a widget or method |
**Testing, in priority order:**
1. Domain entity invariants and use case logic — pure Dart, fast, no mocks
   beyond a fake repository.
2. Repository policy — offline-first fallbacks, failure mapping, the
   not-scorable path. Use `mocktail`.
3. Widget tests for each state a screen can be in: loading, scored, stale,
   not-scorable, offline.
4. Golden tests for Urdu RTL layout and 200 % text scale.
**Test names state behaviour, not method names.**
Good: `returns cached assessment when offline`
Bad: `testGetLatestAssessment`
Do not write a test that only asserts a mock was called. Assert the observable
outcome.
---
## 5. Non-negotiable product constraints
These come from the SRS and from field testing. Do not "improve" them without
asking.
- **Push-to-talk only.** Never voice activity detection. VAD fails in wind and
  in a noisy shop; this was validated in prior fieldwork.
- **Offline reads always work.** Every read path serves from the local DB.
  Network is an enhancement, never a precondition.
- **The outbox is durable.** Locally created records survive process death,
  restart, and app upgrade. Zero data loss is the target, not a goal.
- **Conflicts on farmer-authored content are never auto-resolved.** Surface
  both versions and let the user choose. Last-writer-wins applies only to
  read-only mirrors and telemetry.
- **Every screen is completable by voice.** No task needed to receive and act
  on a warning may require reading text.
- **Touch targets ≥ 48 dp**, 8 dp apart. The user may be wearing work gloves.
- **Colour never carries meaning alone.** Colour + glyph shape + word, always.
- **Data budget ≤ 5 MB/month** for a typical farmer. Compress, use ETags,
  never poll.
- **APK ≤ 40 MB.**
- **Reference device: Android 9, 2 GB RAM.** If it does not run well there, it
  does not ship.
---
## 6. Security
- Parameterised queries only. Drift generates these — do not drop to raw SQL.
- Never put a parcel id, coordinate, or phone number in a URL query string.
  Path segments or request bodies only. Query strings leak into proxy logs.
- Secrets come from `--dart-define` or the secure store. Never in source,
  never in `pubspec.yaml`, never in a committed `.env`.
- Never log tokens, coordinates, or phone numbers. Use `dart:developer` `log`,
  never `print`.
- Certificate pinning failures are hostile, not flaky. Never retry, never
  downgrade.
- Validate uploads by magic bytes, not file extension.
---
## 7. Working style
**Before writing code:**
1. State your plan in 3–6 bullets. Wait for confirmation on anything
   architectural.
2. Read the existing code first. Match its conventions. Do not restyle files
   you are not otherwise changing.
**While writing:**
- Small commits, conventional format: `feat(risk): add stale-data banner`.
- One concern per commit. Do not mix a refactor with a feature.
- Write the test with the code, not after the milestone.
**When you finish a task, report:**
- What changed and why.
- Which quality gates you ran and their output.
- Anything you could not verify, stated plainly.
**Do not:**
- Claim something works if you have not run it.
- Silence an analyzer warning with an ignore comment instead of fixing it.
- Leave `TODO` without a linked issue number.
- Refactor beyond the task scope without asking.
- Generate placeholder or lorem content in shipped code.
**If a requirement seems wrong, say so before implementing it.** Two real
defects in the Python pipeline were found this way — the label definition
matched 40 % of all days, and unlabelled rows were silently becoming `False`.
Both would have survived into a trained model.
---
## 8. Known open items
- **SIF is unavailable in Google Earth Engine.** The pipeline runs on MODIS
  NDVI in degraded mode and records that on every prediction. Do not write
  code, copy, or comments claiming SIF is in use.
- **The flash-drought label needs the two-sided criterion** (start above 40th
  percentile, end below 20th, within the horizon). A bare 20-point drop is too
  loose. Do not revert this.
- **Never report bare accuracy anywhere.** The positive class is 2–6 % of
  days, so "95 % accurate" is what a model that always says "no" achieves.
  Report precision, recall, PR-AUC.
- **The pilot district is Faisalabad–Jhang, Punjab** (`config.PILOT_REGION`).
  Confirmed August 2026 against the Earth Engine Data Catalog: SMAP L4 and
  ERA5-Land both have continuous global coverage there (flat agricultural
  plain, no permafrost/ocean/dense-canopy attenuation). That same check found
  `NASA/SMAP/SPL4SMGP/007` deprecated in favour of `/008` — `config.py` has
  been updated; do not revert to `/007`.
---
## 9. Repository layout
This is a monorepo with two independent projects. Neither depends on the
other at build time; they share only the domain concepts in this file and in
the SRS.
```
aagahi-app/       Flutter mobile client (see aagahi-app/pubspec.yaml)
aagahi-signal/    Python Earth-observation pipeline and model training
                  (see aagahi-signal/README.md)
```
Everything in sections 1–8 above is written for `aagahi-app/`. The Python
side has its own, lighter conventions documented in `aagahi-signal/README.md`
— principally: pure-pandas modules stay unit-testable without network access,
splits are temporal only (never shuffled), and bare accuracy is never
reported.
