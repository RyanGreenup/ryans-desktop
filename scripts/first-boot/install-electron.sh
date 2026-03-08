#!/usr/bin/env bash
# Install electron globally via bun for claude-desktop
set -euo pipefail

STAMP="/var/lib/electron-first-boot-done"

if [[ -f "$STAMP" ]]; then
    echo "Electron already installed, skipping."
    exit 0
fi

bun install -g electron

touch "$STAMP"
echo "Electron install complete."
