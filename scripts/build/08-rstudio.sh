#!/bin/bash
set -ouex pipefail

DNF_OPTS="--setopt=max_parallel_downloads=20"

RSTUDIO_URL=$(curl -s https://dailies.rstudio.com/rstudio/latest/index.json \
    | grep -o 'https://[^"]*electron/rhel9/x86_64/rstudio-[0-9][^"]*x86_64\.rpm' | head -1)
curl -fsSL "$RSTUDIO_URL" -o /tmp/rstudio.rpm
dnf5 install -y $DNF_OPTS /tmp/rstudio.rpm
