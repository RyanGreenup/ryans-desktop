#!/bin/bash
set -ouex pipefail

export CARGO_HOME=/tmp/cargo RUSTUP_HOME=/tmp/rustup
rustup-init -y --profile minimal
source "$CARGO_HOME/env"
cargo install cargo-binstall
cargo binstall -y --force ouch nu typst-cli
install -Dm755 "$CARGO_HOME/bin/ouch" /usr/bin/ouch
install -Dm755 "$CARGO_HOME/bin/nu" /usr/bin/nu
install -Dm755 "$CARGO_HOME/bin/typst" /usr/bin/typst
rm -rf "$CARGO_HOME" "$RUSTUP_HOME"
