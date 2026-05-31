from __future__ import annotations

import os
import re
import subprocess
import sys
import time
from datetime import datetime

DEBUG = os.environ.get("DISPLAY_SYNC_DEBUG") == "1"
POLL_SECONDS = 3

# EDIDs of known dummy plugs. Any connected output not in this set is treated
# as a real display. Add more UUIDs here if additional dummy plugs are used.
DUMMY_PLUG_UUIDS: frozenset[str] = frozenset({
    "d5ec3d5d-0120-4826-8b84-0e8dbec0af1c",
})

ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*m")
OUTPUT_HEADER = re.compile(r"^Output:\s+\d+\s+(\S+)\s+([0-9a-f-]{36})")


def log_debug(message: str) -> None:
    if DEBUG:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(
            f"[display-sync] {timestamp} {message}",
            file=sys.stderr,
            flush=True,
        )


def get_outputs() -> list[dict]:
    try:
        result = subprocess.run(
            ["kscreen-doctor", "-o"],
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception as exc:
        log_debug(f"kscreen-doctor failed: {exc}")
        return []

    text = ANSI_ESCAPE.sub("", result.stdout or result.stderr)
    outputs: list[dict] = []
    current: dict | None = None

    for line in text.splitlines():
        m = OUTPUT_HEADER.match(line)
        if m:
            if current is not None:
                outputs.append(current)
            current = {
                "name": m.group(1),
                "uuid": m.group(2),
                "connected": False,
                "enabled": False,
            }
        elif current is not None:
            token = line.strip()
            if token == "enabled":
                current["enabled"] = True
            elif token == "connected":
                current["connected"] = True

    if current is not None:
        outputs.append(current)

    return outputs


def is_dummy(output: dict) -> bool:
    return output.get("uuid") in DUMMY_PLUG_UUIDS


def real_display_connected(outputs: list[dict]) -> bool:
    return any(o.get("connected") and not is_dummy(o) for o in outputs)


def set_dummy_plugs_enabled(outputs: list[dict], enable: bool) -> None:
    action = "enable" if enable else "disable"
    for output in outputs:
        if not is_dummy(output):
            continue
        name = output.get("name")
        if not isinstance(name, str):
            continue
        command = ["kscreen-doctor", f"output.{name}.{action}"]
        try:
            if DEBUG:
                subprocess.run(command, check=True)
            else:
                subprocess.run(
                    command,
                    check=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        except Exception as exc:
            log_debug(f"command failed ({' '.join(command)}): {exc}")


def main() -> None:
    last_state: str | None = None
    while True:
        outputs = get_outputs()
        has_real = real_display_connected(outputs)
        state = "real display connected" if has_real else "no real display"
        dummy_should_enable = not has_real

        if state != last_state:
            action = "enable" if dummy_should_enable else "disable"
            log_debug(f"{state}; {action} dummy plug(s)")
            last_state = state

        set_dummy_plugs_enabled(outputs, dummy_should_enable)
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
