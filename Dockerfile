FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG GHC_VERSION=9.2.7
ARG CABAL_VERSION=3.10.3.0
ARG STACK_VERSION=2.13.1
# HLS 1.10.0.0 ships a binary built specifically for GHC 9.2.7.
ARG HLS_VERSION=1.10.0.0

USER root

# Libraries and utilities required by GHCup's Linux bindists and by common
# Haskell packages that compile C sources.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libffi-dev \
        libgmp-dev \
        libncurses-dev \
        libnuma-dev \
        libtinfo5 \
        pkg-config \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Keep the large, versioned toolchain outside the remote user's home
# directory. Dev Containers may recursively change ownership of /home/vscode
# to match the host UID; keeping GHCup here avoids copying its multi-GB files
# into that generated image layer.
RUN install -d -o vscode -g vscode /opt/ghcup

USER vscode

ENV GHCUP_INSTALL_BASE_PREFIX=/opt/ghcup \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_MINIMAL=1 \
    PATH=/opt/ghcup/.ghcup/bin:/home/vscode/.cabal/bin:${PATH} \
    GHCUP_SKIP_UPDATE_CHECK=1

# Bootstrap only GHCup, then install the development executables explicitly.
# This avoids retaining the bootstrap script's default toolchain alongside the
# versions pinned below. The project resolver remains the source of truth for
# the compiler used by Stack.
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org \
        | sh \
    && ghcup install ghc ${GHC_VERSION} \
    && ghcup set ghc ${GHC_VERSION} \
    && ghcup install cabal ${CABAL_VERSION} \
    && ghcup set cabal ${CABAL_VERSION} \
    && ghcup install stack ${STACK_VERSION} \
    && ghcup set stack ${STACK_VERSION} \
    && ghcup install hls ${HLS_VERSION} \
    && ghcup set hls ${HLS_VERSION}

# Do not download a second compiler: Stack uses the GHC installed above, whose
# version is the one selected by lts-20.18.
RUN mkdir -p /home/vscode/.stack \
    && printf '%s\n' 'system-ghc: true' 'install-ghc: false' \
        > /home/vscode/.stack/config.yaml
