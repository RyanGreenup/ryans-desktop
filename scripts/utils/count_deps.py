#!/usr/bin/env python3
"""Count the number of dependencies per package from the package lists."""

import subprocess
import sys
from pathlib import Path

def get_packages(packages_dir: Path) -> list[str]:
    packages = []
    for f in sorted(packages_dir.glob("*.txt")):
        for line in f.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                packages.append(line)
    return packages

def count_deps(pkg: str) -> int | None:
    try:
        result = subprocess.run(
            ["dnf5", "repoquery", "--requires", pkg],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            return None
        deps = [l for l in result.stdout.strip().splitlines()
                if l.strip() and not l.startswith(("Updating", "Repositories"))]
        return len(deps) if deps else None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None

def main():
    packages_dir = Path(__file__).resolve().parent.parent / "build_files" / "packages"
    if not packages_dir.exists():
        print(f"Package directory not found: {packages_dir}", file=sys.stderr)
        sys.exit(1)

    packages = get_packages(packages_dir)
    results = []

    for pkg in packages:
        count = count_deps(pkg)
        if count is not None:
            results.append((pkg, count))
        else:
            results.append((pkg, -1))

    results.sort(key=lambda x: x[1], reverse=True)

    total = 0
    print(f"{'Package':<40} {'Deps':>6}")
    print("-" * 47)
    for pkg, count in results:
        label = "N/A" if count < 0 else str(count)
        print(f"{pkg:<40} {label:>6}")
        if count > 0:
            total += count

    print("-" * 47)
    print(f"{'Total packages':<40} {len(results):>6}")
    print(f"{'Total dependencies':<40} {total:>6}")

if __name__ == "__main__":
    main()
