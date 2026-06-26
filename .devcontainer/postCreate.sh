#!/usr/bin/env bash
# .devcontainer/postCreate.sh
set -euo pipefail

retry_cmd() {
    local max_attempts="$1"
    shift
    local attempt=1
    local delay=2

    while true; do
        if "$@"; then
            return 0
        fi

        if [ "$attempt" -ge "$max_attempts" ]; then
            return 1
        fi

        echo "   ↻ Attempt ${attempt}/${max_attempts} failed; retrying in ${delay}s..."
        sleep "$delay"
        attempt=$((attempt + 1))
        if [ "$delay" -lt 10 ]; then
            delay=$((delay * 2))
        fi
    done
}

wait_for_dns() {
    local host="$1"
    local max_tries="$2"
    local tries=0

    while ! getent hosts "$host" >/dev/null 2>&1; do
        tries=$((tries + 1))
        if [ "$tries" -ge "$max_tries" ]; then
            return 1
        fi
        sleep 1
    done
}

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

grep -q 'yolopilot' "$HOME/.bashrc" 2>/dev/null \
    || echo "alias yolopilot='copilot --yolo --experimental'" >> "$HOME/.bashrc"

echo ""
echo "🔧 Running post-create setup..."
echo ""

PACKAGE_ROOT="${NUGET_PACKAGES:-$HOME/.nuget/packages}"

# ── Prepare Copilot ───────────────────────────────────────────────────────────
# ~/.copilot is bind-mounted directly from the host. Shared config and session
# history — avoid running Copilot on host + container simultaneously to prevent
# SQLite lock contention.
# Ensure ~/.copilot root itself is writable by vscode. Feature install steps can
# leave the directory root-owned, which makes `copilot` exit immediately.
sudo mkdir -p "$HOME/.copilot"
sudo chown vscode:vscode "$HOME/.copilot"
echo "✅ Copilot directory ready (bind mount from host)"

# ── Fix volume ownership ──────────────────────────────────────────────────────
echo "🔑 Fixing volume ownership..."
# Prevent noisy "sudo: unable to resolve host <container-id>" on fresh containers.
if ! getent hosts "$(hostname)" >/dev/null 2>&1; then
    echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts >/dev/null
fi
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
    if ! wait_for_dns registry.npmjs.org 30; then
        echo "❌ DNS for registry.npmjs.org did not resolve within 30s."
        echo "   Network was not ready during post-create; failing setup."
        exit 1
    fi
    if ! retry_cmd 5 npm i -g @ast-grep/cli; then
        echo "❌ Failed to install @ast-grep/cli after 5 attempts."
        echo "   Last command: npm i -g @ast-grep/cli"
        exit 1
    fi
    echo "   ✅ ast-grep $(ast-grep --version)"
else
    echo "✅ ast-grep already installed"
fi

# ── Write / append tool-preference section to AGENTS.md ──────────────────────
# AGENTS.md is read passively by Copilot CLI (and most other agents) at session
# start — no skill invocation required. The template section is idempotent: it
# is only appended when the sentinel comment is absent, so re-creating the
# container never duplicates content. Existing content is never removed.
AGENTS_MD="/workspace/AGENTS.md"
AGENTS_TEMPLATE="/workspace/.devcontainer/AGENTS.md.template"
AGENTS_SENTINEL="<!-- devcontainer:prefer-container-tools -->"
if [ -f "$AGENTS_TEMPLATE" ]; then
    if [ ! -f "$AGENTS_MD" ]; then
        cp "$AGENTS_TEMPLATE" "$AGENTS_MD"
        echo "✅ Created /workspace/AGENTS.md from template"
    elif grep -qF "$AGENTS_SENTINEL" "$AGENTS_MD"; then
        echo "✅ AGENTS.md already contains tool-preference section (skipping)"
    else
        printf '\n' >> "$AGENTS_MD"
        cat "$AGENTS_TEMPLATE" >> "$AGENTS_MD"
        echo "✅ Appended tool-preference section to existing AGENTS.md"
    fi
fi

# ── Copy repo-bundled skills into ~/.copilot/skills ──────────────────────────
# Skills placed under .devcontainer/skills/ are copied into the active skills
# directory so they are available to agents without requiring manual host setup.
REPO_SKILLS_DIR="/workspace/.devcontainer/skills"
if [ -d "$REPO_SKILLS_DIR" ]; then
    echo "📚 Installing repo-bundled skills..."
    for skill_dir in "$REPO_SKILLS_DIR"/*/; do
        skill_name="$(basename "$skill_dir")"
        dest="$HOME/.copilot/skills/$skill_name"
        if [ ! -d "$dest" ]; then
            cp -r "$skill_dir" "$dest"
            echo "   ✅ Installed skill: $skill_name"
        else
            echo "   ⏭  Skill already present (not overwriting): $skill_name"
        fi
    done
else
    echo "ℹ️  No repo-bundled skills found (skipping)"
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
