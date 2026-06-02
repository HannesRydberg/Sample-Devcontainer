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

# ── Prepare Copilot directories ──────────────────────────────────────────────
for dir in "$HOME/.agents" "$HOME/.agents/skills"; do
    mkdir -p "$dir"
done
if [ ! -w "$HOME/.agents/skills" ]; then
    echo "⚠️  $HOME/.agents/skills is not writable by $(whoami); fix host ownership or mode bits instead of changing them from inside the container"
fi
echo "✅ Copilot directories ready"

# ── Fix volume ownership ──────────────────────────────────────────────────────
echo "🔑 Fixing volume ownership..."
sudo mkdir -p \
    "$HOME/.local/share" \
    "$HOME/.local/state" \
    "$HOME/.nuget" \
    "$HOME/.copilot"
sudo chown -R vscode:vscode \
    "$HOME/.local" \
    "$HOME/.nuget" \
    "$HOME/.copilot" \
    2>/dev/null || true
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

# ── Load per-repo dev skills ─────────────────────────────────────────────────
# Reads the git-ignored .copilot-skills file at the repo root. Each line names a
# subdirectory under ~/.config/copilot-dev-skills/ on the host. Every skill folder
# (containing a SKILL.md) found there is copied into ~/.copilot/skills/ so Copilot
# picks it up. The file itself is never committed — each developer maintains their own.
SKILLS_CONFIG="/workspace/.copilot-skills"
SKILLS_STAGING="$HOME/.config/copilot-dev-skills"
SKILLS_DEST="$HOME/.copilot/skills"
if [ -f "$SKILLS_CONFIG" ] && [ -d "$SKILLS_STAGING" ]; then
    echo "🧠 Loading dev skills from .copilot-skills..."
    mkdir -p "$SKILLS_DEST"
    while IFS= read -r set_name || [ -n "$set_name" ]; do
        # Skip blank lines and comments
        [[ -z "$set_name" || "$set_name" == \#* ]] && continue
        set_dir="$SKILLS_STAGING/$set_name"
        if [ ! -d "$set_dir" ]; then
            echo "   ⚠️  Skill set '$set_name' not found at $set_dir — skipping"
            continue
        fi
        count=0
        for skill_dir in "$set_dir"/*/; do
            [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name="$(basename "$skill_dir")"
            cp -r "$skill_dir" "$SKILLS_DEST/$skill_name"
            count=$((count + 1))
        done
        echo "   ✅ $set_name — $count skill(s) loaded"
    done < "$SKILLS_CONFIG"
else
    [ ! -f "$SKILLS_CONFIG" ] && echo "ℹ️  No .copilot-skills file found — skipping dev skills"
    [ ! -d "$SKILLS_STAGING" ] && echo "ℹ️  ~/.config/copilot-dev-skills not found — skipping dev skills"
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
echo "  Python         : $(python3 --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Node.js        : $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Java           : $(java --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  Go             : $(go version 2>/dev/null || echo 'NOT FOUND')"
echo "  Docker         : $(docker --version 2>/dev/null || echo 'NOT RUNNING')"
echo "  Docker Compose : $(docker compose version 2>/dev/null || echo 'NOT FOUND')"
echo "  Copilot CLI    : $(copilot --version 2>/dev/null || echo 'run: copilot')"
echo "  SSH agent      : $([ -S "${SSH_AUTH_SOCK:-}" ] && echo "connected ($(ssh-add -l 2>/dev/null | wc -l | tr -d ' ') key(s))" || echo '⚠️  not connected')"
echo "  Copilot skills : $(ls "$HOME/.copilot/skills" 2>/dev/null | wc -l) file(s)"
echo "  Copilot agents : $(ls "$HOME/.copilot/agents" 2>/dev/null | wc -l) file(s)"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "📋 Quick Start"
echo "  Verify DinD:           docker run --rm hello-world"
echo "  Copilot CLI:           copilot auth login"
echo ""
echo "💡 First time? On your Mac (one-time host setup):"
echo "  mkdir -p ~/.copilot/skills ~/.agents/skills ~/.config/copilot-dev-skills ~/.config/dev"
echo "  cp .env.example ~/.config/dev/dev.env"
echo "  # then edit ~/.config/dev/dev.env with your actual tokens"
echo ""
