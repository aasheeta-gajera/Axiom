@echo off
echo 🚀 Starting Axiom Backend Server...

REM Check if node_modules exists
if not exist "node_modules" (
    echo 📦 Installing dependencies...
    npm install
)

REM Start the server
echo 🔥 Starting server on port 5000...
npm run dev

pause
