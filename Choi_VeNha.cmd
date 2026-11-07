@echo off
setlocal
cd /d "%~dp0"
if exist "build\VeNha.exe" (
  start "" "build\VeNha.exe"
  exit /b
)
if exist "tools\godot\Godot_v4.7.2-stable_win64.exe" (
  start "" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
  exit /b
)
echo Khong tim thay Godot. Mo project.godot bang Godot 4.7.2.
pause
