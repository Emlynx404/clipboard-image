#!/bin/bash
# macOS clipboard image extraction
# Usage: grab-image-darwin.sh [save_directory]
# Output: JSON to stdout

SAVE_DIR="${1:-/tmp}"
RAND=$(head -c 2 /dev/urandom | xxd -p)
FILENAME="claude-paste-$(date +%Y%m%d-%H%M%S)-${RAND}.png"
FILEPATH="${SAVE_DIR}/${FILENAME}"

# Check if clipboard contains image data
has_image=$(osascript -e 'clipboard info' 2>/dev/null | grep -c 'PNGf\|TIFF')

if [ "$has_image" -eq 0 ]; then
  echo '{"success":false,"error":"No image found in clipboard"}'
  exit 1
fi

mkdir -p "$SAVE_DIR"

# Export clipboard image as PNG
osascript -e "
  set imgData to the clipboard as «class PNGf»
  set filePath to POSIX file \"${FILEPATH}\"
  set fileRef to open for access filePath with write permission
  write imgData to fileRef
  close access fileRef
" 2>/dev/null

if [ -f "$FILEPATH" ]; then
  # Resize if wider than 1920px
  width=$(sips -g pixelWidth "$FILEPATH" 2>/dev/null | tail -1 | awk '{print $2}')
  if [ -n "$width" ] && [ "$width" -gt 1920 ]; then
    sips --resampleWidth 1920 "$FILEPATH" >/dev/null 2>&1
  fi
  echo "{\"success\":true,\"path\":\"${FILEPATH}\"}"
else
  echo '{"success":false,"error":"Failed to export clipboard image"}'
  exit 1
fi
