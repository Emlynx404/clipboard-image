# Cross-Platform Clipboard Image Extraction

## Goal

Add Linux and Windows support to the clipboard-image plugin, which currently only works on macOS.

## Architecture

Split the single `grab-image.sh` into a platform dispatcher and per-platform scripts:

```
scripts/
  grab-image.sh          # Entry point: detect OS, delegate to platform script
  grab-image-darwin.sh   # macOS: osascript + sips
  grab-image-linux.sh    # Linux: xclip or wl-paste + optional ImageMagick
  grab-image-win.ps1     # Windows: PowerShell + optional ImageMagick
```

## Entry Script — `grab-image.sh`

- Accepts `SAVE_DIR` as first argument (defaults to `/tmp`)
- Detects platform via `uname -s`:
  - `Darwin` → `grab-image-darwin.sh "$SAVE_DIR"`
  - `Linux` → `grab-image-linux.sh "$SAVE_DIR"`
  - `MINGW*|MSYS*|CYGWIN*` → `powershell.exe -File grab-image-win.ps1 "$SAVE_DIR"`
- Unknown platform → `{"success":false,"error":"Unsupported platform"}`

## Platform Scripts

All scripts share the same contract:

- **Input:** `SAVE_DIR` (directory path)
- **Output:** JSON to stdout
  - Success: `{"success":true,"path":"/path/to/image.png"}`
  - Failure: `{"success":false,"error":"error message"}`
- **Filename:** `claude-paste-YYYYMMDD-HHMMSS.png`

### macOS (`grab-image-darwin.sh`)

Extracted from current `grab-image.sh`, no logic changes:

1. Check clipboard via `osascript -e 'clipboard info'` for `PNGf` or `TIFF`
2. Export as PNG via `osascript`
3. Resize with `sips --resampleWidth 1920` if width > 1920px

### Linux (`grab-image-linux.sh`)

1. Detect display server:
   - If `$WAYLAND_DISPLAY` is set → use `wl-paste`
   - Otherwise → use `xclip`
2. Check tool is installed, error if not
3. Extract clipboard image:
   - Wayland: `wl-paste --type image/png > "$FILEPATH"`
   - X11: `xclip -selection clipboard -t image/png -o > "$FILEPATH"`
4. Resize with `convert` (ImageMagick) if installed and width > 1920px, skip otherwise

### Windows (`grab-image-win.ps1`)

1. Use `Get-Clipboard -Format Image` to check for image
2. Save as PNG via `System.Drawing.Bitmap.Save()`
3. Resize with `convert` (ImageMagick) if installed and width > 1920px, skip otherwise

## Resize Logic

| Platform | Tool | Required? |
|----------|------|-----------|
| macOS | `sips` | Always available (system built-in) |
| Linux | `convert` (ImageMagick) | Optional, skip if not installed |
| Windows | `convert` (ImageMagick) | Optional, skip if not installed |

Resize threshold: 1920px width. Only applied when image exceeds this width.

## Changes to Existing Files

- `grab-image.sh` — rewrite as platform dispatcher (existing macOS logic moves to `grab-image-darwin.sh`)
- `commands/paste.md` — no changes needed
- `README.md` — update Platform Support section

## Error Messages

All error messages in English:
- No image in clipboard: `"No image found in clipboard"`
- Missing tool: `"Required tool not found: xclip"` / `"Required tool not found: wl-paste"`
- Export failure: `"Failed to export clipboard image"`
- Unsupported platform: `"Unsupported platform: <uname>"`
