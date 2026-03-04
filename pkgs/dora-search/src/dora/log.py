"""Subset of the Dora logging helpers used by Demucs at runtime."""

from __future__ import annotations

import logging
import sys
import time
from collections.abc import Iterable, Sized
from typing import Optional


def _colorize(text: str, code: str) -> str:
    return f"\033[{code}m{text}\033[0m"


class LogProgress:
    def __init__(
        self,
        logger: logging.Logger,
        iterable: Iterable,
        updates: int = 5,
        min_interval: int = 1,
        time_per_it: bool = False,
        total: Optional[int] = None,
        name: str = "LogProgress",
        level: int = logging.INFO,
    ) -> None:
        self.iterable = iterable
        if total is None:
            assert isinstance(iterable, Sized)
            total = len(iterable)
        self.total = total
        self.updates = updates
        self.min_interval = min_interval
        self.time_per_it = time_per_it
        self.name = name
        self.logger = logger
        self.level = level

    def update(self, **infos) -> bool:
        self._infos = infos
        return self._will_log

    def __iter__(self):
        self._iterator = iter(self.iterable)
        self._will_log = False
        self._index = -1
        self._infos = {}
        self._begin = time.time()
        return self

    def __next__(self):
        if self._will_log:
            self._log()
            self._will_log = False
        value = next(self._iterator)
        self._index += 1
        if self.updates > 0:
            log_every = max(self.min_interval, self.total // self.updates)
            if self._index >= 1 and self._index % log_every == 0:
                self._will_log = True
        return value

    def _log(self) -> None:
        speed = (1 + self._index) / max(time.time() - self._begin, 1e-12)
        infos = " | ".join(f"{k.capitalize()} {v}" for k, v in self._infos.items())
        if speed < 1e-4:
            speed_display = "oo sec/it"
        elif self.time_per_it and speed < 1:
            speed_display = f"{1 / speed:.2f} sec/it"
        elif self.time_per_it:
            speed_display = f"{1000 / speed:.1f} ms/it"
        elif speed < 0.1:
            speed_display = f"{1 / speed:.1f} sec/it"
        else:
            speed_display = f"{speed:.2f} it/sec"
        out = f"{self.name} | {self._index}/{self.total} | {speed_display}"
        if infos:
            out += " | " + infos
        self.logger.log(self.level, out)


def bold(text: str) -> str:
    return _colorize(text, "1")


def red(text: str) -> str:
    return _colorize(text, "31")


def simple_log(first: str, *args, color=None) -> None:
    print(bold(first), *args, file=sys.stderr)


def fatal(*args):
    simple_log("FATAL:", *args)
    raise SystemExit(1)


_dora_handler = None


def setup_logging(verbose: bool = False) -> None:
    global _dora_handler
    log_level = logging.DEBUG if verbose else logging.INFO
    logger = logging.getLogger("dora")
    logger.setLevel(log_level)
    _dora_handler = logging.StreamHandler(sys.stderr)
    _dora_handler.setFormatter(logging.Formatter("%(levelname)s:%(name)s:%(message)s"))
    _dora_handler.setLevel(log_level)
    logger.addHandler(_dora_handler)


def disable_logging() -> None:
    assert _dora_handler is not None
    logger = logging.getLogger("dora")
    logger.removeHandler(_dora_handler)
