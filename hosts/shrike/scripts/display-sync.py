from __future__ import annotations

import json
import os
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


def log_debug(message: str) -> None:
    if DEBUG:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(
            f"[display-sync] {timestamp} {message}",
            file=sys.stderr,
            flush=True,
        )


def parse_embedded_json(text: str):
    decoder = json.JSONDecoder()
    for marker in ("{", "["):
        start = text.find(marker)
        while start != -1:
            try:
                payload, _ = decoder.raw_decode(text[start:])
                if isinstance(payload, (dict, list)):
                    return payload
            except json.JSONDecodeError:
                pass
            start = text.find(marker, start + 1)
    return None


def run_kscreen_json():
    commands = (
        ["kscreen-doctor", "--json", "-o"],
        ["kscreen-doctor", "-j", "-o"],
    )
    for command in commands:
        try:
            completed = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
            )
            payload = parse_embedded_json(completed.stdout)
            if payload is None and completed.stderr:
                payload = parse_embedded_json(completed.stderr)
            if payload is not None:
                return payload
            if DEBUG:
                log_debug(f"no JSON payload found ({' '.join(command)})")
        except Exception as exc:
            if DEBUG:
                log_debug(f"query failed ({' '.join(command)}): {exc}")
    return None


def get_outputs():
    payload = run_kscreen_json()
    if payload is None:
        return []

    outputs = (
        payload.get("outputs", []) if isinstance(payload, dict) else payload
    )
    return outputs if isinstance(outputs, list) else []


def is_dummy(output: dict) -> bool:
    return output.get("uuid") in DUMMY_PLUG_UUIDS


def real_display_connected(outputs: list) -> bool:
    return any(
        isinstance(o, dict) and o.get("connected") and not is_dummy(o)
        for o in outputs
    )


def set_dummy_plugs_enabled(outputs: list, enable: bool) -> None:
    action = "enable" if enable else "disable"
    for output in outputs:
        if not isinstance(output, dict) or not is_dummy(output):
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
            if DEBUG:
                log_debug(f"command failed ({' '.join(command)}): {exc}")


def main() -> None:
    last_state = None
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
