"""Robot connection test (read-only).

  python probe.py                 # status, rooms, network
  python probe.py CMD [JSON]      # sends an arbitrary RPC command
"""
import asyncio
import json
import sys

import aiohttp
from roborock.devices.device_manager import UserParams, create_device_manager
from roborock.devices.file_cache import FileCache

import rr


async def main(args: list[str]) -> None:
    email, user_data = rr.load_session()
    params = UserParams(username=email, user_data=user_data, base_url="https://euiot.roborock.com")
    async with aiohttp.ClientSession() as http:
        manager = await create_device_manager(params, cache=FileCache(rr.SECRETS / "cache"), session=http)
        try:
            device = (await manager.get_devices())[0]
            props = device.v1_properties
            print(f"{device.name}: connected={device.is_connected} local={device.is_local_connected}")
            if args:
                result = await props.command.send(args[0], json.loads(args[1]) if len(args) > 1 else None)
                print(json.dumps(result, indent=2, default=str))
                return
            for trait in (props.status, props.rooms, props.network_info, props.consumables):
                await trait.refresh()
            s = props.status
            print(f"state={s.state_name} battery={s.battery}% suction={s.fan_speed_name} error={s.error_code_name}")
            print("rooms:", [(r.segment_id, r.name) for r in props.rooms.rooms])
            print("network:", props.network_info.ip, props.network_info.ssid)
        finally:
            await manager.close()


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1:]))
