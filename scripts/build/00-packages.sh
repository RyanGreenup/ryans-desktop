#!/bin/bash
set -ouex pipefail

DNF_OPTS="--setopt=max_parallel_downloads=20"

PACKAGES=""
for list in /ctx/packages/*.txt; do
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        PACKAGES="$PACKAGES $pkg"
    done < "$list"
done
if [[ -n "$PACKAGES" ]]; then
    dnf5 install -y $DNF_OPTS $PACKAGES
fi
