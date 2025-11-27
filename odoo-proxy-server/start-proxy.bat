@echo off
echo ========================================
echo   Odoo Proxy Server - Quick Start
echo ========================================
echo.

echo Checking Node.js installation...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js is installed!
echo.

echo Checking if dependencies are installed...
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies!
        pause
        exit /b 1
    )
)

echo.
echo Starting Odoo Proxy Server...
echo.
echo The server will be available at: http://localhost:3000
echo Proxy endpoint: http://localhost:3000/api/odoo
echo.
echo Press Ctrl+C to stop the server
echo.

call npm start

pause


