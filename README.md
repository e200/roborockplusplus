# Roborock++

An Android app (Flutter) for the Roborock Saros 20, built to do everything the official app does, and what it lacks:

- a **cleaning queue**: jobs run one after another, and adding jobs never cancels the running clean;
- **change suction and water mid-clean** without cancelling it;
- **different modes per room**, extra zones drawn on the map while a clean is running;
- a clear **live map** with furniture, door sills, obstacles and map editing (no-go, no-mop, virtual walls);
- **routines** with schedules, **history** with each clean's map, charts and per-room stats;
- **notifications** and a live lock-screen status, which keep working with the app closed.

The UI is available in **English and Portuguese** (it follows the phone's language).

It talks to the robot directly: the local V1 protocol (L01, AES-256-GCM) with a fallback to the cloud over MQTT.

## Layout

- `app/`: the app. `cd app && flutter test && flutter build apk --release`
- `docs/`: reverse-engineering notes (queue design, analytics, gap review)
- `rr.py`, `probe.py`, …: Python tools used during the research (python-roborock)

## Translations

Texts live in `app/lib/l10n/app_en.arb` (template) and `app_pt.arb`. To add a language, copy `app_en.arb` to
`app_<code>.arb`, translate the values and run `flutter gen-l10n`.

## Privacy

The Roborock session (`secrets/`) and real home maps never go into the repository.

A personal project, not affiliated with Roborock.
