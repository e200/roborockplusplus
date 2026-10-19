"""Read-only: logs state transitions until the task ends, reconnecting if the link drops."""
import asyncio, json, time
import aiohttp
from roborock.devices.device_manager import UserParams, create_device_manager
from roborock.devices.file_cache import FileCache
import rr
from test_live import FIELDS, log

async def main():
    email, ud = rr.load_session()
    prev, deadline = None, time.time() + 40 * 60
    while time.time() < deadline:
        try:
            async with aiohttp.ClientSession() as http:
                mgr = await create_device_manager(UserParams(email, ud, "https://euiot.roborock.com"),
                                                  cache=FileCache(rr.SECRETS / "cache"), session=http)
                cmd = (await mgr.get_devices())[0].v1_properties.command
                try:
                    while time.time() < deadline:
                        raw = (await cmd.send("get_status"))[0]
                        snap = {k: raw.get(k) for k in FIELDS} | {"cleaning_info": raw.get("cleaning_info")}
                        if snap != prev:
                            log(json.dumps(snap)); prev = snap
                        if raw.get("in_cleaning") == 0 and raw.get("state") in (8, 100, 3):
                            log("END: in_cleaning=0 and robot stopped"); return
                        await asyncio.sleep(5)
                finally:
                    await mgr.close()
        except Exception as e:
            log(f"link lost ({type(e).__name__}: {e}); reconnecting")
            await asyncio.sleep(5)

asyncio.run(main())
