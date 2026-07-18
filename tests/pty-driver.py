"""Drive an interactive Python REPL under a PTY for testing."""

from __future__ import annotations

import os
import pty
import select
import sys


def _read_until(fd: int, marker: bytes, timeout: float = 10.0) -> bytes:
    buf = b""
    while True:
        r, _, _ = select.select([fd], [], [], timeout)
        if not r:
            raise TimeoutError(f"timed out waiting for {marker!r}; captured: {buf!r}")
        try:
            chunk = os.read(fd, 4096)
            if not chunk:
                break
            buf += chunk
            if marker in buf:
                break
        except OSError:
            break
    return buf


def main() -> None:
    argv = sys.argv[1:]
    if not argv:
        sys.exit("usage: pty-driver.py COMMAND [ARGS...]")

    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(argv[0], argv)

    _read_until(fd, b">>>")
    os.write(fd, b"exit()\n")

    while True:
        r, _, _ = select.select([fd], [], [], 3)
        if not r:
            break
        try:
            if not os.read(fd, 4096):
                break
        except OSError:
            break

    _, status = os.waitpid(pid, 0)
    sys.exit(os.waitstatus_to_exitcode(status))


if __name__ == "__main__":
    main()
