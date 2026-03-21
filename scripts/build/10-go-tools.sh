#!/bin/bash
set -ouex pipefail

dnf5 install -y golang
dnf5 clean all

export GOPATH=/tmp/go
export GOCACHE=/tmp/go-cache
export GOBIN=/usr/bin

### d2 — declarative diagramming language
go install oss.terrastruct.com/d2@latest

# Clean up Go toolchain and build cache
dnf5 remove -y golang
dnf5 clean all
rm -rf "$GOPATH"
