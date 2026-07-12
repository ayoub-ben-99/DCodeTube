#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
REPO_URL="https://github.com/ayoub-ben-99/DCodeTube"
ARCHIVE_URL="$REPO_URL/archive/refs/heads/main.tar.gz"
TMP_ROOT=""

cleanup() {
  if [[ -n "$TMP_ROOT" ]]; then
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

is_repo_root() {
  [[ -f "$1/bin/install.sh" && -f "$1/bin/DCodeTube" && -d "$1/lib" ]]
}

if is_repo_root "$SCRIPT_DIR"; then
  REPO_ROOT="$SCRIPT_DIR"
elif is_repo_root "$PWD"; then
  REPO_ROOT="$PWD"
else
  TMP_ROOT="$(mktemp -d)"
  echo "Downloading DCodeTube installer files..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMP_ROOT"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$ARCHIVE_URL" | tar -xz -C "$TMP_ROOT"
  else
    echo "curl or wget is required to install from a pipe." >&2
    exit 1
  fi
  REPO_ROOT="$TMP_ROOT/DCodeTube-main"
fi

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
if [[ -f "$REPO_ROOT/bin/install.sh" ]]; then
  exec bash "$REPO_ROOT/bin/install.sh" "$@"
else
  echo "bin/install.sh not found; aborting." >&2
  exit 1
fi
