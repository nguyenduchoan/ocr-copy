@echo off
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0ocr-copy.ps1" %*
exit /b %errorlevel%
