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

NODE_MAJOR_REQUIRED=24

ensure_wslvar() {
  if command -v wslvar >/dev/null 2>&1; then
    echo "==> wslvar already available, skipping"
    return
  fi

  echo "==> Installing wslu (WSL utilities)"
  sudo apt update
  if sudo apt install -y wslu && command -v wslvar >/dev/null 2>&1; then
    echo "==> wslu installed successfully"
    return
  fi

  echo "==> wslu not available in apt repos; installing local wslvar shim"
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/wslvar" <<'EOF'
#!/usr/bin/env bash
if [ $# -ne 1 ]; then
  echo "usage: wslvar <WINDOWS_ENV_VAR_NAME>" >&2
  exit 2
fi
cmd.exe /c "echo %$1%" | tr -d '\r'
EOF
  chmod +x "$HOME/.local/bin/wslvar"

  if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

install_docker_ce() {
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
}

if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "==> Docker already installed, skipping"
else
  install_docker_ce
fi

export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "==> Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
fi

# Load nvm in this shell session without restarting
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"

installed_node_major=""
if command -v node >/dev/null 2>&1; then
  installed_node_major="$(node -p 'process.versions.node.split(".")[0]')"
fi

if [ -n "$installed_node_major" ] && [ "$installed_node_major" -ge "$NODE_MAJOR_REQUIRED" ]; then
  echo "==> Node.js $(node -v) already satisfies requirement (>= ${NODE_MAJOR_REQUIRED}), skipping"
else
  echo "==> Installing Node.js ${NODE_MAJOR_REQUIRED} via nvm"
  nvm install "$NODE_MAJOR_REQUIRED"
fi

echo "==> Ensuring pnpm via corepack"
corepack enable pnpm

if command -v devcontainer >/dev/null 2>&1; then
  echo "==> Dev Containers CLI already installed ($(devcontainer --version)), skipping"
else
  echo "==> Installing Dev Containers CLI"
  npm install -g @devcontainers/cli
fi

ensure_wslvar

echo ""
echo "Prerequisite check complete."
echo "Node $(node -v), pnpm $(pnpm -v), Docker $(docker --version), Dev Containers CLI $(devcontainer --version)"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to ~/.config/dev/dev.env and add your GitHub PAT."
echo "  2. Run: scripts/doctor.sh"
echo "  3. Load the aliases from aliases.md."
echo "  4. Run: dev-up"
