---
description: Paste image from clipboard into conversation
argument-hint: [--save <directory>] [prompt]
allowed-tools: Bash, Read
---

The user wants to paste an image from their clipboard. The user provided: $ARGUMENTS

Follow these steps exactly:

1. **Parse arguments:** From the text above, check if the user provided `--save <directory>`. If yes, use that directory as SAVE_DIR. If no, use `/tmp` as SAVE_DIR. Any remaining text after the flags is the user's PROMPT.

2. **Extract image from clipboard:** Run this command:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/grab-image.sh "SAVE_DIR"
   ```
   Replace SAVE_DIR with the actual directory path.

3. **Handle the result:**
   - If the output contains `"success":true`, extract the `path` value from the JSON output.
   - If the output contains `"success":false`, tell the user the error message from the JSON and stop.

4. **Read the image:** Use the Read tool to read the image file at the extracted path.

5. **Respond:**
   - If the user provided a PROMPT, respond to their prompt based on the image content.
   - If no PROMPT was provided, tell the user "已接收图片：<file_path>" and wait for further instructions.
