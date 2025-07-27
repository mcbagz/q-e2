@echo off
REM Development build script for Quantum ESPRESSO Web UI (Windows)
REM This version runs the backend and frontend directly without Docker

echo === Quantum ESPRESSO Web UI Development Setup ===
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed. Please install Python 3.8 or later.
    exit /b 1
)

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed. Please install Node.js 16 or later.
    exit /b 1
)

REM Set up backend
echo [INFO] Setting up backend...
cd backend

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv venv
)

REM Activate virtual environment and install dependencies
echo [INFO] Installing backend dependencies...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt

REM Create .env file if it doesn't exist
if not exist ".env" (
    echo [INFO] Creating .env file...
    (
        echo QE_BIN_PATH=../../build/bin
        echo QE_PSEUDO_PATH=../../pseudo
        echo DATABASE_URL=sqlite:///./simulations.db
        echo CORS_ORIGINS=http://localhost:3000
    ) > .env
)

echo [SUCCESS] Backend setup complete!
echo.

REM Set up frontend
echo [INFO] Setting up frontend...
cd ..\frontend

REM Install dependencies
echo [INFO] Installing frontend dependencies...
call npm install

echo [SUCCESS] Frontend setup complete!
echo.

echo === Development servers ready to start ===
echo.
echo To run the development servers:
echo.
echo 1. Backend (in a new terminal):
echo    cd web-ui\backend
echo    venv\Scripts\activate
echo    python run.py
echo.
echo 2. Frontend (in another terminal):
echo    cd web-ui\frontend
echo    npm run dev
echo.
echo Then access the application at http://localhost:3000
echo.

pause