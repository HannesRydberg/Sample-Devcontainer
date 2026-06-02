# .devcontainer/Dockerfile
# Ubuntu 24.04 — supports arm64 (Apple Silicon) and amd64.
# Universal image has no arm64 build; runtimes are installed via devcontainer features instead.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xclip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
