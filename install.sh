#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<EOF
Usage: ${0##*/} [--user|--system]

Installs DCodeTube to the current system.

  --user    Install to user-local directories (~/.local)
  --system  Install system-wide (/usr/local) — requires sudo

Examples:
  ${0##*/} --user
  sudo ${0##*/} --system
EOF
  exit 1
}

if [[ ${#@} -eq 0 ]]; then
  mode="user"
else
  case "$1" in
    --user) mode="user" ;;
    --system) mode="system" ;;
    *) usage ;;
  esac
fi

if [[ "$mode" == "user" ]]; then
  BIN_DIR="$HOME/.local/bin"
  LIB_DIR="$HOME/.local/lib/DCodeTube"
  CONF_DIR="$HOME/.config/DCodeTube"
  DATA_DIR="$HOME/.local/share/DCodeTube"
else
  BIN_DIR="/usr/local/bin"
  LIB_DIR="/usr/local/lib/DCodeTube"
  CONF_DIR="/etc/DCodeTube"
  DATA_DIR="/var/lib/DCodeTube"
fi

echo "Forwarding to bin/install.sh (preferred installer)"
if [[ -x "$REPO_ROOT/bin/install.sh" ]]; then
  exec "$REPO_ROOT/bin/install.sh" "$@"
else
  echo "bin/install.sh not found or not executable; aborting." >&2
  exit 1
fi
