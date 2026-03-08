#!/bin/bash
set -ouex pipefail

DNF_OPTS="--setopt=max_parallel_downloads=20"

curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
    | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf5 install -y $DNF_OPTS nvidia-container-toolkit
