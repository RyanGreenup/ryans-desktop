#!/bin/bash
set -ouex pipefail

DNF_OPTS="--setopt=max_parallel_downloads=20"

dnf5 -y copr enable lihaohong/yazi
dnf5 -y $DNF_OPTS install yazi
dnf5 -y copr disable lihaohong/yazi

dnf5 -y copr enable pesader/showmethekey
dnf5 -y $DNF_OPTS install showmethekey
dnf5 -y copr disable pesader/showmethekey
