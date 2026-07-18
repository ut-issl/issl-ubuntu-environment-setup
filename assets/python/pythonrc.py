"""Shared interactive Python startup for ISSL environment."""

from __future__ import annotations

import builtins
import os
import sys
from pprint import pprint


def _will_use_pyrepl() -> bool:
    if sys.version_info < (3, 13):
        return False
    if os.environ.get("PYTHON_BASIC_REPL"):
        return False
    if not sys.stdin.isatty():
        return False
    try:
        from _pyrepl.main import CAN_USE_PYREPL  # type: ignore[import-not-found]

        return CAN_USE_PYREPL
    except (ImportError, AttributeError):  # fmt: skip
        return False


def _is_libedit() -> bool:
    try:
        import readline
    except ImportError:
        return False
    if sys.version_info >= (3, 13):
        return getattr(readline, "backend", "") == "editline"
    return "libedit" in getattr(readline, "__doc__", "")


def _history_base_path() -> str:
    path = os.environ.get("PYTHON_HISTORY")
    if path:
        return path
    state_home = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    return os.path.join(state_home, "python", "python_history")


def _history_path() -> str:
    base = _history_base_path()
    if _is_libedit():
        return base + ".editline"
    return base


def _enable_completion() -> None:
    import readline

    if _is_libedit():
        readline.parse_and_bind("bind ^I rl_complete")
    else:
        readline.parse_and_bind("tab: complete")


def _enable_history() -> None:
    import atexit
    import readline

    histfile = _history_path()
    histdir = os.path.dirname(histfile)
    if histdir:
        os.makedirs(histdir, exist_ok=True)

    if os.path.exists(histfile):
        try:
            readline.read_history_file(histfile)
        except Exception:
            return

    readline.set_history_length(10_000)

    def save_history() -> None:
        try:
            readline.write_history_file(histfile)
        except Exception:
            pass

    atexit.register(save_history)


def _redirect_history_for_libedit() -> None:
    path = _history_path()
    histdir = os.path.dirname(path)
    if histdir:
        os.makedirs(histdir, exist_ok=True)
    os.environ["PYTHON_HISTORY"] = path


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


_enable_pretty_display()

if not _will_use_pyrepl():
    _enable_completion()
    _set_colored_prompts()
    if sys.version_info < (3, 13):
        _enable_history()
    elif _is_libedit():
        _redirect_history_for_libedit()
