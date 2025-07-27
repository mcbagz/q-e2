@echo off
REM Quantum ESPRESSO Web UI - Build and Run Script for Windows

echo === Quantum ESPRESSO Web UI Builder ===
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose is not installed. Please install Docker Compose first.
    exit /b 1
)

REM Parse command line arguments
set MODE=dev
set BUILD_ONLY=false
set COMPOSE_FILE=docker-compose.yml

:parse_args
if "%1"=="" goto :end_parse
if "%1"=="--prod" (
    set MODE=prod
    set COMPOSE_FILE=docker-compose.prod.yml
    echo [INFO] Using production configuration
)
if "%1"=="--build-only" (
    set BUILD_ONLY=true
)
if "%1"=="--help" (
    echo Usage: %0 [OPTIONS]
    echo Options:
    echo   --prod       Build and run production configuration
    echo   --build-only Only build containers without starting them
    echo   --help       Show this help message
    exit /b 0
)
shift
goto :parse_args
:end_parse

REM Create necessary directories
echo [INFO] Creating necessary directories...
if not exist "data" mkdir data
if not exist "simulations" mkdir simulations
if not exist "logs" mkdir logs

REM Build containers
echo [INFO] Building Docker containers...
docker-compose -f %COMPOSE_FILE% build
if %errorlevel% neq 0 (
    echo [ERROR] Failed to build containers
    exit /b 1
)

if "%BUILD_ONLY%"=="true" (
    echo [SUCCESS] Containers built successfully!
    exit /b 0
)

REM Stop any existing containers
echo [INFO] Stopping any existing containers...
docker-compose -f %COMPOSE_FILE% down

REM Start containers
echo [INFO] Starting containers...
docker-compose -f %COMPOSE_FILE% up -d
if %errorlevel% neq 0 (
    echo [ERROR] Failed to start containers
    exit /b 1
)

REM Wait for services to be ready
echo [INFO] Waiting for services to be ready...
timeout /t 5 /nobreak >nul

REM Check if services are running
docker-compose -f %COMPOSE_FILE% ps | findstr "Up" >nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Services are running!
    echo.
    echo Access the application at:
    echo   - Web UI: http://localhost
    echo   - API Docs: http://localhost:8000/docs
    echo.
    echo To view logs:
    echo   - All services: docker-compose -f %COMPOSE_FILE% logs -f
    echo   - Backend only: docker-compose -f %COMPOSE_FILE% logs -f backend
    echo   - Frontend only: docker-compose -f %COMPOSE_FILE% logs -f frontend
    echo.
    echo To stop services:
    echo   - docker-compose -f %COMPOSE_FILE% down
) else (
    echo [ERROR] Services failed to start. Check logs with: docker-compose -f %COMPOSE_FILE% logs
    exit /b 1
)