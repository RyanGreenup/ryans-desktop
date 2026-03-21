#!/usr/bin/env python3
import os
import subprocess
import sys

VERBOSE = False
SESSION = "devops/sys/ublue-declaration"


def log(msg):
    if VERBOSE:
        print(f"[attach] {msg}")


def run(cmd, check=True, capture=True):
    log(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=capture, text=True)
    if VERBOSE and capture:
        if result.stdout.strip():
            print(result.stdout.strip())
        if result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)
    if check and result.returncode != 0:
        log(f"Command failed with exit code {result.returncode}")
        sys.exit(1)
    return result


def session_exists():
    result = subprocess.run(
        ["tmux", "has-session", "-t", SESSION],
        capture_output=True, text=True,
    )
    return result.returncode == 0


def main():
    log(f"SESSION={SESSION}")
    log(f"TMUX={os.environ.get('TMUX', '(unset)')}")
    log(f"TERM={os.environ.get('TERM', '(unset)')}")

    try:
        tty = os.ttyname(sys.stdin.fileno())
    except OSError:
        tty = "(not a tty)"
    log(f"TTY={tty}")
    log(f"PID={os.getpid()}")

    if session_exists():
        log(f"Session '{SESSION}' already exists")
        run(["tmux", "list-sessions"])
    else:
        log(f"Session '{SESSION}' not found, creating...")
        run(["tmux", "new-session", "-d", "-s", SESSION])
        log("Session created successfully")
        run(["tmux", "list-sessions"])

    if os.environ.get("TMUX"):
        log("Already inside tmux, using switch-client...")
        os.execvp("tmux", ["tmux", "switch-client", "-t", SESSION])
    else:
        log("Not inside tmux, using attach-session...")
        os.execvp("tmux", ["tmux", "attach-session", "-t", SESSION])


if __name__ == "__main__":
    main()
