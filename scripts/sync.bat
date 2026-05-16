@echo off
REM Quick sync shortcut - uses the Node.js script
node "%~dp0sync-config.js" %*
if errorlevel 1 exit /b %errorlevel%
