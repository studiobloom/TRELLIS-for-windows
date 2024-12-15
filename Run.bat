chcp 65001 >nul
start cmd /k "cd .venv && cloudflared tunnel --url http://localhost:7860"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\2、run_gui.ps1"
pause
