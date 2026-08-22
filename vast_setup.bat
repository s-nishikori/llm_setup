@echo off
setlocal

set "VAST_HOST=192.220.55.116"
set "VAST_PORT=21294"
set "VAST_USER=root"
set "LOCAL_PORT=8080"
set "REMOTE_PORT=8080"
set "SETUP_SCRIPT=setup_vast.sh"

cd /d "%~dp0"

echo [1/2] Uploading %SETUP_SCRIPT% to Vast.ai...
scp -P %VAST_PORT% "%SETUP_SCRIPT%" %VAST_USER%@%VAST_HOST%:/tmp/setup_vast.sh
if errorlevel 1 (
    echo Upload failed.
    exit /b 1
)

echo [2/2] Cloning or updating the repository...
echo Port forwarding: http://localhost:%LOCAL_PORT%
ssh -t -p %VAST_PORT% -L %LOCAL_PORT%:localhost:%REMOTE_PORT% %VAST_USER%@%VAST_HOST% "bash /tmp/setup_vast.sh && cd /workspace/llm_setup && exec bash -l"

endlocal

