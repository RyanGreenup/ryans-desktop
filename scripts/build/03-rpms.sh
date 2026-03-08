#!/bin/bash
set -ouex pipefail

DNF_OPTS="--setopt=max_parallel_downloads=20"

dnf5 install -y $DNF_OPTS /ctx/rpms/*.rpm
