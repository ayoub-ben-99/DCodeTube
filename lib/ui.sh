#!/usr/bin/env bash
set -Eeuo pipefail

source "${BASH_SOURCE[0]%/*}/core.sh"
source "${BASH_SOURCE[0]%/*}/config.sh"

# ── prompt_url ──
prompt_url() {
  local url
  read -r -p "$(echo -e "${NORD8}${BOLD}YouTube URL: ${RESET}")" url
  url="$(echo "$url" | xargs)"
  if [[ ! "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.be|youtube-nocookie\.com)/.*$ ]]; then
    die "Invalid URL"
  fi
  echo "$url"
}

# ── show_video_info ──
show_video_info() {
  local json="$1"
  local title channel duration views
  title=$(echo "$json" | jq -r '.title // "?"')
  channel=$(echo "$json" | jq -r '.channel // .uploader // "?"')
  duration=$(echo "$json" | jq -r '.duration // 0')
  views=$(echo "$json" | jq -r '.view_count // "?"')

  local dur_fmt
  if [[ "$duration" =~ ^[0-9]+$ ]]; then
    dur_fmt=$(printf '%02d:%02d:%02d' $((duration/3600)) $(( (duration%3600)/60 )) $((duration%60)))
  else
    dur_fmt="?"
  fi

  echo -e "${NORD9}${BOLD}══════════════ Video Information ══════════════${RESET}"
  echo -e "${NORD4}${BOLD}Title:${RESET}    ${NORD7}$title${RESET}"
  echo -e "${NORD4}${BOLD}Channel:${RESET}  ${NORD8}$channel${RESET}"
  echo -e "${NORD4}${BOLD}Duration:${RESET} ${NORD13}$dur_fmt${RESET}"
  echo -e "${NORD4}${BOLD}Views:${RESET}    ${NORD9}$views${RESET}"
  echo -e "${NORD3}────────────────────────────────────────────────${RESET}"
  echo
}

# ── main_menu ──
main_menu() {
  local items
  items=$(cat <<-EOF
${NORD7}▶ Video${RESET}
${NORD8}♫ Audio${RESET}
${NORD9}☰ Subtitles${RESET}
${NORD13}▣ Video + Subs${RESET}
${NORD8}⚙ Settings${RESET}
${NORD3}☰ History${RESET}
${NORD11}✖ Exit${RESET}
EOF
  )

  local sel
  sel=$(echo "$items" | fzf "${FZF_BASE_OPTS[@]}" \
    --prompt=" Main menu > " \
    --header=" Choose download type" \
    2>/dev/null)

  case "$sel" in
    *"Video"*)           echo "video" ;;
    *"Audio"*)           echo "audio" ;;
    *"Subtitles"*)       echo "subtitle" ;;
    *"Video + Subs"*)    echo "video+sub" ;;
    *"Settings"*)        echo "settings" ;;
    *"History"*)         echo "history" ;;
    *"Exit"*)            echo "exit" ;;
  esac
}

# ── select_quality ──
select_quality() {
  local formats_txt="$1"
  local sel
  sel=$(echo "$formats_txt" | fzf "${FZF_BASE_OPTS[@]}" \
    --prompt=" Quality > " \
    --header=" Choose quality (❯ to move, TAB to select)" \
    --with-nth=2.. \
    2>/dev/null)
  if [[ -z "$sel" ]]; then
    die "No quality selected"
  fi
  echo "$sel" | awk '{print $1}'
}

# ── select_audio_format ──
select_audio_format() {
  local fmts
  fmts=$(cat <<-EOF
${NORD7}mp3  MP3${RESET}
${NORD8}aac  AAC${RESET}
${NORD9}opus Opus${RESET}
${NORD13}flac FLAC${RESET}
EOF
  )

  local sel
  sel=$(echo "$fmts" | fzf "${FZF_BASE_OPTS[@]}" \
    --prompt=" Format > " \
    --header=" Choose audio format" \
    --with-nth=1 \
    2>/dev/null)
  if [[ -z "$sel" ]]; then
    echo "$DEFAULT_AUDIO_FORMAT"
    return
  fi
  echo "$sel" | awk '{print $1}'
}

# ── select_subtitle_lang ──
select_subtitle_lang() {
  local json="$1"
  local default="${2:-en}"

  local subs
  subs=$(echo "$json" | jq -r '.subtitles // {} | keys[]' 2>/dev/null || true)

  if [[ -z "$subs" ]]; then
    echo "$default"
    return
  fi

  local items=""
  while IFS= read -r lang; do
    [[ -z "$lang" ]] && continue
    items+="${NORD7}${lang}${RESET}\n"
  done <<< "$subs"

  items+="${NORD13}${default} (default)${RESET}"

  local sel
  sel=$(echo -e "$items" | fzf "${FZF_BASE_OPTS[@]}" \
    --prompt=" Subtitle language > " \
    --header=" Choose subtitle language" \
    2>/dev/null)
  if [[ -z "$sel" ]]; then
    echo "$default"
    return
  fi
  echo "$sel" | sed 's/.*\x1b\[[0-9;]*m//g' | awk '{print $1}'
}

# ── select_output_dir ──
select_output_dir() {
  read -r -e -p "$(echo -e "${NORD8}Save path: ${RESET}")" newdir
  if [[ -z "$newdir" ]]; then
    echo "$DOWNLOAD_DIR"
    return
  fi
  mkdir -p "$newdir" 2>/dev/null || die "Failed to create directory"
  echo "$newdir"
}

# ── show_history ──
show_history() {
  if [[ ! -f "$YTDL_HISTORY" ]]; then
    echo -e "${NORD13}No history yet${RESET}"
    read -r -p "$(echo -e "${NORD8}Press Enter to go back${RESET}")"
    return
  fi

  tail -r "$YTDL_HISTORY" | fzf "${FZF_BASE_OPTS[@]}" \
    --prompt=" History > " \
    --header=" Download history (newest first)" \
    --height=80% \
    --bind 'esc:abort' \
    2>/dev/null || true
}
