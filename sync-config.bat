@echo off
REM sync-config.bat - Safely commit and push mofacts_config without exposing API keys
REM Usage: sync-config.bat "Optional commit message"

setlocal enabledelayedexpansion

set "COMMIT_MSG=%~1"
if "%COMMIT_MSG%"=="" set "COMMIT_MSG=Update configuration files"

echo.
echo [92m Starting safe config sync...[0m
echo.

REM Create backup directory with timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BACKUP_DIR=.key_backups_%datetime:~0,14%

echo [96m Creating backup directory: %BACKUP_DIR%[0m
mkdir "%BACKUP_DIR%" 2>nul

REM Backup all JSON files
echo [96m Backing up JSON files...[0m
for /r %%f in (*.json) do (
    set "filepath=%%f"
    set "relpath=!filepath:%CD%\=!"
    echo   [92m Backing up: !relpath![0m

    REM Create subdirectory structure in backup
    for %%p in ("%%f") do set "dirname=%%~dpf"
    set "backupdir=!dirname:%CD%=%BACKUP_DIR%!"
    mkdir "!backupdir!" 2>nul

    copy "%%f" "%BACKUP_DIR%\!relpath!" >nul
)

REM Strip keys using PowerShell for better text processing
echo [96m Stripping API keys from JSON files...[0m
for /r %%f in (*.json) do (
    set "filepath=%%f"
    set "relpath=!filepath:%CD%\=!"
    echo   [93m Processing: !relpath![0m

    powershell -Command "(Get-Content '%%f' -Raw) -replace '\"speechAPIKey\": \"[^\"]*\"', '\"speechAPIKey\": \"YOUR_GOOGLE_SPEECH_API_KEY\"' -replace '\"textToSpeechAPIKey\": \"[^\"]*\"', '\"textToSpeechAPIKey\": \"YOUR_GOOGLE_TTS_API_KEY\"' | Set-Content '%%f' -NoNewline"
)

echo [96m Staging all changes...[0m
git add -A

echo [96m Committing changes...[0m
git commit -m "%COMMIT_MSG%"
if errorlevel 1 echo [93m No changes to commit[0m

echo [96m Pushing to remote...[0m
git push

echo [96m Restoring original files with keys...[0m
for /r "%BACKUP_DIR%" %%f in (*.json) do (
    set "filepath=%%f"
    set "relpath=!filepath:%BACKUP_DIR%\=!"
    echo   [92m Restoring: !relpath![0m
    copy "%%f" "!relpath!" >nul
)

echo [96m Cleaning up backup directory...[0m
rmdir /s /q "%BACKUP_DIR%"

echo.
echo [92m Done! Configuration pushed without keys, and keys restored locally.[0m
echo [96m Commit message: %COMMIT_MSG%[0m
echo.

endlocal
