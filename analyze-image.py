#!/usr/bin/env python3
"""Analyze space consumption in the container image built by `just build`.

Usage:
    just build                     # build the image first
    python3 analyze-image.py       # uses default image name
    python3 analyze-image.py myimage:latest
"""

import json
import subprocess
import sys
import shutil
from dataclasses import dataclass, field
from pathlib import PurePosixPath


# ── helpers ──────────────────────────────────────────────────────────────────

def run(*cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, check=True, **kw)


def human(n: int) -> str:
    for unit in ("B", "KiB", "MiB", "GiB"):
        if abs(n) < 1024:
            return f"{n:6.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TiB"


def bar(fraction: float, width: int = 30) -> str:
    filled = int(fraction * width)
    return "█" * filled + "░" * (width - filled)


# ── layer analysis ───────────────────────────────────────────────────────────

@dataclass
class Layer:
    idx: int
    digest: str
    size: int
    created_by: str


def get_layers(image: str) -> list[Layer]:
    """Return layer info from podman inspect + history."""
    info = json.loads(run("podman", "inspect", image).stdout)
    history = json.loads(run("podman", "history", "--format", "json", image).stdout)

    layers = []
    for i, entry in enumerate(reversed(history)):
        size = entry.get("size", 0) or 0
        created_by = entry.get("createdBy", entry.get("comment", ""))
        digest = entry.get("id", "")[:12]
        layers.append(Layer(idx=i, digest=digest, size=size, created_by=created_by))

    return layers


# ── filesystem analysis (runs inside the container) ──────────────────────────

ANALYZE_SCRIPT = r"""
import json, os, sys
from collections import defaultdict

# Top-level directory sizes
top = defaultdict(int)
for entry in os.scandir("/"):
    if entry.is_symlink():
        continue
    if entry.is_file():
        top[entry.path] += entry.stat().st_size
    elif entry.is_dir():
        for dirpath, dirnames, filenames in os.walk(entry.path, followlinks=False):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                try:
                    top[entry.path] += os.lstat(fp).st_size
                except OSError:
                    pass

# Drill into /usr (where most content lives)
usr = defaultdict(int)
if os.path.isdir("/usr"):
    for entry in os.scandir("/usr"):
        base = f"/usr/{entry.name}"
        if entry.is_symlink():
            continue
        if entry.is_file():
            usr[base] += entry.stat().st_size
        elif entry.is_dir():
            for dirpath, dirnames, filenames in os.walk(base, followlinks=False):
                for f in filenames:
                    fp = os.path.join(dirpath, f)
                    try:
                        usr[base] += os.lstat(fp).st_size
                    except OSError:
                        pass

# Largest individual files
big_files = []
for dirpath, dirnames, filenames in os.walk("/", followlinks=False):
    for f in filenames:
        fp = os.path.join(dirpath, f)
        try:
            sz = os.lstat(fp).st_size
            if sz > 5_000_000:  # >5 MB
                big_files.append((sz, fp))
        except OSError:
            pass
big_files.sort(reverse=True)

# RPM package sizes
rpm_packages = []
try:
    import subprocess
    out = subprocess.run(
        ["rpm", "-qa", "--queryformat", "%{NAME}\t%{SIZE}\n"],
        capture_output=True, text=True
    )
    if out.returncode == 0:
        for line in out.stdout.strip().splitlines():
            parts = line.split("\t", 1)
            if len(parts) == 2:
                rpm_packages.append((parts[0], int(parts[1])))
        rpm_packages.sort(key=lambda x: -x[1])
except Exception:
    pass

print(json.dumps({
    "top": dict(top),
    "usr": dict(usr),
    "big_files": big_files[:50],
    "rpm_packages": rpm_packages[:80],
}))
"""


def analyze_filesystem(image: str) -> dict:
    """Run a Python script inside the container to gather filesystem stats."""
    result = run(
        "podman", "run", "--rm", "--entrypoint", "python3",
        image, "-c", ANALYZE_SCRIPT,
    )
    return json.loads(result.stdout)


# ── report ───────────────────────────────────────────────────────────────────

SEP = "─" * 78


def print_section(title: str):
    print(f"\n{SEP}\n  {title}\n{SEP}")


def print_table(rows: list[tuple[int, str]], total: int | None = None):
    if total is None:
        total = sum(s for s, _ in rows) or 1
    for size, label in rows:
        frac = size / total if total else 0
        print(f"  {human(size)}  {bar(frac)}  {label}")


def main():
    image = sys.argv[1] if len(sys.argv) > 1 else "ryans-desktop:latest"

    # Check image exists
    try:
        run("podman", "image", "exists", image)
    except subprocess.CalledProcessError:
        print(f"Error: image '{image}' not found. Run `just build` first.")
        sys.exit(1)

    # Total image size
    inspect = json.loads(run("podman", "inspect", image).stdout)
    total_size = inspect[0].get("Size", 0)
    virtual_size = inspect[0].get("VirtualSize", total_size)

    width = shutil.get_terminal_size((80, 24)).columns
    print(f"\n{'═' * width}")
    print(f"  Image Space Analysis: {image}")
    print(f"  Virtual size: {human(virtual_size)}   Image size: {human(total_size)}")
    print(f"{'═' * width}")

    # ── Layers ───────────────────────────────────────────────────────────────
    print_section("LAYERS (build steps)")
    layers = get_layers(image)
    total_layer = sum(l.size for l in layers) or 1

    for l in layers:
        cmd = l.created_by
        # Shorten the created_by for display
        if "/ctx/scripts/build/" in cmd:
            cmd = cmd.split("/ctx/scripts/build/")[-1].split(" ")[0]
        elif len(cmd) > 60:
            cmd = cmd[:57] + "..."
        frac = l.size / total_layer if total_layer else 0
        print(f"  {l.idx:2d}  {human(l.size)}  {bar(frac)}  {cmd}")

    # ── Filesystem ───────────────────────────────────────────────────────────
    print("\n  Analyzing filesystem (running container)...", flush=True)
    fs = analyze_filesystem(image)

    # Top-level directories
    print_section("TOP-LEVEL DIRECTORIES")
    top_rows = sorted(
        [(s, p) for p, s in fs["top"].items()],
        reverse=True,
    )
    fs_total = sum(s for s, _ in top_rows)
    print_table(top_rows[:15], fs_total)
    print(f"\n  Total filesystem: {human(fs_total)}")

    # /usr breakdown
    print_section("/usr BREAKDOWN")
    usr_rows = sorted(
        [(s, p) for p, s in fs["usr"].items()],
        reverse=True,
    )
    usr_total = sum(s for s, _ in usr_rows)
    print_table(usr_rows[:20], usr_total)

    # RPM packages
    if fs["rpm_packages"]:
        print_section("TOP RPM PACKAGES BY INSTALLED SIZE")
        rpm_total = sum(s for _, s in fs["rpm_packages"])
        rpm_rows = [(s, name) for name, s in fs["rpm_packages"][:30]]
        print_table(rpm_rows, rpm_total)
        print(f"\n  Total RPM installed size: {human(rpm_total)}")

    # Big files
    if fs["big_files"]:
        print_section("LARGEST FILES (>5 MiB)")
        for size, path in fs["big_files"][:25]:
            print(f"  {human(size)}  {path}")

    print(f"\n{'═' * width}\n")


if __name__ == "__main__":
    main()
