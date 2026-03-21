#!/bin/bash
set -ouex pipefail

export CARGO_HOME=/tmp/cargo RUSTUP_HOME=/tmp/rustup
curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
source "$CARGO_HOME/env"
curl -fsSL https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-x86_64-unknown-linux-musl.tgz \
    | tar -xz -C "$CARGO_HOME/bin"
cargo binstall -y --force ouch nu typst-cli mise usage-cli
install -Dm755 "$CARGO_HOME/bin/ouch" /usr/bin/ouch
install -Dm755 "$CARGO_HOME/bin/nu" /usr/bin/nu
install -Dm755 "$CARGO_HOME/bin/typst" /usr/bin/typst
install -Dm755 "$CARGO_HOME/bin/mise" /usr/bin/mise
install -Dm755 "$CARGO_HOME/bin/usage" /usr/bin/usage
rm -rf "$CARGO_HOME" "$RUSTUP_HOME"
