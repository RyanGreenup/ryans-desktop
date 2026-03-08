# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY packages /packages
COPY rpms /rpms
COPY scripts /scripts
COPY systemd /systemd
COPY config /config

# Base Image
FROM ghcr.io/ublue-os/cosmic-atomic-main:latest

# DNF packages from lists (stable, slow)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/00-packages.sh

# NVIDIA CUDA toolkit
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/01-nvidia-cuda.sh

# NVIDIA Container Toolkit
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/02-nvidia-container.sh

# Custom RPMs
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/03-rpms.sh

# COPR packages
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/04-copr.sh

# Rust tools (cargo binstall)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/build/05-rust-tools.sh

# GitHub release binaries
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/build/06-github-releases.sh

# Standalone tools (bun, duckdb, clickhouse)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/build/07-standalone.sh

# RStudio
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/build/08-rstudio.sh

# First-boot services + systemctl enables (changes most often)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/run \
    /ctx/scripts/build/09-services.sh

# Ensure /var/run is a symlink to /run (required by bootc)
RUN rm -rf /var/run && \
    ln -s /run /var/run

# Verify final image and contents are correct.
RUN bootc container lint
