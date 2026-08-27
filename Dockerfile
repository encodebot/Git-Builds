FROM debian:trixie-slim AS builder

# Enforce Strict Error Handling. Instantly Aborts On Any Hidden Failure.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set Non-Interactive Frontend For Apt To Prevent Hanging Prompts.
ENV DEBIAN_FRONTEND=noninteractive
# Accept Git Version As A Dynamic Build Argument.
ARG GIT_VERSION
# Git Requires Specific Libraries Like OpenSSL, Curl & Expat To Function Properly.
# Also Install 'file' To Safely Identify Binaries For Stripping.
# 1. Install Prerequisites Required For Git Compilation.
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cargo \
    curl \
    file \
    gettext \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libssl-dev \
    rustc \
    wget \
    xz-utils \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Download & Extract Git Source Safely With CI-Friendly wget Progress.
RUN wget -q --show-progress --https-only --retry-connrefused --waitretry=5 --tries=5 --progress=dot:giga "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" -O git_src.tar.gz && \
    tar -xzf git_src.tar.gz && \
    rm -rf git_src.tar.gz

WORKDIR /git-${GIT_VERSION}

# NO_TCLTK=1 Disables The GUI Tools.
# NO_INSTALL_HARDLINKS=1 Prevents Docker Extraction Bloat By Using Symlinks.
# 3. Compile With Multi-Core Support Directly Passed To Make.
RUN make -j"$(nproc)" prefix=/git-build NO_TCLTK=1 NO_INSTALL_HARDLINKS=1 all && \
    make prefix=/git-build NO_TCLTK=1 NO_INSTALL_HARDLINKS=1 install

# Because Git Contains Shell Scripts In Its libexec Folder, I Use 'file' To Ensure 
# ONLY Run 'strip' On Actual ELF Compiled Binaries, Preventing Corruption.
# 4. Strip Debugging Symbols From The Actual Binaries To Shrink The Final Size.
RUN find /git-build -type f -exec sh -c 'file "{}" | grep -q "ELF" && strip --strip-all "{}" || true' \;

# 5. Use A Scratch Image To Export The ENTIRE Compiled Directory Structure Back To The Host.
FROM scratch AS export-stage
COPY --from=builder /git-build /
