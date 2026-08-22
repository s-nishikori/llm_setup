@echo off
setlocal
cd /d "%~dp0"

if exist ".venv\Scripts\python.exe" (
    set "PYTHON=.venv\Scripts\python.exe"
) else (
    set "PYTHON=python"
)

%PYTHON% chat.py
if errorlevel 1 (
    echo.
    echo If a Python package is missing, run: python -m pip install -r requirements.txt
    echo Also make sure connect.bat is running and .env contains the correct API key.
)

pause
endlocal
