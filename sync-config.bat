@echo off
REM sync-config.bat - Wrapper around the Node implementation
REM Usage: sync-config.bat "Optional commit message"

node "%~dp0sync-config.js" %*
if errorlevel 1 exit /b %errorlevel%
