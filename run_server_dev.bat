@echo off
REM Quick-start script for local dev on Windows
REM - Exposes OTP in responses for easy testing
REM - Uses local MongoDB on 127.0.0.1:27017/resume_builder
REM - Starts the Node.js API on port 3000 by default, or a port you pass as arg 1

setlocal

REM Allow override if already set in environment
if "%MONGODB_URI%"=="" set "MONGODB_URI=mongodb://127.0.0.1:27017/resume_builder"
if "%EXPOSE_OTP%"=="" set "EXPOSE_OTP=true"

REM Accept first argument as port override; otherwise default to 3000
if not "%~1"=="" (
	set "PORT=%~1"
) else (
	if "%PORT%"=="" set "PORT=3000"
)

echo Starting Resume Builder API with:
echo   PORT=%PORT%
echo   MONGODB_URI=%MONGODB_URI%
echo   EXPOSE_OTP=%EXPOSE_OTP%
echo.

node server.js
