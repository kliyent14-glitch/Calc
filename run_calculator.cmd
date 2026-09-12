@echo off
setlocal
set "SCRIPT=%~dp0calculator.ps1"

if not exist "%SCRIPT%" (
  echo Error: calculator.ps1 was not found next to this launcher.
  echo Keep run_calculator.cmd and calculator.ps1 in the same folder.
  pause
  exit /b 1
)

start "Calculator" powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%SCRIPT%"
