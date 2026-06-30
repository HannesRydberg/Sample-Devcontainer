#!/usr/bin/env bash

set -euo pipefail

NODE_MAJOR_REQUIRED=24
failures=0
warnings=0

ok() {
  echo "OK: $1"
}

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

warn() {
  echo "WARN: $1"
  warnings=$((warnings + 1))
}

check_command() {
  local cmd="$1"
  local name="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$name installed"
  else
    fail "$name missing ($cmd not found)"
  fi
}

check_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    ok "Directory exists: $dir"
  else
    fail "Directory missing: $dir"
  fi
}

check_initialize_host_paths() {
  local log_file
  log_file="$(mktemp)"
  if node .devcontainer/initialize-host-paths.mjs >"$log_file" 2>&1; then
    ok "Host bootstrap initialize script succeeded (.devcontainer/initialize-host-paths.mjs)"
  else
    fail "Host bootstrap initialize script failed (.devcontainer/initialize-host-paths.mjs)"
    echo "----- initialize-host-paths output -----"
    cat "$log_file"
    echo "----- end initialize-host-paths output -----"
  fi
  rm -f "$log_file"
}

echo "==> Running setup preflight checks"

check_command docker "Docker"
if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose plugin available"
  else
    fail "Docker Compose plugin missing (docker compose)"
  fi
fi

check_command devcontainer "Dev Containers CLI"
check_command node "Node.js"
if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$node_major" -ge "$NODE_MAJOR_REQUIRED" ]; then
    ok "Node.js version satisfies requirement (>= ${NODE_MAJOR_REQUIRED}): $(node -v)"
  else
    fail "Node.js version too old: $(node -v), need >= ${NODE_MAJOR_REQUIRED}"
  fi
fi

check_command pnpm "pnpm"

if grep -qi microsoft /proc/version 2>/dev/null; then
  if command -v wslvar >/dev/null 2>&1; then
    ok "wslu installed (wslvar available)"
    win_profile="$(wslvar USERPROFILE 2>/dev/null || true)"
    if [ -z "$win_profile" ]; then
      fail "wslvar is present but USERPROFILE could not be resolved"
    elif command -v wslpath >/dev/null 2>&1 && wslpath "$win_profile" >/dev/null 2>&1; then
      ok "Windows USERPROFILE resolves to a valid WSL path"
    else
      fail "Windows USERPROFILE did not convert to a valid WSL path via wslpath"
    fi
  else
    fail "wslu missing (wslvar not found)"
  fi
fi

check_dir "$HOME/.config/dev"
check_dir "$HOME/.copilot"
check_dir "$HOME/.nuget/packages"

env_file="$HOME/.config/dev/dev.env"
if [ -f "$env_file" ]; then
  ok "Secrets file exists: $env_file"
  if grep -Eq '^[[:space:]]*COPILOT_GITHUB_TOKEN[[:space:]]*=[[:space:]]*".+"[[:space:]]*$|^[[:space:]]*COPILOT_GITHUB_TOKEN[[:space:]]*=[[:space:]]*[^"#[:space:]].*$' "$env_file"; then
    ok "COPILOT_GITHUB_TOKEN appears configured"
  else
    warn "COPILOT_GITHUB_TOKEN is not set in $env_file"
  fi
else
  fail "Secrets file missing: $env_file"
fi

if [ -f ".devcontainer/initialize-host-paths.mjs" ]; then
  check_initialize_host_paths
else
  fail "Missing .devcontainer/initialize-host-paths.mjs (run doctor from repo root)"
fi

echo ""
if [ "$failures" -gt 0 ]; then
  echo "Preflight failed: $failures issue(s), $warnings warning(s)."
  exit 1
fi

echo "Preflight passed with $warnings warning(s)."
