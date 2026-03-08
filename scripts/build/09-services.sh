#!/bin/bash
set -ouex pipefail

### First-boot services
install -Dm755 /ctx/scripts/first-boot/install-flatpaks.sh /usr/libexec/install-flatpaks.sh
install -Dm644 /ctx/config/flatpaks.txt /usr/share/ublue-os/flatpaks.txt
install -Dm644 /ctx/config/flatpaks-remove.txt /usr/share/ublue-os/flatpaks-remove.txt
install -Dm644 /ctx/systemd/flatpak-first-boot.service /usr/lib/systemd/system/flatpak-first-boot.service
systemctl enable flatpak-first-boot.service

install -Dm755 /ctx/scripts/first-boot/install-electron.sh /usr/libexec/install-electron.sh
install -Dm644 /ctx/systemd/electron-first-boot.service /usr/lib/systemd/system/electron-first-boot.service
systemctl enable electron-first-boot.service

install -Dm755 /ctx/scripts/first-boot/install-go-tools.sh /usr/libexec/install-go-tools.sh
install -Dm644 /ctx/systemd/go-tools-first-boot.service /usr/lib/systemd/system/go-tools-first-boot.service
systemctl enable go-tools-first-boot.service

### Enable system services
systemctl enable podman.socket
systemctl enable systemd-oomd
