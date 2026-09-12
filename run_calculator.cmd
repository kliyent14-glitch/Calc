@echo off
start "Calculator" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0calculator.ps1"
