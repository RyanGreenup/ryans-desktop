#!/usr/bin/env bash
# Install Flatpak apps from list on first boot
set -euo pipefail

STAMP="/var/lib/flatpak-first-boot-done"
LIST="/usr/share/ublue-os/flatpaks.txt"
REMOVE_LIST="/usr/share/ublue-os/flatpaks-remove.txt"
REMOVE_UNWANTED=false

if [[ -f "$STAMP" ]]; then
    echo "Flatpaks already installed, skipping."
    exit 0
fi

if [[ ! -f "$LIST" ]]; then
    echo "No flatpak list found at $LIST"
    exit 1
fi

# Ensure flathub remote exists
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

# Install each app, skipping blank lines and comments
while IFS= read -r app; do
    [[ -z "$app" || "$app" == \#* ]] && continue
    echo "Installing $app..."
    flatpak install --system --noninteractive flathub "$app" || echo "Failed to install $app, continuing..."
done < "$LIST"

# Remove unwanted Flatpaks that may ship with the base image
if [[ "$REMOVE_UNWANTED" == true && -f "$REMOVE_LIST" ]]; then
    while IFS= read -r app; do
        [[ -z "$app" || "$app" == \#* ]] && continue
        echo "Removing $app..."
        flatpak uninstall --system --noninteractive "$app" || echo "Failed to remove $app, continuing..."
    done < "$REMOVE_LIST"
fi

touch "$STAMP"
echo "Flatpak first-boot install complete."
