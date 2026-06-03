#!/usr/bin/env bash
# .devcontainer/postCreate.sh
set -euo pipefail

# ── Load secrets ──────────────────────────────────────────────────────────────
load_env_file_safely() {
    local env_file="$1"
    local line key value

    [ -f "$env_file" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi

            export "$key=$value"
        else
            echo "⚠️  Skipping malformed env line in $env_file"
        fi
    done < "$env_file"
}

load_env_file_safely /run/secrets/dev.env

bashrc="$HOME/.bashrc"
managed_start='# >>> devcontainer safe env loader >>>'
managed_end='# <<< devcontainer safe env loader <<<'
legacy_hook='if [ -f /run/secrets/dev.env ]; then set -a; s'"ource /run/secrets/dev.env; set +a; fi"

if [ -f "$bashrc" ]; then
    tmp_bashrc="${bashrc}.tmp"
    awk -v legacy="$legacy_hook" -v start="$managed_start" -v end="$managed_end" '
        $0 == legacy { next }
        $0 == start { in_block=1; next }
        $0 == end { in_block=0; next }
        !in_block { print }
    ' "$bashrc" > "$tmp_bashrc"
    mv "$tmp_bashrc" "$bashrc"
fi

cat >> "$bashrc" <<'EOF'

# >>> devcontainer safe env loader >>>
load_env_file_safely() {
    local env_file="$1"
    local line key value

    [ -f "$env_file" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi

            export "$key=$value"
        else
            echo "⚠️  Skipping malformed env line in $env_file"
        fi
    done < "$env_file"
}

load_env_file_safely /run/secrets/dev.env
# <<< devcontainer safe env loader <<<
EOF

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
HOST_COPILOT_SKILLS="/mnt/host-inputs/copilot-skills"
HOST_AGENT_SKILLS="/mnt/host-inputs/agent-skills"
HOST_SKILLS_STAGING="/mnt/host-inputs/copilot-dev-skills"
SKILLS_CONFIG="/workspace/.copilot-skills"
ACTIVE_COPILOT_SKILLS="$HOME/.copilot/skills"
ACTIVE_AGENT_SKILLS="$HOME/.agents/skills"

sync_skill_tree() {
    local src_root="$1"
    local dest_root="$2"
    local skill_dir skill_name

    [ -d "$src_root" ] || return 0

    shopt -s nullglob
    for skill_dir in "$src_root"/*/; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        skill_name="$(basename "$skill_dir")"
        rm -rf "$dest_root/$skill_name"
        cp -R "$skill_dir" "$dest_root/$skill_name"
    done
    shopt -u nullglob
}

skill_inputs_ready() {
    [ -d "$HOST_COPILOT_SKILLS" ] && [ -r "$HOST_COPILOT_SKILLS" ] || return 1
    [ -d "$HOST_AGENT_SKILLS" ] && [ -r "$HOST_AGENT_SKILLS" ] || return 1

    if [ -f "$SKILLS_CONFIG" ]; then
        [ -d "$HOST_SKILLS_STAGING" ] && [ -r "$HOST_SKILLS_STAGING" ] || return 1
    fi
}

if ! skill_inputs_ready; then
    echo "⚠️  Hardened skill-loading requires the /mnt/host-inputs mounts."
    echo "   Rebuild the container before rerunning postCreate.sh so active skill paths stay untouched."
else
    echo "🧠 Refreshing container-local skills from read-only host inputs..."
    rm -rf "$ACTIVE_COPILOT_SKILLS" "$ACTIVE_AGENT_SKILLS"
    mkdir -p "$ACTIVE_COPILOT_SKILLS" "$ACTIVE_AGENT_SKILLS"

    sync_skill_tree "$HOST_COPILOT_SKILLS" "$ACTIVE_COPILOT_SKILLS"
    sync_skill_tree "$HOST_AGENT_SKILLS" "$ACTIVE_AGENT_SKILLS"

    if [ -f "$SKILLS_CONFIG" ] && [ -d "$HOST_SKILLS_STAGING" ]; then
        while IFS= read -r set_name || [ -n "$set_name" ]; do
            [[ -z "$set_name" || "$set_name" == \#* ]] && continue
            set_dir="$HOST_SKILLS_STAGING/$set_name"
            if [ ! -d "$set_dir" ]; then
                echo "   ⚠️  Skill set '$set_name' not found at $set_dir — skipping"
                continue
            fi
            sync_skill_tree "$set_dir" "$ACTIVE_COPILOT_SKILLS"
        done < "$SKILLS_CONFIG"
    else
        [ ! -f "$SKILLS_CONFIG" ] && echo "ℹ️  No .copilot-skills file found — skipping repo skill import"
        [ ! -d "$HOST_SKILLS_STAGING" ] && echo "ℹ️  Host copilot-dev-skills staging directory not found — skipping repo skill import"
    fi
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
echo "  Skill/config changes: rebuild the devcontainer to refresh container-local loaded copies"
echo ""
echo "💡 First time? On your Mac (one-time host setup):"
echo "  mkdir -p ~/.copilot/skills ~/.agents/skills ~/.config/copilot-dev-skills ~/.config/dev"
echo "  cp .env.example ~/.config/dev/dev.env"
echo "  # then edit ~/.config/dev/dev.env with your actual tokens"
echo ""
