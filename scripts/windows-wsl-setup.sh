#!/usr/bin/env bash
# windows-wsl-setup.sh
#
# Run this script inside a WSL 2 Ubuntu terminal to install all prerequisites
# needed before using this devcontainer on Windows.
#
# Prerequisites (do these first, before running this script):
#   1. In PowerShell (as administrator): wsl --install
#   2. Restart your machine and open an Ubuntu WSL terminal.
#   3. Run: bash scripts/windows-wsl-setup.sh
#
set -euo pipefail

echo "==> Installing Docker CE"
sudo apt update
sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

echo "==> Installing Node.js via nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash

# Load nvm in this shell session without restarting
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
\. "$NVM_DIR/nvm.sh"

nvm install 24
corepack enable pnpm

echo "==> Installing wslu (WSL utilities)"
sudo apt install -y wslu

echo ""
echo "All prerequisites installed."
echo "Node $(node -v), pnpm $(pnpm -v), Docker $(docker --version)"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to ~/.config/dev/dev.env and add your GitHub PAT."
echo "  2. Install the Dev Containers CLI: npm install -g @devcontainers/cli"
echo "  3. Load the aliases from aliases.md."
echo "  4. Run: dev-up"
