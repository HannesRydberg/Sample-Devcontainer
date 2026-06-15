# .devcontainer/Dockerfile
# Ubuntu 24.04 — supports arm64 (Apple Silicon) and amd64.
# Universal image has no arm64 build; runtimes are installed via devcontainer features instead.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# ── .NET 8 SDK (for legacy projects) ──────────────────────────────────────
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && bash /tmp/dotnet-install.sh --version 8.0.403 --install-dir /usr/share/dotnet \
    && rm /tmp/dotnet-install.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xclip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Agent tooling ────────────────────────────────────────────────────────────
# Fast CLI utilities used by AI coding agents and dev workflows.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ripgrep \
        fd-find \
        bat \
        jq \
        tree \
    && ln -s "$(which fdfind)" /usr/local/bin/fd \
    && ln -s "$(which batcat)" /usr/local/bin/bat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
