@echo off
setlocal
set "SCRIPT=%~dp0calculator.ps1"

if not exist "%SCRIPT%" (
  echo Error: calculator.ps1 was not found next to this launcher.
  echo Download or copy the full Calc folder, not only this launcher.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 (
  echo.
  echo Calculator did not start. The error text is shown above.
  pause
)
