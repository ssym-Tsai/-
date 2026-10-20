@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0plugins\default-browser\skills\default-browser\scripts\Set-CodexLinkTarget.ps1" -Action Restore
pause
