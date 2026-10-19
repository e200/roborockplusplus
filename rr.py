"""Roborock cloud login and React Native plugin download.

  python rr.py request-code EMAIL          # emails a login code
  python rr.py login EMAIL CODE            # saves the session to secrets/session.json
  python rr.py fetch                       # lists devices and downloads plugins
"""
import asyncio
import json
import os
import secrets
import sys
from pathlib import Path

import aiohttp
from roborock.data import UserData
from roborock.web_api import RoborockApiClient

ROOT = Path(__file__).parent
SECRETS = ROOT / "secrets"
SESSION = SECRETS / "session.json"
DEVICE_ID = SECRETS / "device_id"
OUT = ROOT / "plugins" / "remote"


def client(email: str, http: aiohttp.ClientSession, base_url: str | None = None) -> RoborockApiClient:
    """The login code is bound to the device id, so it must stay the same across runs."""
    SECRETS.mkdir(mode=0o700, exist_ok=True)
    if not DEVICE_ID.exists():
        DEVICE_ID.write_text(secrets.token_urlsafe(16))
        os.chmod(DEVICE_ID, 0o600)
    api = RoborockApiClient(email, base_url=base_url, session=http)
    api._device_identifier = DEVICE_ID.read_text()
    return api


def save_session(email: str, user_data: UserData) -> None:
    SESSION.write_text(json.dumps({"email": email, "user_data": user_data.as_dict()}, indent=2))
    os.chmod(SESSION, 0o600)


def load_session() -> tuple[str, UserData]:
    data = json.loads(SESSION.read_text())
    return data["email"], UserData.from_dict(data["user_data"])


async def download(session: aiohttp.ClientSession, url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    async with session.get(url) as resp:
        resp.raise_for_status()
        dest.write_bytes(await resp.read())
    print(f"  -> {dest} ({dest.stat().st_size} bytes)")


async def main(cmd: str, args: list[str]) -> None:
    async with aiohttp.ClientSession() as http:
        if cmd == "request-code":
            await client(args[0], http).request_code_v4()
            print("Code sent to", args[0])
        elif cmd == "login":
            api = client(args[0], http)
            save_session(args[0], await api.code_login_v4(args[1]))
            print("Session saved to", SESSION)
        elif cmd == "fetch":
            email, user_data = load_session()
            # The region is fixed per account; skip the email lookup, which is tightly rate limited.
            api = client(email, http, base_url="https://euiot.roborock.com")
            home = await api.get_home_data_v3(user_data)
            (OUT).mkdir(parents=True, exist_ok=True)
            (OUT / "home_data.json").write_text(json.dumps(home.as_dict(), indent=2, default=str))
            products = {p.id: p for p in home.products}
            for dev in home.devices + home.received_devices:
                p = products.get(dev.product_id)
                print(f"{dev.name}: model={p.model if p else '?'} product_id={dev.product_id} fw={dev.fv}")
                url = await api.download_code(user_data, dev.product_id)
                print("  plugin:", url)
                await download(http, url, OUT / f"{p.model if p else dev.product_id}.zip")
            for category, url in (await api.download_category_code(user_data)).items():
                print(f"category {category}: {url}")
                await download(http, url, OUT / "category" / f"{category}.zip")


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1], sys.argv[2:]))
