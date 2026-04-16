#!/bin/bash
# Platform dispatcher for clipboard image extraction.
# Detects OS and delegates to the appropriate platform script.
# Usage: grab-image.sh [save_directory]
# Output: JSON to stdout

SAVE_DIR="${1:-/tmp}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-cleanup: remove claude-paste-*.png files older than 24 hours
find "$SAVE_DIR" -maxdepth 1 -name "claude-paste-*.png" -type f -mmin +1440 -delete 2>/dev/null

case "$(uname -s)" in
  Darwin)
    bash "$SCRIPT_DIR/grab-image-darwin.sh" "$SAVE_DIR"
    ;;
  Linux)
    bash "$SCRIPT_DIR/grab-image-linux.sh" "$SAVE_DIR"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/grab-image-win.ps1" "$SAVE_DIR"
    ;;
  *)
    echo "{\"success\":false,\"error\":\"Unsupported platform: $(uname -s)\"}"
    exit 1
    ;;
esac
