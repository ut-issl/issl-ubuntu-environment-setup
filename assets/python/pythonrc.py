"""Shared interactive Python startup for ISSL environment."""

from __future__ import annotations

import atexit
import builtins
import os
import readline
import sys
from pprint import pprint


def _history_path() -> str:
    histfile = os.environ.get("PYTHONHISTFILE")
    if histfile:
        return histfile

    python_home = os.path.join(os.path.expanduser("~"), ".python")
    return os.path.join(python_home, ".python_history")


def _enable_completion() -> None:
    readline.parse_and_bind("tab: complete")


def _enable_history() -> None:
    histfile = _history_path()
    histdir = os.path.dirname(histfile)
    if histdir:
        os.makedirs(histdir, exist_ok=True)

    if os.path.exists(histfile):
        try:
            readline.read_history_file(histfile)
        except Exception:
            pass

    readline.set_history_length(10_000)

    def save_history() -> None:
        try:
            readline.write_history_file(histfile)
        except Exception:
            pass

    atexit.register(save_history)


def _enable_pretty_display() -> None:
    def displayhook(value: object) -> None:
        if value is None:
            return
        builtins._ = value
        pprint(value, indent=1, width=100, compact=True, depth=3)

    sys.displayhook = displayhook


def _set_colored_prompts() -> None:
    term = os.environ.get("TERM", "")
    if sys.stdout.isatty() and term and term != "dumb":
        purple = "\001\033[0;35m\002"
        brown = "\001\033[0;33m\002"
        normal = "\001\033[0m\002"
        sys.ps1 = f"{purple}>>>{normal} "
        sys.ps2 = f"{brown}...{normal} "


_enable_completion()
_enable_history()
_enable_pretty_display()
_set_colored_prompts()
