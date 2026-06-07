# DCodeTube

> YouTube TUI Toolkit — Nord Edition

![DCodeTube Logo](./ascii-art-text.png)

**DCodeTube** is a Bash TUI (Terminal User Interface) tool for downloading YouTube videos, audio, and subtitles. Built with `yt-dlp`, `ffmpeg`, `jq`, and `fzf` — wrapped in a clean Nord-themed interface.

---
⠀⠀⢀⣀⣠⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣄⣀⡀⠀⠀
⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀
⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠈⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⢈⣹⣿⣿⣿⣿⣿⣿⣿⡇
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇
⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀
⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀
⠀⠀⠈⠉⠙⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠋⠉⠁⠀⠀

---

## Features

- **Video Download** — Select quality from available formats, auto-merges with best audio
- **Audio Extraction** — MP3, AAC, Opus, FLAC
- **Subtitles** — Dual-stage: manual subs → auto-generated fallback, converted to SRT
- **Video + Subtitles** — Download and burn subtitles directly into the MP4
- **Settings** — Configurable download path, default language, audio format
- **History** — Persistent transaction log viewed in read-only FZF browser
- **Nord Palette** — Carefully styled terminal UI with the Nord color scheme
- **ASCII Art Banner** — DCodeTube logo rendered in block characters
- **RTL Safe** — LRM-prefixed lines for Arabic subtitle display
- **Error Resilience** — Specific error messages for private/unavailable videos, ffmpeg failures

---

## Dependencies

| Tool | Purpose |
|------|---------|
| `yt-dlp` | Video/audio extraction engine |
| `ffmpeg` | Media merging and subtitle conversion |
| `jq` | JSON metadata parsing |
| `fzf` | Fuzzy finder TUI menu system |
| `node` | JavaScript runtime for yt-dlp fallback |

Verify with:

```bash
which yt-dlp ffmpeg jq fzf node
```

### Installation (Fedora)

```bash
sudo dnf install yt-dlp ffmpeg jq fzf nodejs
```

---

## Installation

Install using the provided installer script (recommended):

```bash
bash bin/install.sh --user
```

Quick install from terminal (replace <user>/<repo> with your GitHub repo):

```bash
curl -sSfL https://raw.githubusercontent.com/<user>/<repo>/main/install.sh | bash -s -- --user
```

Or install manually to your local user directories:

```bash
mkdir -p ~/.local/bin ~/.local/lib/DCodeTube ~/.config/DCodeTube ~/.local/share/DCodeTube
cp bin/DCodeTube ~/.local/bin/DCodeTube
cp lib/*.sh ~/.local/lib/DCodeTube/
cp config/config.conf ~/.config/DCodeTube/
touch ~/.local/share/DCodeTube/history.log
chmod +x ~/.local/bin/DCodeTube
```

Ensure `~/.local/bin` is in your `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Usage

```bash
DCodeTube
```

### Main Menu

| Option | Description |
|--------|-------------|
| `▶ Video` | Download video at selected quality |
| `♫ Audio` | Extract audio in chosen format |
| `☰ Subtitles` | Download SRT subtitles |
| `▣ Video + Subs` | Download video with burned-in subtitles |
| `⚙ Settings` | Change download path, language, audio format |
| `☰ History` | Browse download history |
| `✖ Exit` | Quit |

### Workflow

1. Launch `DCodeTube`
2. Choose download type from the FZF menu
3. Paste a YouTube URL (validates `youtube.com`, `youtu.be`, `youtube-nocookie.com`)
4. View video metadata (title, channel, duration, views)
5. Select quality / format / language from FZF
6. File saves to configured download directory

---

## Configuration

File: `~/.config/DCodeTube/config.conf`

```ini
DOWNLOAD_DIR=$HOME/Downloads
DEFAULT_LANG=en
DEFAULT_AUDIO_FORMAT=mp3
```

Edit via the Settings menu or directly in the file.

---

## Project Structure

```
~/.local/bin/DCodeTube          # Main entry point (executable)
~/.config/DCodeTube/config.conf  # User configuration
~/.local/share/DCodeTube/history.log  # Download history
~/.local/lib/DCodeTube/
├── core.sh       # Colors, globals, dependencies, logging
├── config.sh     # Config loader/saver, settings menu
├── ui.sh         # FZF menus, prompts, info display
└── download.sh   # yt-dlp wrappers, format parsing, download engines
```

---

## Error Handling

| Condition | Message |
|-----------|---------|
| Invalid URL | `Invalid URL` |
| Private video | `Video is private` |
| Unavailable video | `Video has been removed or is unavailable` |
| No subtitles | `No subtitles available` |
| ffmpeg failure | `Failed to merge video` |
| Missing deps | `Missing dependencies: ...` |

---

## Technical Details

- **Sourcing**: All library files use `${BASH_SOURCE[0]%/*}` for dynamic, collision-free includes
- **Cleanup**: `trap cleanup EXIT` removes temp directory on exit
- **Overwrite Prevention**: Auto-incrementing `_1`, `_2` suffixes for duplicate filenames
- **Subtitle Pipeline**: yt-dlp `--convert-subs srt` for native SRT output
- **JS Challenge Bypass**: `--js-runtimes node --remote-components ejs:github --no-warnings` flags on all yt-dlp calls
- **FZF Theme**: 24-bit Nord colors with `--ansi` flag for inline SGR support

---

## License

MIT — Free to use, modify, and distribute.
