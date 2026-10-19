# Cleaning queue: design

## What the Saros 20 firmware (a288, fw 02.55.44) offers

| Need | Command | Status |
|---|---|---|
| One task with a different mode per room | `app_segment_clean_subdivision` `{data:[{id, fan_power, water_box_mode, mop_mode, repeat, seq_type, mop_type?, mop_power?}], repeat, clean_order_mode, is_new_clean, auto_dry, auto_dustCollection}` | **rejected on fw 02.55.44** (`-10007 invalid params`) with the plugin's item shape `{id, fan_power, water_box_mode, mop_mode, seq_type, repeat}`, as an object or a list, `is_new_clean` 0 or 1. Per-room modes therefore run through the queue. Next lead: `set_customize_clean_mode` (custom mode per room; empty on this robot) |
| The same for drawn zones | `app_zoned_clean_subdivision` | unconfirmed |
| Room order | `set_clean_sequence` / `get_clean_sequence` | exists |
| Zone clean | `app_zoned_clean [[x0, y0, x1, y1, passes]]` | **tested 2026-10-19**: 1×1 m zone, `complete=1`, `clean_type=2`, 1.7 m² in 3 min 19 s |
| Skip the current room | `app_skip_current_cleaning_area` | exists |
| Change suction and water mid-clean | `set_custom_mode`, `set_water_box_custom_mode` | **tested: applies to the running task** |
| Change the mop route mid-clean | `set_mop_mode` | **tested: only changes the default; the running task keeps its route** |
| Time, area and battery left | `app_get_clean_estimate_info` | **tested** (`remaining_time`, `remaining_area`, `percent`) |
| Current room | `get_status` → `cleaning_info.segment_id` | **tested** |
| Resume an interrupted task | `resume_segment_clean`, `resume_zoned_clean`, `app_resume` | exists |

The robot runs **one task at a time**. There is no queue in the firmware: any new `app_segment_clean` or
`app_zoned_clean` replaces the running task. The queue has to live in the app.

## Three levels

1. **Inside one task (native):** several rooms with different modes become a single `app_segment_clean_subdivision`.
   The robot optimises the route and the mop washes itself. This is the fastest case.
2. **Between tasks (our queue):** an ordered list of jobs. When the current task ends, the engine starts the next one.
   Adding, reordering or removing pending jobs **never touches the robot**, so it never cancels anything.
3. **Priority insert:** e.g. a zone right now while rooms are being cleaned. The robot cannot suspend a task to run
   another, so the engine:
   1. records which rooms are already done (from `cleaning_info.segment_id` during the task);
   2. stops the current task and starts the urgent job;
   3. puts a job with the remaining rooms, same modes, back at the front of the queue.
   The room that was half done is redone in full. By default a new job goes in as "next", interrupting nothing;
   "now" is an explicit action.

## End of a task (engine criterion)

- Finished: `in_cleaning` goes from ≠0 to 0, without an error, with `state` ∈ {8 charging, 100 fully charged,
  3 idle}. Confirm with the latest record (`get_clean_summary` → `get_clean_record`): `complete == 1` is a normal end;
  anything else is a cancellation. A `TASK_COMPLETE` push (dps 130) also arrives.
- **Do not use `charge_status`**: it stays at 1 for the whole clean. **Do not use `clean_percent`**: it is relative to
  the estimate and can end below 100% (69% with `complete=1` in the test).

Real sequence (kitchen, 2026-10-18), with `in_cleaning=3` until the end:

| Phase | `state` | Duration |
|---|---|---|
| Mop wash before leaving (`wash_phase` 10/11/12, 100 at the end) | 23 | 3 min |
| Cleaning the room | 18 | 13 min |
| Returning to the dock (`in_returning=1`) | 6 | 30 s |
| Emptying the bin | 22 | 25 s |
| Final mop wash | 23 | ~5 min |
| End: `in_cleaning=0` | 8 | — |

- **Not** finished: mop washes (`state` 23/25/26 with `in_cleaning != 0`), a recharge trip mid-clean, pause
  (`state` 10). While paused, the queue waits.
- Error (`state` 12 or `error_code != 0`): the queue **pauses** and notifies. It never moves on blindly.
- Manual cancellation (e.g. from the official app): the queue pauses and asks whether to continue.

## Automatic merging

Consecutive room jobs with no priority between them can be merged into one `app_segment_clean_subdivision` before
starting. That saves dock trips and extra washes. Only jobs that have not started are merged.

## Platforms

- Android: the engine runs in a foreground service with an ongoing notification ("Vacuuming Kitchen · 42% · Up next:
  Living room"). When the app is swiped away, the service runs the engine itself.
- iOS: there is no continuous background execution. With the app closed, the queue only advances if the engine runs
  elsewhere (a hub). That is why the engine is a Dart module with no UI dependencies.

## Map refresh

The robot's position only arrives inside the map (`get_map_v1`, cloud only, ≈300 ms per fetch, ~470 KB raw).
While cleaning the app fetches it every second, paced from the start of each request; the background service, with
nobody looking, every 30 s. At rest, every 60 s.

## Other findings (2026-10-19)

- `get_multi_maps_list` reports `max_multi_map: 1`: this robot keeps a single map, so multiple floors are not possible.
  It also lists an automatic map backup (`bak_maps`) and each room's type (`tag`: 1 bedroom, 13 dining room,
  14 kitchen, 15 bathroom), which the app shows as icons.
- Room editing commands exist (`name_segment`, `split_segment`, `merge_segment`); their parameters come straight from
  the plugin's map selection. They change the map permanently, so they are not tried without the owner's go-ahead.
- Voice: `get_current_sound` → `language: en`. Installing another voice downloads a package (`dnld_install_sound`)
  from a cloud list that is not in the plugin; not pursued.

