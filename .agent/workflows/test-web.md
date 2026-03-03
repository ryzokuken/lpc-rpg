---
description: Build to web and test the game in browser
migrated: .claude/commands/test-web.md
---

> **Migrated to `.claude/commands/test-web.md`.** Use `/test-web` in Claude Code.

// turbo-all

# Testing Workflow

## First-Time Setup (Required Once)

> [!IMPORTANT]
> Web export templates must be installed before building. This is a one-time step.

1. Open Godot Editor (not headless)
2. Go to **Editor → Manage Export Templates**
3. Click **Download and Install** for version 4.6.stable
4. Wait for download to complete (~500MB)

## Quick Test (Copy-Paste Ready)

```powershell
& "d:\Godot Project\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe" --headless --export-debug "Web" exports/web/index.html; if ($?) { Push-Location exports/web; & "C:\Users\ushar\AppData\Local\Microsoft\WindowsApps\python.exe" -m http.server 8080 }
```

Then open http://localhost:8080 in browser.

---

## Step-by-Step Flow

### Step 1: Build Web Export (Debug Mode)

```powershell
& "d:\Godot Project\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe" --headless --export-debug "Web" exports/web/index.html
```

> Uses `--export-debug` for faster builds and better error messages.
> For release builds, use `--export-release` instead.

### Step 2: Start Local Server

```powershell
Push-Location exports/web; & "C:\Users\ushar\AppData\Local\Microsoft\WindowsApps\python.exe" -m http.server 8080
```

### Step 3: Test in Browser

Open http://localhost:8080 and verify:

| Check | How to Test |
|-------|-------------|
| Game loads | Wait for loading bar |
| Player moves | WASD keys |
| Time advances | Watch clock HUD |
| Interactions | Press E near NPCs |

### Step 4: Stop Server

Press Ctrl+C in the terminal running the server.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Export templates missing" | Editor → Manage Export Templates → Download |
| Black screen | Check browser console (F12) for errors |
| Controls don't respond | Click on game canvas to focus |
| Python not found | Ensure `python` path is correct in scripts |
