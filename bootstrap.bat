@echo off
setlocal enabledelayedexpansion

echo ====================================
echo    Flux Kontext Installer for Forge
echo ====================================
echo.

REM Check if help is requested
if /i "%~1"=="--help" (
    echo Usage: %~nx0 [--help]
    echo.
    echo Options:
    echo   --help    Show this help message
    echo.
    echo Examples:
    echo   %~nx0           # Normal installation
    echo.
    pause
    exit /b 0
)

REM Check if we're in the correct directory
if not exist "%~dp0bootstrap.sh" (
    echo ❌ Error: bootstrap.sh not found in this directory.
    echo Please make sure you're running this file from inside the flux-kontext-for-forge folder.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0assets.json" (
    echo ❌ Error: assets.json not found in this directory.
    echo Please make sure you're running this file from inside the flux-kontext-for-forge folder.
    echo.
    pause
    exit /b 1
)

REM Try to find Git Bash
set "BASH_PATH="
set "GIT_BASH_PATH="

REM Check common Git Bash locations
for %%P in (
    "C:\Program Files\Git\bin\bash.exe"
    "C:\Program Files (x86)\Git\bin\bash.exe"
    "C:\Git\bin\bash.exe"
    "%PROGRAMFILES%\Git\bin\bash.exe"
    "%PROGRAMFILES(X86)%\Git\bin\bash.exe"
    "%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
) do (
    if exist "%%~P" (
        set "BASH_PATH=%%~P"
        set "GIT_BASH_PATH=%%~P"
        goto :found_bash
    )
)

REM Try to find bash in PATH
for /f "tokens=*" %%i in ('where bash 2^>nul') do (
    set "BASH_PATH=%%i"
    goto :found_bash
)

REM If bash not found, show error and instructions
echo ❌ Git Bash not found on your system.
echo.
echo To fix this:
echo 1. Install Git for Windows from: https://git-scm.com/download/win
echo 2. Make sure to check "Use Git and optional Unix tools from Command Prompt" during installation
echo 3. Restart Command Prompt after installation
echo 4. Run this script again
echo.
echo Alternative: Right-click in this folder and select "Git Bash Here", then run: bash bootstrap.sh
echo.
pause
exit /b 1

:found_bash
echo ✅ Found Git Bash at: %BASH_PATH%
echo 📦 Starting installation...
echo.

REM Run the bootstrap script
"%BASH_PATH%" "%~dp0bootstrap.sh"

REM Bootstrap script completed - exit code handling is done by bootstrap.sh

echo.
echo Press any key to close this window...
pause >nul 