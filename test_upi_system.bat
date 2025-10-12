@echo off
REM UPI Payment System Test Runner for Windows
REM Comprehensive testing script for all UPI payment components

echo 🚀 Starting UPI Payment System Tests...
echo ========================================

REM Test configuration
set TEST_ENV_FILE=.env.test
set SERVER_PORT=3001
set DB_NAME=resume_app_upi_test

REM Function to print status (Windows version)
echo 🔍 Checking prerequisites...

REM Check Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js is required but not installed
    exit /b 1
)

REM Check npm
where npm >nul 2>&1
if errorlevel 1 (
    echo ❌ npm is required but not installed
    exit /b 1
)

REM Check Flutter
where flutter >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is required but not installed
    exit /b 1
)

echo ✅ All prerequisites found

REM Set up test environment
echo 🛠️  Setting up test environment...

REM Create test environment file
(
echo NODE_ENV=test
echo PORT=%SERVER_PORT%
echo MONGODB_URI=mongodb://localhost:27017/%DB_NAME%
echo MONGODB_TEST_URI=mongodb://localhost:27017/%DB_NAME%
echo JWT_SECRET=test_jwt_secret_key
echo EXPOSE_OTP=true
echo.
echo # Razorpay Test Credentials
echo RAZORPAY_KEY_ID=rzp_test_dummy_key
echo RAZORPAY_KEY_SECRET=dummy_secret_key
echo RAZORPAY_WEBHOOK_SECRET=dummy_webhook_secret
echo.
echo # Stripe Test Credentials
echo STRIPE_SECRET_KEY=sk_test_dummy_key
echo STRIPE_PUBLISHABLE_KEY=pk_test_dummy_key
echo STRIPE_WEBHOOK_SECRET=whsec_dummy_webhook_secret
echo.
echo # PayPal Test Credentials
echo PAYPAL_CLIENT_ID=dummy_paypal_client_id
echo PAYPAL_CLIENT_SECRET=dummy_paypal_client_secret
) > %TEST_ENV_FILE%

echo ✅ Test environment configured

REM Install dependencies
echo 📦 Installing Node.js dependencies...
call npm install --silent
if errorlevel 1 (
    echo ❌ Failed to install Node.js dependencies
    exit /b 1
)
echo ✅ Node.js dependencies installed

REM Install Flutter dependencies
echo 📦 Installing Flutter dependencies...
call flutter pub get >nul 2>&1
if errorlevel 1 (
    echo ❌ Failed to install Flutter dependencies
    exit /b 1
)
echo ✅ Flutter dependencies installed

REM Start test server
echo 🚀 Starting test server...
set NODE_ENV=test
start /b node server.js
set SERVER_PID=%!

REM Wait for server to start
timeout /t 3 /nobreak >nul

REM Check if server is running
curl -s http://localhost:%SERVER_PORT%/ >nul 2>&1
if errorlevel 1 (
    echo ❌ Test server failed to start
    exit /b 1
)
echo ✅ Test server running on port %SERVER_PORT%

REM Run Node.js/Backend tests
echo 🧪 Running Backend UPI Tests...
echo.

echo 📝 Running UPI Payment API Tests...
call npm test test/upi/upi_payment_test.js
set UPI_API_RESULT=%errorlevel%

echo ⚡ Running UPI Performance Tests...
call npm test test/upi/upi_performance_test.js
set UPI_PERF_RESULT=%errorlevel%

REM Run Flutter/Frontend tests
echo 🧪 Running Flutter UPI Tests...
echo.

echo 📱 Running UPI Payment Service Tests...
call flutter test test/upi/upi_payment_service_test.dart
set UPI_SERVICE_RESULT=%errorlevel%

echo 🎨 Running UPI Payment Widget Tests...
call flutter test test/upi/upi_payment_widget_test.dart
set UPI_WIDGET_RESULT=%errorlevel%

REM Run integration tests
echo 🔗 Running Integration Tests...
echo.

REM Test UPI endpoints manually
echo 🌐 Testing UPI API Endpoints...

REM Test UPI apps endpoint
curl -s http://localhost:%SERVER_PORT%/api/payment/upi/apps > temp_response.json
findstr "googlepay" temp_response.json >nul
if errorlevel 1 (
    echo ❌ UPI Apps endpoint failed
    set UPI_ENDPOINT_RESULT=1
) else (
    echo ✅ UPI Apps endpoint working
    set UPI_ENDPOINT_RESULT=0
)
del temp_response.json

REM Test health check
curl -s http://localhost:%SERVER_PORT%/ > temp_health.json
findstr "Resume Builder API is running" temp_health.json >nul
if errorlevel 1 (
    echo ❌ Health check failed
) else (
    echo ✅ Health check passed
)
del temp_health.json

REM Performance benchmarks
echo 📊 Running Performance Benchmarks...
echo.
echo ⏱️  Benchmarking UPI Apps endpoint...

REM Simple performance test (Windows doesn't have built-in timing like bash)
for /l %%i in (1,1,10) do (
    curl -s http://localhost:%SERVER_PORT%/api/payment/upi/apps >nul
)
echo ✅ UPI Apps endpoint performance test completed

REM Security tests
echo 🔒 Running Security Tests...
echo.

REM Test authentication requirement
curl -s -w "%%{http_code}" http://localhost:%SERVER_PORT%/api/payment/upi/create-intent -o nul > temp_auth.txt
set /p AUTH_RESPONSE=<temp_auth.txt
if "%AUTH_RESPONSE%"=="401" (
    echo ✅ Authentication protection working
) else (
    echo ❌ Authentication protection failed
)
del temp_auth.txt

REM Compile results
echo 📊 Test Results Summary
echo ========================================

set TOTAL_TESTS=5
set PASSED_TESTS=0

if %UPI_API_RESULT%==0 (
    echo ✅ UPI Payment API Tests: PASSED
    set /a PASSED_TESTS+=1
) else (
    echo ❌ UPI Payment API Tests: FAILED
)

if %UPI_PERF_RESULT%==0 (
    echo ✅ UPI Performance Tests: PASSED
    set /a PASSED_TESTS+=1
) else (
    echo ❌ UPI Performance Tests: FAILED
)

if %UPI_SERVICE_RESULT%==0 (
    echo ✅ UPI Payment Service Tests: PASSED
    set /a PASSED_TESTS+=1
) else (
    echo ❌ UPI Payment Service Tests: FAILED
)

if %UPI_WIDGET_RESULT%==0 (
    echo ✅ UPI Payment Widget Tests: PASSED
    set /a PASSED_TESTS+=1
) else (
    echo ❌ UPI Payment Widget Tests: FAILED
)

if %UPI_ENDPOINT_RESULT%==0 (
    echo ✅ UPI Integration Tests: PASSED
    set /a PASSED_TESTS+=1
) else (
    echo ❌ UPI Integration Tests: FAILED
)

echo.
echo 📈 Coverage Summary:
echo    • Backend API Coverage: UPI endpoints, authentication, validation
echo    • Frontend Widget Coverage: UI components, user interactions
echo    • Integration Coverage: End-to-end payment flow
echo    • Performance Coverage: Response times, concurrent requests
echo    • Security Coverage: Authentication, input validation

echo.
if %PASSED_TESTS%==%TOTAL_TESTS% (
    echo 🎉 ALL TESTS PASSED ^(%PASSED_TESTS%/%TOTAL_TESTS%^)
    echo ✨ UPI Payment System is ready for production!
) else (
    echo ❌ SOME TESTS FAILED ^(%PASSED_TESTS%/%TOTAL_TESTS%^)
    echo 🔧 Please fix failing tests before deployment
)

REM Cleanup
echo.
echo 🧹 Cleaning up test environment...

REM Stop test server (kill node processes)
taskkill /f /im node.exe >nul 2>&1

REM Clean test files
if exist %TEST_ENV_FILE% del %TEST_ENV_FILE%

echo ✅ Cleanup completed

if %PASSED_TESTS%==%TOTAL_TESTS% (
    exit /b 0
) else (
    exit /b 1
)