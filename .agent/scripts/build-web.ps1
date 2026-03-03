# Build Web Export Script (Debug Mode - Fast)
# Usage: .\.agent\scripts\build-web.ps1

$GodotPath = "d:\Godot Project\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64_console.exe"
$PythonPath = "C:\Users\ushar\AppData\Local\Microsoft\WindowsApps\python.exe"
$ProjectPath = $PSScriptRoot | Split-Path | Split-Path
$ExportPath = Join-Path $ProjectPath "exports\web\index.html"

if (-not (Test-Path $PythonPath)) {
    Write-Warning "Python not found at $PythonPath. Trying 'python' from PATH..."
    $PythonPath = "python"
}

Write-Host "Building web export (debug mode)..." -ForegroundColor Cyan

Push-Location $ProjectPath
& $GodotPath --headless --export-debug "Web" $ExportPath
$BuildResult = $LASTEXITCODE
Pop-Location

if ($BuildResult -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host "Starting server at http://localhost:8080" -ForegroundColor Cyan
    Push-Location (Join-Path $ProjectPath "exports\web")
    & $PythonPath -m http.server 8080
} else {
    Write-Host "Build failed with exit code $BuildResult" -ForegroundColor Red
}
