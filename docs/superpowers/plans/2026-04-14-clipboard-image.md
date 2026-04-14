# clipboard-image Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that lets users paste clipboard images and drag image files into the CLI for debugging and code recognition.

**Architecture:** A `.claude-plugin` with a shell script for clipboard extraction, a slash command for user invocation, and a prompt hook for drag-and-drop detection. No external dependencies — macOS `osascript` only.

**Tech Stack:** Bash (shell script), Markdown (commands/hooks), JSON (plugin manifest, hook config)

---

## File Structure

| File | Responsibility |
|------|---------------|
| `.claude-plugin/plugin.json` | Plugin manifest — name, version, description |
| `scripts/grab-image.sh` | Core logic — detect clipboard image, export as PNG, output JSON |
| `commands/paste.md` | `/paste` slash command — parse args, call script, read image |
| `hooks/hooks.json` | Hook config — detect dragged image paths in user input |
| `README.md` | Usage documentation |

---

### Task 1: Plugin Manifest

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Create plugin manifest**

```json
{
  "name": "clipboard-image",
  "description": "Paste images from clipboard or drag image files into Claude Code CLI",
  "version": "0.1.0",
  "author": {
    "name": "emcow"
  },
  "keywords": ["clipboard", "image", "paste", "screenshot"]
}
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cat .claude-plugin/plugin.json | python3 -m json.tool`
Expected: Pretty-printed JSON output with no errors

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add plugin manifest"
```

---

### Task 2: Clipboard Image Extraction Script

**Files:**
- Create: `scripts/grab-image.sh`

- [ ] **Step 1: Write the script**

```bash
#!/bin/bash
# Extracts image from macOS clipboard and saves as PNG.
# Usage: grab-image.sh [save_directory]
# Output: JSON to stdout — {"success":true,"path":"..."} or {"success":false,"error":"..."}

SAVE_DIR="${1:-/tmp}"
FILENAME="claude-paste-$(date +%Y%m%d-%H%M%S).png"
FILEPATH="${SAVE_DIR}/${FILENAME}"

# Check if clipboard contains image data
has_image=$(osascript -e 'clipboard info' 2>/dev/null | grep -c 'PNGf\|TIFF')

if [ "$has_image" -eq 0 ]; then
  echo '{"success":false,"error":"剪贴板中没有图片"}'
  exit 1
fi

# Ensure save directory exists
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
  echo "{\"success\":true,\"path\":\"${FILEPATH}\"}"
else
  echo '{"success":false,"error":"图片导出失败"}'
  exit 1
fi
```

- [ ] **Step 2: Make script executable**

Run: `chmod +x scripts/grab-image.sh`

- [ ] **Step 3: Test with no image in clipboard**

First clear clipboard to text:
Run: `echo "test" | pbcopy`
Run: `bash scripts/grab-image.sh`
Expected: `{"success":false,"error":"剪贴板中没有图片"}` and exit code 1

- [ ] **Step 4: Test with image in clipboard**

Copy a screenshot to clipboard (Cmd+Ctrl+Shift+4 to capture a region), then:
Run: `bash scripts/grab-image.sh`
Expected: `{"success":true,"path":"/tmp/claude-paste-XXXXXXXX-XXXXXX.png"}` and the file exists

- [ ] **Step 5: Test with custom save directory**

Run: `bash scripts/grab-image.sh /tmp/test-clipboard`
Expected: File saved under `/tmp/test-clipboard/`, directory auto-created

- [ ] **Step 6: Commit**

```bash
git add scripts/grab-image.sh
git commit -m "feat: add clipboard image extraction script"
```

---

### Task 3: Slash Command

**Files:**
- Create: `commands/paste.md`

- [ ] **Step 1: Write the slash command**

```markdown
---
description: Paste image from clipboard into conversation
argument-hint: [--save <directory>]
allowed-tools: Bash, Read
---

The user wants to paste an image from their clipboard. Follow these steps exactly:

1. **Parse arguments:** Check if the user provided `--save <directory>`. If yes, use that directory as SAVE_DIR. If no, use `/tmp` as SAVE_DIR.

2. **Extract image from clipboard:** Run this command:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/grab-image.sh "SAVE_DIR"
   ```
   Replace SAVE_DIR with the actual directory path.

3. **Handle the result:**
   - If the output contains `"success":true`, extract the `path` value from the JSON output.
   - If the output contains `"success":false`, tell the user the error message from the JSON and stop.

4. **Read the image:** Use the Read tool to read the image file at the extracted path.

5. **Confirm receipt:** Tell the user: "已接收图片：<file_path>"

6. **Wait:** Do not analyze the image. Wait for the user's next instruction.
```

- [ ] **Step 2: Test the command**

In Claude Code CLI, run `/paste` with an image in the clipboard.
Expected: Claude executes the script, reads the image, and confirms "已接收图片：/tmp/claude-paste-*.png"

- [ ] **Step 3: Test with --save flag**

Run: `/paste --save ./screenshots`
Expected: Image saved to `./screenshots/` directory

- [ ] **Step 4: Test with empty clipboard**

Clear clipboard to text (`echo "test" | pbcopy`), then run `/paste`.
Expected: Claude reports "剪贴板中没有图片"

- [ ] **Step 5: Commit**

```bash
git add commands/paste.md
git commit -m "feat: add /paste slash command"
```

---

### Task 4: Drag-and-Drop Hook

**Files:**
- Create: `hooks/hooks.json`

- [ ] **Step 1: Write the hook configuration**

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if the user's input contains a file path ending in .png, .jpg, .jpeg, .gif, .webp, or .bmp (case-insensitive). The path may be absolute or relative, and may be surrounded by whitespace or quotes. If you find an image file path, respond with: {\"decision\": \"approve\", \"reason\": \"Image file path detected\", \"systemMessage\": \"The user's message contains an image file path. Use the Read tool to read the image file, then confirm to the user: 已接收图片：<file_path>. Do not analyze the image until the user asks.\"}. If you do NOT find any image file path, respond with: {\"decision\": \"approve\", \"reason\": \"No image path detected\"}."
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cat hooks/hooks.json | python3 -m json.tool`
Expected: Pretty-printed JSON with no errors

- [ ] **Step 3: Test hook (requires restart)**

Restart Claude Code to load the new hook. Then type or drag a path like `/tmp/test.png` into the prompt.
Expected: Claude automatically reads the image and confirms receipt.

- [ ] **Step 4: Test non-image input**

Type a normal message without any image path.
Expected: No interference — Claude responds normally.

- [ ] **Step 5: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: add drag-and-drop image detection hook"
```

---

### Task 5: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README**

```markdown
# clipboard-image

A Claude Code plugin for pasting clipboard images and dragging image files into the CLI.

## Install

```bash
/install-plugin /path/to/clipboard-image
```

## Usage

### Paste from clipboard

1. Copy an image (screenshot, browser image, etc.)
2. In Claude Code, type:

```
/paste
```

To save to a specific directory:

```
/paste --save ./screenshots
```

### Drag and drop

Drag any image file (.png, .jpg, .gif, .webp, .bmp) into the terminal. The plugin automatically detects and reads it.

## Platform Support

- **macOS** — supported (uses osascript)
- **Linux** — not yet supported
- **Windows** — not yet supported

## Requirements

- macOS
- Claude Code CLI
- No external dependencies
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 6: End-to-End Verification

- [ ] **Step 1: Verify plugin structure**

Run: `find . -not -path './.git/*' -not -path './.git' -not -path './docs/*' | sort`
Expected:
```
.
./.claude-plugin
./.claude-plugin/plugin.json
./commands
./commands/paste.md
./hooks
./hooks/hooks.json
./README.md
./scripts
./scripts/grab-image.sh
```

- [ ] **Step 2: Install plugin locally**

Run: `/install-plugin /Users/emcow/Desktop/code-space/claude/clipboard-image`
Expected: Plugin installed successfully

- [ ] **Step 3: Restart Claude Code and test /paste**

Copy a screenshot to clipboard, restart Claude Code, run `/paste`.
Expected: Image received and confirmed.

- [ ] **Step 4: Test drag-and-drop**

Drag an image file into the terminal.
Expected: Hook detects path, Claude reads and confirms.

- [ ] **Step 5: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: adjustments from end-to-end testing"
```
