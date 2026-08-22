# Cached / bundled audio goes here

Server-rendered Urdu briefings are downloaded at runtime and cached to local
storage (FR-SYNC-008) - they do not live in this directory. This folder is
for audio bundled *with the app binary*: the pre-recorded human-voice phrase
inventory that is the fallback when synthetic TTS intelligibility is
inadequate (FR-LOCL-009, RISK-04). None exist yet; add them here as
`snake_case` `.mp3` or `.m4a` files and list each one under `flutter.assets`
in `pubspec.yaml` if per-file (rather than whole-directory) referencing is
ever needed.
