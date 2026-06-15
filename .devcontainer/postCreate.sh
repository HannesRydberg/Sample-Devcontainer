#!/usr/bin/env bash
# .devcontainer/postCreate.sh
set -euo pipefail

# ── Load secrets ──────────────────────────────────────────────────────────────
# Source the bind-mounted .env for this script and wire it into .bashrc so every
# future terminal session picks it up too. No secret values are ever copied.
if [ -f /run/secrets/dev.env ]; then
    set -a
    # shellcheck source=/dev/null
    source /run/secrets/dev.env
    set +a
fi
grep -q 'dev.env' "$HOME/.bashrc" 2>/dev/null \
    || echo 'if [ -f /run/secrets/dev.env ]; then set -a; source /run/secrets/dev.env; set +a; fi' \
        >> "$HOME/.bashrc"

echo ""
echo "🔧 Running post-create setup..."
echo ""

PACKAGE_ROOT="${NUGET_PACKAGES:-$HOME/.nuget/packages}"

# ── Prepare Copilot ───────────────────────────────────────────────────────────
# ~/.copilot is bind-mounted directly from the host. Shared config and session
# history — avoid running Copilot on host + container simultaneously to prevent
# SQLite lock contention.
echo "✅ Copilot directory ready (bind mount from host)"

# ── Fix volume ownership ──────────────────────────────────────────────────────
echo "🔑 Fixing volume ownership..."
sudo mkdir -p "$HOME/.local/state"
sudo chown -R vscode:vscode "$HOME/.local" 2>/dev/null || true
mkdir -p "$PACKAGE_ROOT"
echo "   ✅ Done"

# ── Wait for Docker daemon (DinD takes a few seconds to start) ───────────────
echo ""
echo "⏳ Waiting for Docker daemon..."
TRIES=0
MAX_TRIES=30
until docker info >/dev/null 2>&1; do
    TRIES=$((TRIES + 1))
    if [ "$TRIES" -ge "$MAX_TRIES" ]; then
        echo "   ⚠️  Docker daemon did not start within ${MAX_TRIES}s"
        break
    fi
    sleep 1
done
docker info >/dev/null 2>&1 && echo "   ✅ Docker daemon is running"

# ── Agent tooling (npm-based, needs the Node feature) ─────────────────────────
# ast-grep ships as an npm package; install here since npm isn't on PATH at
# Dockerfile build time (the Node feature installs after the image build).
if ! command -v ast-grep >/dev/null 2>&1; then
    echo "📦 Installing ast-grep..."
    npm i -g @ast-grep/cli
    echo "   ✅ ast-grep $(ast-grep --version)"
else
    echo "✅ ast-grep already installed"
fi

# ── Harden sudo (must be last — setup above still needs it) ──────────────────
# Drop the NOPASSWD:ALL rule injected by the devcontainer base image.
# All privileged setup is complete at this point. Removing this rule means
# AI agents running in yolo/auto-approve modes cannot escalate to root.
# To temporarily regain sudo during a terminal session, rebuild the container.
echo "🔒 Hardening: removing NOPASSWD sudo rule..."
sudo rm -f /etc/sudoers.d/vscode
echo "   ✅ sudo disabled for vscode user"

# ── Verification ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  Environment Verification"
echo "══════════════════════════════════════════════════════════"
echo "  .NET SDK       : $(dotnet --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Docker         : $(docker --version 2>/dev/null || echo 'NOT RUNNING')"
echo "  Docker Compose : $(docker compose version 2>/dev/null || echo 'NOT FOUND')"
echo "  Node.js        : $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "  ripgrep        : $(rg --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  fd / bat / jq  : $(fd --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  ast-grep       : $(ast-grep --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Copilot CLI    : $(copilot --version 2>/dev/null || echo 'run: copilot')"
echo "  NuGet packages : ${PACKAGE_ROOT}"
echo "  Package path   : $([ -d "$PACKAGE_ROOT" ] && [ -w "$PACKAGE_ROOT" ] && echo 'writable' || echo 'NOT WRITABLE')"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "📋 Quick Start"
echo "  Verify DinD:           docker run --rm hello-world"
echo "  NuGet auth:            dotnet restore"
echo "  Copilot CLI:           copilot auth login"
echo ""
echo "💡 First time? On your Mac (one-time host setup):"
echo "  node .devcontainer/initialize-host-paths.mjs"
echo ""
