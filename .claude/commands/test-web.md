Build and test the game as a web export.

## Build

Run the PowerShell build script:

```powershell
& ".agent/scripts/build-web.ps1"
```

If the script is not available, run directly:

```powershell
& "d:\Godot Project\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe" --headless --export-debug "Web" exports/web/index.html
```

## Serve Locally

```powershell
Push-Location exports/web
python -m http.server 8080
```

Open http://localhost:8080

## Verification Checklist

| Check | How to Test |
|-------|-------------|
| Game loads | Wait for loading bar |
| Player moves | WASD keys |
| Time advances | Watch clock HUD |
| Interactions | Press E near NPCs |

## First-Time Setup

If web export templates are not installed:
1. Open Godot Editor
2. Editor -> Manage Export Templates
3. Download and Install for 4.6.stable

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Export templates missing" | Editor -> Manage Export Templates -> Download |
| Black screen | Check browser console (F12) for errors |
| Controls don't respond | Click on game canvas to focus |
| Python not found | Ensure `python` path is correct |
