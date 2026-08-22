@echo off
setlocal
cd /d "%~dp0"

if exist ".venv\Scripts\python.exe" (
    set "PYTHON=.venv\Scripts\python.exe"
) else (
    set "PYTHON=python"
)

echo Checking http://localhost:8000/v1 ...
%PYTHON% chat.py --status
if errorlevel 1 (
    echo.
    echo Connection failed. Check that vLLM and connect.bat are running,
    echo and that VLLM_API_KEY in .env matches the Vast.ai server.
)

pause
endlocal
