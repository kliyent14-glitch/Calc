@echo off
setlocal
set "SCRIPT=%~dp0calculator.ps1"

if not exist "%SCRIPT%" (
  echo Ошибка: файл calculator.ps1 не найден рядом с запускателем.
  echo Скачайте весь репозиторий Calc целиком, а не один файл.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 (
  echo.
  echo Калькулятор не запустился. Текст ошибки показан выше.
  pause
)
