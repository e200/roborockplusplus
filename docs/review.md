# Review: Roborock++ vs the official app vs requests (snapshot of 2026-10-18)

This is the gap review that drove the work at the time; much of it has been done since (map editing, routines,
furniture, background service, charts). Kept for the reasoning.

Legend: ✅ done and tested on the robot · 🟡 done, untested on the robot or incomplete · ❌ missing

## User requests

| Request | Status |
|---|---|
| Change settings without cancelling the clean | ✅ suction and water live; mop route only for the next task (firmware limit) |
| Cleaning queue without cancelling the previous clean | ✅ engine tested with the real sequence; 🟡 an end-to-end real clean is missing |
| See what it is doing now and next | ✅ Now screen + notification |
| Different cleans per room | 🟡 through the queue (consecutive tasks); `app_segment_clean_subdivision` (one task) untested |
| Zone clean during another clean | ❌ drawing zones on the map |
| Better map and easy editing | 🟡 live vector map ✅; editing ❌ |
| Analytics and summaries | 🟡 history, totals, per room, summary; charts and per-clean maps missing |
| Notifications | 🟡 alerts and clean finished; ❌ lock screen with progress; ❌ with the app force-closed |
| Light / dark / automatic theme | ❌ |

## Official app (a288 plugin) features still missing

| Area | Missing |
|---|---|
| Cleaning | drawn zones, go to a point, spot clean, per-room mode in a single task, room order |
| Map | rename, split and merge rooms, virtual walls, no-go and no-mop zones, carpets, multiple floors, backup |
| Schedules | create, edit and delete (`get/set/upd/del_timer`, `set_server_timer`) |
| Do not disturb | hours (`get/set_dnd_timer`) |
| Dock | empty mode, wash frequency, mop drying and its duration, water temperature |
| Carpets | mode (avoid/lift mop), deep clean, priority |
| Robot | firmware, network, obstacles with photos, remote control, language/voice |
| History | each clean's map (`get_clean_record_map_v2`) |
| Camera | live video (out of scope for now) |

## Proposed order (at the time)

1. Theme, lock screen notification with progress, redesigned Now screen, drawn zones in the queue.
2. Service with the logic inside (queue and alerts with the app closed).
3. Map editing (with a backup before each change).
4. Schedules, do not disturb, dock and carpet settings.
5. Each clean's map in history, charts.
