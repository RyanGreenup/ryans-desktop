#!/usr/bin/env python3
"""Check which packages from a package list are available via dnf."""

import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
PACKAGE_FILE = SCRIPT_DIR / "00_packages.txt"
FOUND_FILE = SCRIPT_DIR / "found_packages.txt"
MISSING_FILE = SCRIPT_DIR / "missing_packages.txt"
NCPU = os.cpu_count() or 4


def check_package(pkg: str) -> tuple[str, bool]:
    result = subprocess.run(
        ["dnf", "install", "--downloadonly", "-y", pkg],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    status = "  found" if result.returncode == 0 else "MISSING"
    print(f"{status}: {pkg}")
    return (pkg, result.returncode == 0)


def main():
    pkg_file = Path(sys.argv[1]) if len(sys.argv) > 1 else PACKAGE_FILE
    packages = [
        line.strip()
        for line in pkg_file.read_text().splitlines()
        if line.strip()
    ]

    print(f"Checking {len(packages)} packages with {NCPU} workers...\n")

    with ThreadPoolExecutor(max_workers=NCPU) as pool:
        results = list(pool.map(check_package, packages))

    found = [pkg for pkg, ok in results if ok]
    missing = [pkg for pkg, ok in results if not ok]

    FOUND_FILE.write_text("\n".join(found) + "\n")
    MISSING_FILE.write_text("\n".join(missing) + "\n")

    print(f"\n{len(found)} found, {len(missing)} missing")
    print(f"Results written to:\n  {FOUND_FILE}\n  {MISSING_FILE}")


if __name__ == "__main__":
    main()
