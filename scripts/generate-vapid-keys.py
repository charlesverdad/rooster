"""Auto-generate VAPID keys for web push notifications.

Reads .env (copies from .env.example if missing). If VAPID_PUBLIC_KEY is
empty, generates a new keypair and writes it back. Idempotent — does nothing
if keys are already present.
"""

import base64
import shutil
import sys
from pathlib import Path

from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from py_vapid import Vapid


ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
ENV_EXAMPLE_PATH = ENV_PATH.parent / ".env.example"


def ensure_env_file() -> None:
    if not ENV_PATH.exists():
        if ENV_EXAMPLE_PATH.exists():
            shutil.copy(ENV_EXAMPLE_PATH, ENV_PATH)
            print(f"Copied {ENV_EXAMPLE_PATH.name} -> {ENV_PATH.name}")
        else:
            sys.exit(f"ERROR: Neither {ENV_PATH} nor {ENV_EXAMPLE_PATH} found.")


def read_env() -> list[str]:
    return ENV_PATH.read_text().splitlines(keepends=True)


def env_value(lines: list[str], key: str) -> str:
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(f"{key}="):
            return stripped.split("=", 1)[1].strip()
    return ""


def set_env_value(lines: list[str], key: str, value: str) -> list[str]:
    updated = []
    for line in lines:
        if line.strip().startswith(f"{key}="):
            updated.append(f"{key}={value}\n")
        else:
            updated.append(line)
    return updated


def generate_vapid_keys() -> tuple[str, str]:
    vapid = Vapid()
    vapid.generate_keys()

    raw_pub = vapid.public_key.public_bytes(
        encoding=Encoding.X962,
        format=PublicFormat.UncompressedPoint,
    )
    public_key = base64.urlsafe_b64encode(raw_pub).rstrip(b"=").decode()

    raw_priv = vapid.private_key.private_numbers().private_value.to_bytes(32, "big")
    private_key = base64.urlsafe_b64encode(raw_priv).rstrip(b"=").decode()
    return public_key, private_key


def main() -> None:
    ensure_env_file()
    lines = read_env()

    if env_value(lines, "VAPID_PUBLIC_KEY"):
        print("VAPID keys already set in .env — skipping generation.")
        return

    print("Generating VAPID keypair...")
    public_key, private_key = generate_vapid_keys()

    lines = set_env_value(lines, "VAPID_PUBLIC_KEY", public_key)
    lines = set_env_value(lines, "VAPID_PRIVATE_KEY", private_key)
    lines = set_env_value(
        lines, "VAPID_SUBJECT", "mailto:rooster-dev@heartbeatchurch.com.au"
    )

    ENV_PATH.write_text("".join(lines))
    print(f"VAPID keys written to {ENV_PATH.name}")
    print(f"  Public key: {public_key}")


if __name__ == "__main__":
    main()
