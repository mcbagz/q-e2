@echo off
REM Test script to verify QE Web UI setup

echo === Testing Quantum ESPRESSO Web UI Setup ===
echo.

REM Check if QE binaries exist
echo [INFO] Checking for QE binaries...
if exist "..\build\bin\pw.x" (
    echo [SUCCESS] Found pw.x
) else (
    echo [ERROR] pw.x not found in ..\build\bin\
    echo Please ensure Quantum ESPRESSO is built first.
    exit /b 1
)

if exist "..\build\bin\pp.x" (
    echo [SUCCESS] Found pp.x
) else (
    echo [ERROR] pp.x not found in ..\build\bin\
    echo Please ensure Quantum ESPRESSO is built first.
    exit /b 1
)

REM Check for pseudopotentials
echo.
echo [INFO] Checking for pseudopotentials...
if exist "..\pseudo\*.UPF" (
    echo [SUCCESS] Found UPF pseudopotential files
) else if exist "..\pseudo\*.upf" (
    echo [SUCCESS] Found upf pseudopotential files
) else (
    echo [WARNING] No pseudopotential files found in ..\pseudo\
    echo Some functionality may be limited.
)

REM Check Docker
echo.
echo [INFO] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Docker is installed
    docker-compose --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [SUCCESS] Docker Compose is installed
    ) else (
        echo [WARNING] Docker Compose not found
    )
) else (
    echo [WARNING] Docker not found - use development mode instead
)

echo.
echo === Setup verification complete ===
echo.
echo To run the web UI:
echo   1. With Docker: build-and-run.bat
echo   2. Without Docker: build-dev.bat
echo.
pause