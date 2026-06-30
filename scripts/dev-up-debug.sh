#!/usr/bin/env bash

set -euo pipefail

log_dir="${HOME}/.config/dev/logs"
mkdir -p "$log_dir"
log_file="${log_dir}/devcontainer-up-$(date +%Y%m%d-%H%M%S).log"

cmd=(devcontainer up --workspace-folder . --log-level trace --log-format text "$@")

echo "==> Running devcontainer with trace logging"
echo "==> Command: ${cmd[*]}"
echo "==> Log file: $log_file"

set +e
"${cmd[@]}" 2>&1 | tee "$log_file"
status=${PIPESTATUS[0]}
set -e

if [ "$status" -eq 0 ]; then
  echo "Devcontainer started successfully."
  echo "Trace log saved to: $log_file"
  exit 0
fi

echo ""
echo "devcontainer up failed (exit code $status)."
echo "Trace log saved to: $log_file"
echo ""
echo "Most recent error lines:"
grep -Eni "error|failed|fatal|exception" "$log_file" | tail -n 20 || true

exit "$status"
