"""Live test: cleans the kitchen, changes settings mid-clean and logs states until it ends."""
import asyncio
import json
import time

import aiohttp
from roborock.devices.device_manager import UserParams, create_device_manager
from roborock.devices.file_cache import FileCache

import rr

KITCHEN = 7
FIELDS = ("state", "in_cleaning", "in_returning", "clean_percent", "fan_power", "water_box_mode", "mop_mode",
          "wash_phase", "wash_status", "back_type", "charge_status", "error_code", "dock_error_status", "common_status")
LOG = rr.ROOT / "test_live.log"


def log(msg: str) -> None:
    line = f"{time.strftime('%H:%M:%S')} {msg}"
    print(line, flush=True)
    with LOG.open("a") as f:
        f.write(line + "\n")


async def main() -> None:
    email, user_data = rr.load_session()
    async with aiohttp.ClientSession() as http:
        manager = await create_device_manager(
            UserParams(email, user_data, "https://euiot.roborock.com"),
            cache=FileCache(rr.SECRETS / "cache"), session=http)
        cmd = (await manager.get_devices())[0].v1_properties.command
        try:
            log(f"start: {await cmd.send('app_segment_clean', [{'segments': [KITCHEN], 'repeat': 1}])}")
            started, prev, changes_sent = time.time(), None, 0
            while time.time() - started < 45 * 60:
                raw = (await cmd.send("get_status"))[0]
                snap = {k: raw.get(k) for k in FIELDS} | {"cleaning_info": raw.get("cleaning_info")}
                if snap != prev:
                    log(json.dumps(snap))
                    prev = snap
                elapsed = time.time() - started
                cleaning_now = raw.get("in_cleaning") and not raw.get("in_returning") and raw.get("state") == 18
                if cleaning_now and changes_sent == 0 and elapsed > 60:
                    log(f"set_custom_mode 102 -> {await cmd.send('set_custom_mode', [102])}")
                    log(f"set_water_box_custom_mode 225 -> {await cmd.send('set_water_box_custom_mode', [225])}")
                    changes_sent = 1
                elif cleaning_now and changes_sent == 1 and elapsed > 120:
                    log(f"set_mop_mode 304 -> {await cmd.send('set_mop_mode', [304])}")
                    changes_sent = 2
                if elapsed > 90 and not raw.get("in_cleaning") and raw.get("charge_status") == 1:
                    log("END: robot docked, in_cleaning=0")
                    break
                await asyncio.sleep(5)
        finally:
            await manager.close()


if __name__ == "__main__":
    asyncio.run(main())
