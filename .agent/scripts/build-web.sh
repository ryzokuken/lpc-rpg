#!/usr/bin/env bash
# Build the Godot project to a web export (debug mode).
# Usage: bash .agent/scripts/build-web.sh
#
# Override the Godot executable path with the GODOT_PATH env var if needed:
#   GODOT_PATH=/path/to/godot bash .agent/scripts/build-web.sh
set -euo pipefail

GODOT="${GODOT_PATH:-/e/Godot Project/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXPORT_DIR="$PROJECT_DIR/exports/web"
EXPORT_PATH="$EXPORT_DIR/index.html"

if [[ ! -f "$GODOT" ]]; then
    echo "error: Godot not found at: $GODOT"
    echo "set GODOT_PATH to override, or update the path in this script."
    exit 1
fi

mkdir -p "$EXPORT_DIR"

echo "building web export (debug mode)..."
cd "$PROJECT_DIR"
"$GODOT" --headless --export-debug "Web" "$EXPORT_PATH"

echo "build complete: $EXPORT_PATH"
echo "start server: python .agent/scripts/serve.py"
