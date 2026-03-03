#!/usr/bin/env bash
# Validate all GDScript files for syntax and type errors without building.
# Uses Godot's --check-only flag, which exits after script validation.
# Usage: bash .agent/scripts/check.sh
#
# Override the Godot executable path with the GODOT_PATH env var if needed.
set -euo pipefail

GODOT="${GODOT_PATH:-/e/Godot Project/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ ! -f "$GODOT" ]]; then
    echo "error: Godot not found at: $GODOT"
    echo "set GODOT_PATH to override, or update the path in this script."
    exit 1
fi

cd "$PROJECT_DIR"
echo "checking GDScript files..."

set +e
output=$("$GODOT" --headless --check-only 2>&1)
exit_code=$?
set -e

echo "$output"

# Godot exits 0 on success. Non-zero means script errors were found.
if [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "errors found — fix the issues above and run again."
    exit 1
fi

echo ""
echo "all GDScript files OK."
