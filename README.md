# clipboard-image

A Claude Code plugin for pasting clipboard images into conversations.

## Install

```bash
claude --plugin-dir /path/to/clipboard-image
```

## Usage

Copy an image to your clipboard (screenshot, browser image, etc.), then in Claude Code:

**Paste with a prompt:**

```
/clipboard-image:paste What bugs do you see in this screenshot?
```

**Paste without a prompt:**

```
/clipboard-image:paste
```

**Save to a specific directory:**

```
/clipboard-image:paste --save ./screenshots Analyze this architecture diagram
```

## Features

- Extract images directly from macOS clipboard
- Ask questions about images in a single interaction
- Auto-resize large screenshots (>1920px) for faster processing
- Save images to a custom directory with `--save`

## Platform Support

- **macOS** — supported (uses osascript + sips)
- **Linux** — not yet supported
- **Windows** — not yet supported

## Requirements

- macOS
- Claude Code CLI
