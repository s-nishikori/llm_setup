@echo off
setlocal

rem Defaults can be overridden with VAST_HOST, VAST_PORT, VAST_USER,
rem LOCAL_PORT, and REMOTE_PORT environment variables.
if not defined VAST_HOST set "VAST_HOST=192.220.55.116"
if not defined VAST_PORT set "VAST_PORT=21294"
if not defined VAST_USER set "VAST_USER=root"
if not defined LOCAL_PORT set "LOCAL_PORT=8000"
if not defined REMOTE_PORT set "REMOTE_PORT=8000"

echo Opening SSH tunnel to %VAST_USER%@%VAST_HOST%...
echo vLLM endpoint: http://localhost:%LOCAL_PORT%/v1
echo Keep this window open. Press Ctrl+C to disconnect.
echo.

ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 ^
  -L %LOCAL_PORT%:localhost:%REMOTE_PORT% ^
  -p %VAST_PORT% %VAST_USER%@%VAST_HOST%

if errorlevel 1 (
    echo.
    echo SSH tunnel could not be opened.
    pause
    exit /b 1
)

endlocal
