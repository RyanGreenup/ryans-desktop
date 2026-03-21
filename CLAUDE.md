# Project: ryans-desktop (ublue-os custom image)

A bootc/ostree custom desktop image built on top of Universal Blue's Cosmic Atomic (NVIDIA variant).

## Architecture

This is an immutable Fedora Atomic Desktop image. The `Containerfile` builds a full OS image using multi-stage builds:

1. **Parallel download stages** (`rust-tools`, `github-releases`, `standalone`, `go-tools`) — fetch binaries independently for cache efficiency
2. **Sequential build** — DNF packages, custom RPMs, COPR repos, RStudio, then merge binaries from parallel stages
3. **Services & config** — systemd units, firewall rules, bootc lint

The built image is deployed to the host via `bootc switch` or published to GHCR for remote updates.

## Key directories

- `packages/*.txt` — DNF package lists (one package per line, `#` comments). All `.txt` files are installed by `scripts/build/00-packages.sh`
- `scripts/build/` — Numbered build scripts executed by Containerfile stages
- `rpms/` — Local RPM files installed by `03-rpms.sh`
- `config/` — Boot config, certs, flatpak lists
- `systemd/` — First-boot service units (flatpaks, snapper, etc.)
- `disk_config/` — BIB (bootc-image-builder) disk layout configs
- `build_files/toolboxes/` — Separate toolbox container (fedora-toolbox base)

## Common tasks

### Adding a package
Add the package name to the appropriate `packages/*.txt` file. The build script reads all `.txt` files and installs everything via `dnf5 install`.

### Adding a build script
Create a numbered script in `scripts/build/`, then add a corresponding `RUN` stage in the `Containerfile`. Follow the existing pattern of bind-mounting from context stages.

### Justfile commands
- `just build` — Build the container image
- `just deploy` — Build and switch the live system
- `just deploy-fresh` — Pull latest base, no-cache build, switch
- `just switch` / `just switch-remote` — Switch to local or GHCR image
- `just create-toolbox <name>` — Build image then create a toolbox from it
- `just build-toolbox` — Build the separate fedora-toolbox-based toolbox
- `just build-qcow2` / `just build-raw` / `just build-iso` — VM images via BIB
- `just run-vm-*` / `just spawn-vm` — Run VM images
- `just watch-build` — Watch latest GitHub Actions run
- `just lint` / `just format` — shellcheck and shfmt on `.sh` files

## Build details

- Base image: `ghcr.io/ublue-os/cosmic-atomic-nvidia:latest`
- Package manager: `dnf5` (Fedora 43+)
- Container runtime: `podman` (rootless by default, rootful for BIB/switch)
- The Containerfile uses `--mount=type=cache,dst=/var/cache` for DNF cache persistence across builds
- Context is split into named stages (`ctx-packages`, `ctx-scripts`, etc.) so changes to one directory don't invalidate unrelated layers

## Conventions

- Package lists use one package per line, comments start with `#`, blank lines are ignored
- Build scripts use `set -ouex pipefail` (strict mode with trace)
- Justfile recipes use `[group()]` annotations for organization
- First-boot setup (flatpaks, snapper, go tools) happens via systemd oneshot services, not in the image build
