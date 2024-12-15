@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File ".\2、run_gui.ps1"
pause
