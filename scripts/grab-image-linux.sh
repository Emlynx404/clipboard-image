#!/bin/bash
# Linux clipboard image extraction (X11 + Wayland)
# Usage: grab-image-linux.sh [save_directory]
# Output: JSON to stdout

SAVE_DIR="${1:-/tmp}"
RAND=$(head -c 2 /dev/urandom | xxd -p)
FILENAME="claude-paste-$(date +%Y%m%d-%H%M%S)-${RAND}.png"
FILEPATH="${SAVE_DIR}/${FILENAME}"

# Detect display server and choose tool
if [ -n "$WAYLAND_DISPLAY" ]; then
  CLIP_TOOL="wl-paste"
  CLIP_CMD="wl-paste --type image/png"
else
  CLIP_TOOL="xclip"
  CLIP_CMD="xclip -selection clipboard -t image/png -o"
fi

# Check tool is installed
if ! command -v "$CLIP_TOOL" &>/dev/null; then
  echo "{\"success\":false,\"error\":\"Required tool not found: $CLIP_TOOL\"}"
  exit 1
fi

mkdir -p "$SAVE_DIR"

# Extract clipboard image
$CLIP_CMD > "$FILEPATH" 2>/dev/null

if [ ! -f "$FILEPATH" ] || [ ! -s "$FILEPATH" ]; then
  rm -f "$FILEPATH"
  echo '{"success":false,"error":"No image found in clipboard"}'
  exit 1
fi

# Resize if wider than 1920px (requires ImageMagick)
if command -v convert &>/dev/null; then
  width=$(identify -format "%w" "$FILEPATH" 2>/dev/null)
  if [ -n "$width" ] && [ "$width" -gt 1920 ]; then
    convert "$FILEPATH" -resize 1920x "$FILEPATH" 2>/dev/null
  fi
fi

echo "{\"success\":true,\"path\":\"${FILEPATH}\"}"
