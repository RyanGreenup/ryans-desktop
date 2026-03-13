# ── Per-directory context stages ─────────────────────────────────────────────
# Split so changes to one directory don't invalidate layers that use another.
FROM scratch AS ctx-packages
COPY packages /packages

FROM scratch AS ctx-rpms
COPY rpms /rpms

FROM scratch AS ctx-scripts
COPY scripts /scripts

FROM scratch AS ctx-systemd
COPY systemd /systemd

FROM scratch AS ctx-config
COPY config /config

# ── Base Image ───────────────────────────────────────────────────────────────
# FROM ghcr.io/ublue-os/cosmic-atomic-main:latest
FROM ghcr.io/ublue-os/cosmic-atomic-nvidia:latest AS base

# ── Independent download stages (parallel, cache-independent) ────────────────
# These scripts only download binaries — no /ctx/ data, no DNF.
# Built as separate stages so they don't bust (or get busted by) the main build.

FROM base AS rust-tools
RUN --mount=type=bind,from=ctx-scripts,source=/scripts/build/05-rust-tools.sh,target=/run/build.sh \
    --mount=type=tmpfs,dst=/tmp \
    /run/build.sh

FROM base AS github-releases
RUN --mount=type=bind,from=ctx-scripts,source=/scripts/build/06-github-releases.sh,target=/run/build.sh \
    --mount=type=tmpfs,dst=/tmp \
    /run/build.sh

FROM base AS standalone
RUN --mount=type=bind,from=ctx-scripts,source=/scripts/build/07-standalone.sh,target=/run/build.sh \
    --mount=type=tmpfs,dst=/tmp \
    /run/build.sh

# ── Main sequential build ────────────────────────────────────────────────────
FROM base

# DNF packages from lists
RUN --mount=type=bind,from=ctx-packages,source=/packages,target=/ctx/packages \
    --mount=type=bind,from=ctx-scripts,source=/scripts/build/00-packages.sh,target=/ctx/scripts/build/00-packages.sh \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/00-packages.sh

# NVIDIA CUDA toolkit — removed; use containerized CUDA instead:
#   podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.6.3-runtime-ubuntu24.04 ...

# NVIDIA Container Toolkit — already in base image (cosmic-atomic-nvidia)

# Custom RPMs
RUN --mount=type=bind,from=ctx-rpms,source=/rpms,target=/ctx/rpms \
    --mount=type=bind,from=ctx-scripts,source=/scripts/build/03-rpms.sh,target=/ctx/scripts/build/03-rpms.sh \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/03-rpms.sh

# COPR packages
RUN --mount=type=bind,from=ctx-scripts,source=/scripts/build/04-copr.sh,target=/ctx/scripts/build/04-copr.sh \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/04-copr.sh

# RStudio
RUN --mount=type=bind,from=ctx-scripts,source=/scripts/build/08-rstudio.sh,target=/ctx/scripts/build/08-rstudio.sh \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/build/08-rstudio.sh

# ── Merge self-contained binaries (cache-independent via --link) ─────────────
COPY --from=rust-tools /usr/bin/ouch /usr/bin/nu /usr/bin/typst /usr/bin/
COPY --from=github-releases /usr/bin/btdu /usr/bin/sops /usr/bin/kompose /usr/bin/s5cmd /usr/bin/
COPY --from=standalone /usr/bin/bun /usr/bin/bunx /usr/bin/duckdb /usr/bin/clickhouse /usr/bin/

# First-boot services + systemctl enables (changes most often)
RUN --mount=type=bind,from=ctx-scripts,source=/scripts,target=/ctx/scripts \
    --mount=type=bind,from=ctx-systemd,source=/systemd,target=/ctx/systemd \
    --mount=type=bind,from=ctx-config,source=/config,target=/ctx/config \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/09-services.sh

# Ensure /var/run is a symlink to /run (required by bootc)
RUN rm -rf /var/run && \
    ln -s /run /var/run

# Verify final image and contents are correct.
RUN bootc container lint
