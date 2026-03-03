Build and test the game as a web export using Claude Code's preview tools.

## Step 1: Build

Run the bash build script (uses Godot headless export):

```bash
bash ".agent/scripts/build-web.sh"
```

If the build fails with "Export templates missing", the user must open the Godot
Editor and go to Editor → Manage Export Templates → Download 4.6.stable.

## Step 2: Start Preview Server

Use `preview_start` with the "web-game" configuration. This runs serve.py which
adds the COOP/COEP headers required for Godot's SharedArrayBuffer.

## Step 3: Verify

Use `preview_screenshot` to capture the initial state.

Wait a few seconds for the game to load, then take another screenshot.

What to look for:
- Loading bar progressing → game is loading (expected)
- Game canvas showing the outdoor scene → success
- Black screen + browser errors → investigate with `preview_console_logs`
- "Click to focus" message → normal, game canvas needs focus to accept input

Use `preview_console_logs` to check for errors. Common Godot web errors:
- `SharedArrayBuffer is not defined` → COOP/COEP headers missing (should not happen with serve.py)
- `Failed to load resource` → missing export or path issue
- `RangeError: Out of memory` → increase browser memory

## Step 4: Report

Summarize what the screenshot shows. Include any console errors from
`preview_console_logs`. If the game loaded successfully, confirm the test passed.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build fails — Godot not found | Check path in `.agent/scripts/build-web.sh`; update or set `GODOT_PATH` |
| Build fails — export templates missing | Godot Editor → Manage Export Templates → Download 4.6.stable |
| preview_start fails | Check that `exports/web/index.html` exists (build must succeed first) |
| Black screen | Run `preview_console_logs` and report errors |
| Game loads but controls don't respond | Normal — browser game canvas needs a click to receive keyboard input |
