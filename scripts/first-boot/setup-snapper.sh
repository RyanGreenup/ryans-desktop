#!/bin/bash
set -ouex pipefail

SENTINEL=/var/lib/snapper-first-boot-done

if [[ -f "$SENTINEL" ]]; then
    echo "snapper already configured, skipping."
    exit 0
fi

# Resolve the root filesystem UUID
UUID=$(findmnt -n -o UUID /)

if [[ -z "$UUID" ]]; then
    echo "ERROR: Could not determine root filesystem UUID" >&2
    exit 1
fi

echo "Configuring snapper for root filesystem UUID: $UUID"

# Create the root snapper config
snapper -c root create-config /

# Enable snapper timers
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# Mark first-boot setup as complete
touch "$SENTINEL"
echo "snapper setup complete."
