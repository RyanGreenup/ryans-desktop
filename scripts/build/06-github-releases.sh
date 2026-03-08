#!/bin/bash
set -ouex pipefail

### btdu
BTDU_URL=$(curl -s https://api.github.com/repos/CyberShadow/btdu/releases/latest \
    | grep -o 'https://[^"]*btdu-static-x86_64' | head -1)
curl -fsSL "$BTDU_URL" -o /tmp/btdu
install -Dm755 /tmp/btdu /usr/bin/btdu

### sops
SOPS_URL=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest \
    | grep -o 'https://[^"]*sops-v[^"]*linux\.amd64"' | head -1 | tr -d '"')
curl -fsSL "$SOPS_URL" -o /tmp/sops
install -Dm755 /tmp/sops /usr/bin/sops

### kompose
KOMPOSE_URL=$(curl -s https://api.github.com/repos/kubernetes/kompose/releases/latest \
    | grep -o 'https://[^"]*kompose-linux-amd64"' | head -1 | tr -d '"')
curl -fsSL "$KOMPOSE_URL" -o /tmp/kompose
install -Dm755 /tmp/kompose /usr/bin/kompose

### s5cmd
S5CMD_URL=$(curl -s https://api.github.com/repos/peak/s5cmd/releases/latest \
    | grep -o 'https://[^"]*s5cmd_[^"]*_Linux-64bit\.tar\.gz"' | head -1 | tr -d '"')
curl -fsSL "$S5CMD_URL" | tar -xz -C /tmp s5cmd
install -Dm755 /tmp/s5cmd /usr/bin/s5cmd
