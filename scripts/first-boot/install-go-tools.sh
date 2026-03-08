#!/usr/bin/env bash
# Install Go tools to user's home directory on first boot
set -euo pipefail

STAMP="/var/lib/go-tools-first-boot-done"
GOBIN="/var/home/${SUDO_USER:-$USER}/.local/bin"

if [[ -f "$STAMP" ]]; then
    echo "Go tools already installed, skipping."
    exit 0
fi

export GOBIN
mkdir -p "$GOBIN"

go install github.com/rakyll/hey@latest

touch "$STAMP"
echo "Go tools install complete."
