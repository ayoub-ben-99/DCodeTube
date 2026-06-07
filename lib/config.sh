#!/usr/bin/env bash
set -Eeuo pipefail

source "${BASH_SOURCE[0]%/*}/core.sh"

# ── load_config ──
load_config() {
  if [[ -f "$YTDL_CONFIG" ]]; then
    while IFS='=' read -r key value; do
      [[ -z "$key" || "$key" =~ ^# ]] && continue
      key="$(echo "$key" | xargs)"
      value="$(echo "$value" | xargs)"
      case "$key" in
        DOWNLOAD_DIR) DOWNLOAD_DIR="$value" ;;
        DEFAULT_LANG) DEFAULT_LANG="$value" ;;
        DEFAULT_AUDIO_FORMAT) DEFAULT_AUDIO_FORMAT="$value" ;;
      esac
    done < "$YTDL_CONFIG"
  else
    save_config
  fi
}

# ── save_config ──
save_config() {
  mkdir -p "$(dirname "$YTDL_CONFIG")"
  cat > "$YTDL_CONFIG" <<-EOF
DOWNLOAD_DIR=$DOWNLOAD_DIR
DEFAULT_LANG=$DEFAULT_LANG
DEFAULT_AUDIO_FORMAT=$DEFAULT_AUDIO_FORMAT
EOF
}

# ── show_settings_menu ──
show_settings_menu() {
  local choices
  choices=$(
    echo -e "${NORD8}Download path${RESET}"
    echo -e "${NORD8}Default language${RESET}"
    echo -e "${NORD8}Audio format${RESET}"
    echo -e "${NORD13}Back${RESET}"
  )

  local sel
  sel=$(echo "$choices" | fzf "${FZF_BASE_OPTS[@]}" \
  --prompt=" Settings > " \
  --header=" DCodeTube settings" \
  --height=40% \
  2>/dev/null)

  case "$sel" in
    "Download path"*)
      read -r -e -p "$(echo -e "${NORD8}Download path: ${RESET}")" newdir
      if [[ -n "$newdir" ]]; then
        mkdir -p "$newdir" 2>/dev/null || die "Failed to create directory"
        DOWNLOAD_DIR="$newdir"
        save_config
      fi
      ;;
    "Default language"*)
      local langs
      langs=$(echo -e "ar\nen\nfr\nde\nes\ntr")
      local lsel
      lsel=$(echo "$langs" | fzf "${FZF_BASE_OPTS[@]}" \
        --prompt=" Language > " \
        --header=" Choose default language" \
        2>/dev/null)
      if [[ -n "$lsel" ]]; then
        DEFAULT_LANG="$lsel"
        save_config
      fi
      ;;
    "Audio format"*)
      local fmts
      fmts=$(echo -e "mp3\naac\nopus\nflac")
      local fsel
      fsel=$(echo "$fmts" | fzf "${FZF_BASE_OPTS[@]}" \
        --prompt=" Format > " \
        --header=" Choose audio format" \
        2>/dev/null)
      if [[ -n "$fsel" ]]; then
        DEFAULT_AUDIO_FORMAT="$fsel"
        save_config
      fi
      ;;
  esac
}
