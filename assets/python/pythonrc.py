"""Shared interactive Python startup for ISSL environment."""

from __future__ import annotations

import atexit
import os
import readline
import rlcompleter
import sys
from pprint import pprint


def _history_path() -> str:
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.path.expanduser("~"), ".config"))
    python_home = os.environ.get("ISSL_PYTHON_HOME", os.path.join(config_home, "issl", "python"))
    return os.path.join(python_home, ".python_history")


def _enable_completion() -> None:
    rlcompleter.Completer()
    readline.parse_and_bind("tab: complete")


def _enable_history() -> None:
    histfile = _history_path()
    histdir = os.path.dirname(histfile)
    if histdir:
        os.makedirs(histdir, exist_ok=True)

    if os.path.exists(histfile):
        readline.read_history_file(histfile)

    readline.set_history_length(10_000)
    atexit.register(readline.write_history_file, histfile)


def _enable_pretty_display() -> None:
    def displayhook(value: object) -> None:
        if value is None:
            return
        builtins_obj = __builtins__
        if isinstance(builtins_obj, dict):
            builtins_obj["_"] = value
        else:
            setattr(builtins_obj, "_", value)
        pprint(value, indent=1, width=100, compact=True, depth=3)

    sys.displayhook = displayhook


def _set_colored_prompts() -> None:
    term = os.environ.get("TERM", "")
    if term in {"xterm-color", "xterm-256color", "linux", "screen", "screen-256color", "screen-bce"}:
        purple = "\001\033[0;35m\002"
        brown = "\001\033[0;33m\002"
        normal = "\001\033[0m\002"
        sys.ps1 = f"{purple}>>>{normal} "
        sys.ps2 = f"{brown}...{normal} "


_enable_completion()
_enable_history()
_enable_pretty_display()
_set_colored_prompts()
