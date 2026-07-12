#!/usr/bin/env bash
set -Eeuo pipefail

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"

UA="Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.135 Mobile Safari/537.36"
YTDLP_OPTS=(
  --js-runtimes node --remote-components ejs:github --no-warnings
  --user-agent "$UA"
  --extractor-args "youtube:player_client=android_creator;player_skip=webpage"
  --retries 10 --extractor-retries 10
  --sleep-requests 1 --sleep-interval 3 --max-sleep-interval 10
  --add-metadata
  --embed-thumbnail
  --write-info-json
  --write-description
  --no-mtime
  --xattrs
)
YTDLP_SUB_OPTS=(
  --js-runtimes node --remote-components ejs:github --no-warnings
  --user-agent "$UA"
  --extractor-args "youtube:player_client=android_creator,web;player_skip=webpage"
  --retries 15 --extractor-retries 15
  --sleep-requests 2 --sleep-interval 5 --max-sleep-interval 15
  --no-mtime
)

# ── get_video_info ──
get_video_info() {
  local url="$1"
  local json
  local err
  err=$(mktemp "$YTDL_TEMP/ytdlp_err.XXXXXX")

  if ! json=$(yt-dlp "${YTDLP_OPTS[@]}" -J "$url" 2>"$err"); then
    local stderr
    stderr=$(<"$err")
    if [[ "$stderr" =~ "Private" ]]; then
      die "Video is private"
    elif [[ "$stderr" =~ "unavailable" ]]; then
      die "Video has been removed or is unavailable"
    elif [[ "$stderr" =~ "429" || "$stderr" =~ "Too Many Requests" ]]; then
      die "HTTP 429 Too Many Requests — YouTube is rate-limiting. Wait a few minutes and try again."
    else
      die "$stderr"
    fi
  fi

  echo "$json"
}

# ── parse_formats ──
parse_formats() {
  local json="$1"
  jq -r '.formats[] | select(.vcodec != "none" and .acodec == "none") | select(.height != null) | "\(.format_id)\t\(.height)p\t\(.fps // "?")fps\t\(.vcodec | split(".")[0])\t\(if .filesize then (.filesize/1048576 | floor | tostring) + "MB" else "?MB" end)"' <<< "$json"
}

# ── safe_output_path ──
safe_output_path() {
  local base="$1"
  local ext="$2"
  local out="$base.$ext"
  local i=1
  while [[ -f "$out" ]]; do
    out="${base}_${i}.${ext}"
    ((i++))
  done
  echo "$out"
}

# ── download_video ──
download_video() {
  local url="$1"
  local format_id="$2"
  local title="$3"

  echo -e "${NORD8}${BOLD}Downloading video...${RESET}"

  local safe_title
  safe_title=$(echo "$title" | tr -dc '[:alnum:] _-')
  [[ -z "$safe_title" ]] && safe_title="video_$(date +%s)"
  mkdir -p "$DOWNLOAD_DIR"
  local output_template="$DOWNLOAD_DIR/%(title)s.%(ext)s"

  yt-dlp "${YTDLP_OPTS[@]}" \
    -f "${format_id}+bestaudio/best" \
    -o "$output_template" \
    --merge-output-format mp4 \
    --no-overwrites \
    --restrict-filenames \
    "$url" 2>"$YTDL_TEMP/dl_err.txt" || {
    local dl_err
    dl_err=$(<"$YTDL_TEMP/dl_err.txt")
    if [[ "$dl_err" =~ "ffmpeg" ]]; then
      die "Failed to merge video"
    fi
    die "Download failed: $dl_err"
  }

  local final_file
  final_file=$(ls -t "$DOWNLOAD_DIR"/*.mp4 2>/dev/null | head -1)
  log_entry "VIDEO" "$title"
  echo -e "${NORD7}${BOLD}✓ Downloaded: ${final_file}${RESET}"
}

# ── download_audio ──
download_audio() {
  local url="$1"
  local fmt="$2"
  local title="$3"

  echo -e "${NORD8}${BOLD}Downloading audio...${RESET}"

  mkdir -p "$DOWNLOAD_DIR"
  local output_template="$DOWNLOAD_DIR/%(title)s.%(ext)s"

  yt-dlp "${YTDLP_OPTS[@]}" \
    -f bestaudio/best \
    -o "$output_template" \
    --extract-audio \
    --audio-format "$fmt" \
    --no-overwrites \
    --restrict-filenames \
    "$url" 2>"$YTDL_TEMP/dl_err.txt" || {
    local dl_err
    dl_err=$(<"$YTDL_TEMP/dl_err.txt")
    if [[ "$dl_err" =~ "ffmpeg" ]]; then
      die "Failed to merge audio"
    fi
    die "Download failed: $dl_err"
  }

  log_entry "AUDIO" "$title"
  echo -e "${NORD7}${BOLD}✓ Audio downloaded${RESET}"
}

# ── download_subtitles ──
download_subtitles() {
  local url="$1"
  local lang="$2"
  local title="$3"

  echo -e "${NORD8}${BOLD}Downloading subtitles...${RESET}"

  mkdir -p "$DOWNLOAD_DIR"
  local output_template="$DOWNLOAD_DIR/%(title)s.%(ext)s"

  # Stage 1: Manual subtitles
  if yt-dlp "${YTDLP_OPTS[@]}" "${YTDLP_SUB_OPTS[@]}" \
    --skip-download \
    --write-subs \
    --sub-langs "$lang" \
    --convert-subs srt \
    -o "$output_template" \
    --restrict-filenames \
    "$url" 2>"$YTDL_TEMP/sub_err.txt"; then

    local sub_file
    sub_file=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name "*.srt" 2>/dev/null | head -1)
    if [[ -n "$sub_file" ]]; then
      log_entry "SUBTITLE" "$title"
      echo -e "${NORD7}${BOLD}✓ Subtitles downloaded: ${sub_file}${RESET}"
      return
    fi
  fi

  # Stage 2: Auto-generated subtitles (fallback)
  echo -e "${NORD13}${BOLD}Manual subtitles unavailable, fetching auto-generated...${RESET}"

  if yt-dlp "${YTDLP_OPTS[@]}" "${YTDLP_SUB_OPTS[@]}" \
    --skip-download \
    --write-auto-subs \
    --sub-langs "$lang" \
    --convert-subs srt \
    -o "$output_template" \
    --restrict-filenames \
    "$url" 2>"$YTDL_TEMP/auto_sub_err.txt"; then

    local sub_file
    sub_file=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name "*.srt" 2>/dev/null | head -1)
    if [[ -n "$sub_file" ]]; then
      log_entry "SUBTITLE" "$title"
      echo -e "${NORD13}${BOLD}✓ Auto subtitles downloaded: ${sub_file}${RESET}"
      return
    fi
  fi

  die "No subtitles available"
}

# ── download_video_with_subtitles ──
download_video_with_subtitles() {
  local url="$1"
  local format_id="$2"
  local lang="$3"
  local title="$4"

  echo -e "${NORD8}${BOLD}Downloading video with subtitles...${RESET}"

  mkdir -p "$DOWNLOAD_DIR"
  local output_template="$DOWNLOAD_DIR/%(title)s.%(ext)s"

  yt-dlp "${YTDLP_OPTS[@]}" "${YTDLP_SUB_OPTS[@]}" \
    -f "${format_id}+bestaudio/best" \
    -o "$output_template" \
    --merge-output-format mp4 \
    --no-overwrites \
    --restrict-filenames \
    --write-subs \
    --sub-langs "$lang" \
    --convert-subs srt \
    --embed-subs \
    --add-metadata \
    --embed-thumbnail \
    --write-info-json \
    --write-description \
    "$url" 2>"$YTDL_TEMP/dlsub_err.txt" || {
    local dl_err
    dl_err=$(<"$YTDL_TEMP/dlsub_err.txt")
    if [[ "$dl_err" =~ "ffmpeg" ]]; then
      die "Failed to merge video"
    fi
    die "Download failed: $dl_err"
  }

  local video_file
  video_file=$(ls -t "$DOWNLOAD_DIR"/*.mp4 2>/dev/null | head -1)

  local sub_file
  sub_file=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name "*.srt" 2>/dev/null | head -1)

  if [[ -n "$video_file" && -n "$sub_file" ]]; then
    echo -e "${NORD8}${BOLD}Burning subtitles into video...${RESET}"

    local output_file
    output_file=$(safe_output_path "${video_file%.mp4}_with_subs" "mp4")

    ffmpeg -i "$video_file" -f srt -i "$sub_file" \
      -c:v copy -c:a copy -c:s mov_text \
      -metadata:s:s:0 language="$lang" \
      "$output_file" -y 2>"$YTDL_TEMP/ffmpeg_err.txt" || {
      local ff_err
      ff_err=$(<"$YTDL_TEMP/ffmpeg_err.txt")
      die "Failed to merge video: $ff_err"
    }

    [[ "$output_file" != "$video_file" ]] && rm -f "$video_file"
    rm -f "$sub_file"

    log_entry "VIDEO+SUB" "$title"
    echo -e "${NORD7}${BOLD}✓ Downloaded with subtitles: ${output_file}${RESET}"
  elif [[ -n "$video_file" ]]; then
    log_entry "VIDEO+SUB" "$title (no subtitles)"
    echo -e "${NORD13}${BOLD}✓ Video downloaded without subtitles${RESET}"
  else
    die "Failed to download video"
  fi
}
