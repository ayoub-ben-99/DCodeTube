#!/usr/bin/env bash
set -Eeuo pipefail

# ──────────────────────────────────────────────
# DCodeTube — core.sh
# Globals, visuals, dependencies, logging
# ──────────────────────────────────────────────

# ── Nord Palette ──
NORD0=$'\033[38;2;46;52;64m'
NORD3=$'\033[38;2;76;86;106m'
NORD4=$'\033[38;2;216;222;233m'
NORD7=$'\033[38;2;143;188;187m'
NORD8=$'\033[38;2;136;192;208m'
NORD9=$'\033[38;2;129;161;193m'
NORD11=$'\033[38;2;191;97;106m'
NORD13=$'\033[38;2;235;203;139m'
NORD14=$'\033[38;2;163;190;140m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# ── Paths ──
YTDL_HISTORY="$HOME/.local/share/DCodeTube/history.log"
YTDL_CONFIG="$HOME/.config/DCodeTube/config.conf"
YTDL_TEMP=$(mktemp -d)

# ── FZF Base Options ──
FZF_BASE_OPTS=(
  --ansi
  --layout=reverse
  --border=rounded
  --border-label=" DCodeTube "
  --border-label-pos=3
  --color="bg:#2E3440,bg+:#3B4252,fg:#D8DEE9,fg+:#ECEFF4"
  --color="hl:#88C0D0,hl+:#81A1C1,border:#4C566A,prompt:#8FBCBB"
  --color="pointer:#88C0D0,marker:#A3BE8C,spinner:#88C0D0,header:#616E88"
  --pointer='❯'
  --marker='✓'
  --prompt='  '
  --height=60%
  --min-height=15
)

# ── Global variables ──
DOWNLOAD_DIR="$HOME/Downloads"
DEFAULT_LANG="en"
DEFAULT_AUDIO_FORMAT="mp3"

# ── Cleanup ──
cleanup() { rm -rf "$YTDL_TEMP"; }
trap cleanup EXIT

# ── Output helpers ──
die()     { printf '%s%s✖  %s%s\n' "$NORD11" "$BOLD" "$*" "$RESET" >&2; exit 1; }
warn()    { printf '%s⚠  %s%s\n'   "$NORD13" "$*" "$RESET" >&2; }
info()    { printf '%s●  %s%s\n'   "$NORD8"  "$*" "$RESET"; }
success() { printf '%s%s✔  %s%s\n' "$NORD14" "$BOLD" "$*" "$RESET"; }
step()    { printf '%s%s▶  %s%s\n' "$NORD9"  "$BOLD" "$*" "$RESET"; }

# ── show_banner ──
# Inner box width = 50 chars. Padding per line is precomputed (bash ${#}
# counts bytes for multi-byte UTF-8 chars, so we hardcode correct values).
#   lines 1-4  → content 30 chars → 20 trailing spaces
#   lines 5-6  → content 35 chars → 15 trailing spaces
#   subtitle   → content 37 chars → 13 trailing spaces
show_banner() {
  local B="${NORD9}${BOLD}" R="$RESET"
  local A="${NORD8}${BOLD}" S="$NORD3"

  clear
  printf '%s╔══════════════════════════════════════════════════╗%s\n' "$B" "$R"
  local PLAY_BADGE="${NORD11}${BOLD}▶${RESET}"
  local PRODUCT="${A}DCodeTube${RESET}"
  printf '%s║%s  %s  %s  %s󰗃 YouTube TUI Toolkit -- Nord Edition%s             %s║%s\n' "$B" "$R" "$PLAY_BADGE" "$R" "$PRODUCT" "$R" "$B" "$R"
  printf '%s╚══════════════════════════════════════════════════╝%s\n' "$B" "$R"
  printf '\n'
}

# ── check_dependencies ──
check_dependencies() {
  local deps=("yt-dlp" "ffmpeg" "jq" "fzf" "node")
  local missing=()
  for dep in "${deps[@]}"; do
    command -v "$dep" &>/dev/null || missing+=("$dep")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "Missing dependencies: ${missing[*]}"
}

# ── log_entry ──
log_entry() {
  local op_type="$1"
  local title="$2"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] %-10s | %s\n' "$ts" "$op_type" "$title" >> "$YTDL_HISTORY"
}
