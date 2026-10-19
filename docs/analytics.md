# Analytics and post-clean summaries

## Data sources (Saros 20, confirmed on 2026-10-18)

| Source | Command | What it gives | Limit |
|---|---|---|---|
| All-time totals | `get_clean_summary` | time (s), area (mm²), clean count, empty count, record ids | — |
| Per-clean record | `get_clean_record [id]` | `begin`, `end`, `duration`, `area`, `cleaned_area`, `complete`, `finish_reason`, `start_type`, `clean_type`, `wash_count`, `dust_collection_status`, `avoid_count`, `has_omission`, `is_replenish`, `clean_times`, `extra_time` | **the robot only keeps the last 21** |
| Map of each past clean | `get_clean_record_map_v2 {start_time}` | replies `ok`; the map arrives separately (MAP_RESPONSE, protocol 301) | only recent ones; the app caches them |
| Consumables | `get_consumable` | main and side brush, filter and sensor hours; empty count | — |
| Estimate | `app_get_clean_estimate_info` | planned and remaining area, time and battery | only during a task |
| Our telemetry | `get_status` every few seconds during the task | timeline per phase and per room (`cleaning_info.segment_id`), battery, settings used, mid-clean changes, errors | only while the app/service is connected |

Records come with an empty `area_ids`. **The robot does not store time or area per room**: that only exists if the app
records it during the clean.

Codes (from python-roborock):
- `finish_reason`: 52/54/55/56/57 finished; 21/29/35-37/43/48-50/60/103 stopped manually; 61/62 area unreachable;
  45/65 localisation failure; 67/68 washing error.
- `start_type`: 1 button, 2 app, 3 schedule, 101 routine, 8xx voice assistants.
- `clean_type`: 1 whole home, 2 drawn zone, 3 rooms, 5 patrol.

## Storage

Local storage in the app, synced:
- when each task ends (end detected by the queue);
- when the app opens (to catch cleans started by the button, a schedule or the official app).

Records are deduplicated by `begin`. Since the robot keeps only 21, long history only exists from the moment the app
starts syncing.

## Post-clean summary

Notification and card as soon as the task ends:
- rooms, duration, m², mop washes, empties, obstacles avoided, whether it finished or why it stopped;
- timeline coloured by phase (wash mop · clean Kitchen · return · empty · wash mop);
- the clean's map with its path;
- comparison with the usual for those rooms ("8 min faster than average");
- with `has_omission`: a "Clean the missed areas" button (`app_start_replenish_clean_area`).

## Analytics screen

- Per room: last clean, frequency, average duration, m²/min, time since the last mop.
- Weekly calendar / heat map.
- Totals: hours, m², cleans, empties (all time and per period).
- Consumables with a replacement forecast from real usage.
- Reliability: interruptions, errors and unreachable areas over time.
- Clean sources: app, schedule, routine, button.
