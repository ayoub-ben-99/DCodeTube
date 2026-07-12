#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
if [[ -z "$SCRIPT_SOURCE" ]]; then
  echo "Unable to determine script location; run this installer from a file path." >&2
  exit 1
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
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

echo "Installing DCodeTube -> $BIN_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR" "$CONF_DIR" "$DATA_DIR"

# Copy main executable
if [[ -f "$REPO_ROOT/bin/DCodeTube" ]]; then
  cp "$REPO_ROOT/bin/DCodeTube" "$BIN_DIR/DCodeTube"
  chmod +x "$BIN_DIR/DCodeTube" 2>/dev/null || true
else
  echo "No executable found in repo/bin (expected bin/DCodeTube)" >&2
fi

# Copy library scripts
cp -a "$REPO_ROOT/lib/"*.sh "$LIB_DIR/" 2>/dev/null || true

# Copy config
if [[ -f "$REPO_ROOT/config/config.conf" ]]; then
  cp "$REPO_ROOT/config/config.conf" "$CONF_DIR/config.conf"
fi

# Ensure history log exists
mkdir -p "$(dirname "$DATA_DIR/history.log")"
touch "$DATA_DIR/history.log"

echo "DCodeTube installed successfully."
echo "Run: $BIN_DIR/DCodeTube"
