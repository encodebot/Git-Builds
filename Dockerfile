FROM debian:trixie-slim AS builder

# Enforce strict error handling. Instantly aborts on any hidden failure.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend for apt to prevent hanging prompts
ENV DEBIAN_FRONTEND=noninteractive
# Accept Git version as a dynamic build argument
ARG GIT_VERSION
# Install prerequisites required for Git compilation
# Git requires specific libraries like OpenSSL, Curl, and Expat to function properly.
# Also install 'file' to safely identify binaries for stripping.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    xz-utils \
    ca-certificates \
    zlib1g-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libexpat1-dev \
    gettext \
    file \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Git source safely with CI-friendly wget progress
RUN wget --progress=dot:giga "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" -O git_src.tar.gz && \
    tar -xzf git_src.tar.gz

WORKDIR /git-${GIT_VERSION}

# Compile with multi-core support directly passed to make.
# NO_TCLTK=1 disables the GUI tools.
# NO_INSTALL_HARDLINKS=1 prevents Docker extraction bloat by using symlinks
RUN make -j"$(nproc)" prefix=/git-build NO_TCLTK=1 NO_INSTALL_HARDLINKS=1 all && \
    make prefix=/git-build NO_TCLTK=1 NO_INSTALL_HARDLINKS=1 install

# Strip debugging symbols to shrink the final size.
# Because Git contains shell scripts in its libexec folder, I use 'file' to ensure 
# ONLY run 'strip' on actual ELF compiled binaries, preventing corruption.
RUN find /git-build -type f -exec sh -c 'file "{}" | grep -q "ELF" && strip --strip-all "{}" || true' \;

# Use a scratch image to export the ENTIRE compiled directory structure back to the host
FROM scratch AS export-stage
COPY --from=builder /git-build /