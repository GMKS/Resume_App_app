@echo off
setlocal
cd /d %~dp0

rem Optional: install deps if missing
if not exist node_modules (
echo Installing dependencies...
npm install
)

rem Set env vars for this run
set MONGODB_URI=mongodb://127.0.0.1:27017/resume_builder
set PORT=3000

rem Try to start MongoDB service if present (ignore errors)
echo Ensuring MongoDB service is running...
sc query MongoDB | find "RUNNING" >nul || net start MongoDB >nul 2>&1

echo Starting API on port %PORT% ...
npm start

endlocal
pause