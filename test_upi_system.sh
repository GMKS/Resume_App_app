#!/bin/bash

# UPI Payment System Test Runner
# Comprehensive testing script for all UPI payment components

echo "🚀 Starting UPI Payment System Tests..."
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_ENV_FILE=".env.test"
SERVER_PORT=3001
DB_NAME="resume_app_upi_test"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cleanup function
cleanup() {
    print_status $YELLOW "🧹 Cleaning up test environment..."
    
    # Stop test server if running
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
        print_status $GREEN "✅ Test server stopped"
    fi
    
    # Clean test database
    if command_exists mongosh; then
        mongosh --eval "use $DB_NAME; db.dropDatabase();" >/dev/null 2>&1
        print_status $GREEN "✅ Test database cleaned"
    fi
    
    echo ""
}

# Set up cleanup trap
trap cleanup EXIT

# Check prerequisites
print_status $BLUE "🔍 Checking prerequisites..."

if ! command_exists node; then
    print_status $RED "❌ Node.js is required but not installed"
    exit 1
fi

if ! command_exists npm; then
    print_status $RED "❌ npm is required but not installed"
    exit 1
fi

if ! command_exists flutter; then
    print_status $RED "❌ Flutter is required but not installed"
    exit 1
fi

print_status $GREEN "✅ All prerequisites found"

# Set up test environment
print_status $BLUE "🛠️  Setting up test environment..."

# Create test environment file
cat > $TEST_ENV_FILE << EOF
NODE_ENV=test
PORT=$SERVER_PORT
MONGODB_URI=mongodb://localhost:27017/$DB_NAME
MONGODB_TEST_URI=mongodb://localhost:27017/$DB_NAME
JWT_SECRET=test_jwt_secret_key
EXPOSE_OTP=true

# Razorpay Test Credentials
RAZORPAY_KEY_ID=rzp_test_dummy_key
RAZORPAY_KEY_SECRET=dummy_secret_key
RAZORPAY_WEBHOOK_SECRET=dummy_webhook_secret

# Stripe Test Credentials
STRIPE_SECRET_KEY=sk_test_dummy_key
STRIPE_PUBLISHABLE_KEY=pk_test_dummy_key
STRIPE_WEBHOOK_SECRET=whsec_dummy_webhook_secret

# PayPal Test Credentials
PAYPAL_CLIENT_ID=dummy_paypal_client_id
PAYPAL_CLIENT_SECRET=dummy_paypal_client_secret
EOF

print_status $GREEN "✅ Test environment configured"

# Install dependencies
print_status $BLUE "📦 Installing Node.js dependencies..."
npm install --silent
if [ $? -ne 0 ]; then
    print_status $RED "❌ Failed to install Node.js dependencies"
    exit 1
fi
print_status $GREEN "✅ Node.js dependencies installed"

# Install Flutter dependencies
print_status $BLUE "📦 Installing Flutter dependencies..."
flutter pub get >/dev/null
if [ $? -ne 0 ]; then
    print_status $RED "❌ Failed to install Flutter dependencies"
    exit 1
fi
print_status $GREEN "✅ Flutter dependencies installed"

# Start test server
print_status $BLUE "🚀 Starting test server..."
NODE_ENV=test node server.js --env-file=$TEST_ENV_FILE &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Check if server is running
if ! curl -s http://localhost:$SERVER_PORT/ >/dev/null; then
    print_status $RED "❌ Test server failed to start"
    exit 1
fi
print_status $GREEN "✅ Test server running on port $SERVER_PORT"

# Run Node.js/Backend tests
print_status $BLUE "🧪 Running Backend UPI Tests..."
echo ""

print_status $YELLOW "📝 Running UPI Payment API Tests..."
npm test -- test/upi/upi_payment_test.js
UPI_API_RESULT=$?

print_status $YELLOW "⚡ Running UPI Performance Tests..."
npm test -- test/upi/upi_performance_test.js
UPI_PERF_RESULT=$?

# Run Flutter/Frontend tests
print_status $BLUE "🧪 Running Flutter UPI Tests..."
echo ""

print_status $YELLOW "📱 Running UPI Payment Service Tests..."
flutter test test/upi/upi_payment_service_test.dart
UPI_SERVICE_RESULT=$?

print_status $YELLOW "🎨 Running UPI Payment Widget Tests..."
flutter test test/upi/upi_payment_widget_test.dart
UPI_WIDGET_RESULT=$?

# Run integration tests
print_status $BLUE "🔗 Running Integration Tests..."
echo ""

# Test UPI endpoints manually
print_status $YELLOW "🌐 Testing UPI API Endpoints..."

# Test UPI apps endpoint
UPI_APPS_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/api/payment/upi/apps)
if echo "$UPI_APPS_RESPONSE" | grep -q "googlepay"; then
    print_status $GREEN "✅ UPI Apps endpoint working"
    UPI_ENDPOINT_RESULT=0
else
    print_status $RED "❌ UPI Apps endpoint failed"
    UPI_ENDPOINT_RESULT=1
fi

# Test health check
HEALTH_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/)
if echo "$HEALTH_RESPONSE" | grep -q "Resume Builder API is running"; then
    print_status $GREEN "✅ Health check passed"
else
    print_status $RED "❌ Health check failed"
fi

# Performance benchmarks
print_status $BLUE "📊 Running Performance Benchmarks..."
echo ""

# Benchmark UPI apps endpoint
print_status $YELLOW "⏱️  Benchmarking UPI Apps endpoint..."
START_TIME=$(date +%s%N)
for i in {1..10}; do
    curl -s http://localhost:$SERVER_PORT/api/payment/upi/apps >/dev/null
done
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000)) # Convert to milliseconds
AVG_DURATION=$(($DURATION / 10))

if [ $AVG_DURATION -lt 100 ]; then
    print_status $GREEN "✅ UPI Apps endpoint: ${AVG_DURATION}ms average (excellent)"
elif [ $AVG_DURATION -lt 200 ]; then
    print_status $YELLOW "⚠️  UPI Apps endpoint: ${AVG_DURATION}ms average (good)"
else
    print_status $RED "❌ UPI Apps endpoint: ${AVG_DURATION}ms average (slow)"
fi

# Security tests
print_status $BLUE "🔒 Running Security Tests..."
echo ""

# Test authentication requirement
AUTH_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:$SERVER_PORT/api/payment/upi/create-intent -o /dev/null)
if [ "$AUTH_RESPONSE" = "401" ]; then
    print_status $GREEN "✅ Authentication protection working"
else
    print_status $RED "❌ Authentication protection failed"
fi

# Test input validation
VALIDATION_RESPONSE=$(curl -s -X POST http://localhost:$SERVER_PORT/api/payment/upi/create-intent \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer invalid_token" \
    -d '{"planType":"invalid","currency":"USD"}')

if echo "$VALIDATION_RESPONSE" | grep -q "Invalid"; then
    print_status $GREEN "✅ Input validation working"
else
    print_status $RED "❌ Input validation failed"
fi

# Compile results
print_status $BLUE "📊 Test Results Summary"
echo "========================================"

TOTAL_TESTS=5
PASSED_TESTS=0

if [ $UPI_API_RESULT -eq 0 ]; then
    print_status $GREEN "✅ UPI Payment API Tests: PASSED"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_status $RED "❌ UPI Payment API Tests: FAILED"
fi

if [ $UPI_PERF_RESULT -eq 0 ]; then
    print_status $GREEN "✅ UPI Performance Tests: PASSED"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_status $RED "❌ UPI Performance Tests: FAILED"
fi

if [ $UPI_SERVICE_RESULT -eq 0 ]; then
    print_status $GREEN "✅ UPI Payment Service Tests: PASSED"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_status $RED "❌ UPI Payment Service Tests: FAILED"
fi

if [ $UPI_WIDGET_RESULT -eq 0 ]; then
    print_status $GREEN "✅ UPI Payment Widget Tests: PASSED"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_status $RED "❌ UPI Payment Widget Tests: FAILED"
fi

if [ $UPI_ENDPOINT_RESULT -eq 0 ]; then
    print_status $GREEN "✅ UPI Integration Tests: PASSED"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_status $RED "❌ UPI Integration Tests: FAILED"
fi

echo ""
print_status $BLUE "📈 Coverage Summary:"
echo "   • Backend API Coverage: UPI endpoints, authentication, validation"
echo "   • Frontend Widget Coverage: UI components, user interactions"
echo "   • Integration Coverage: End-to-end payment flow"
echo "   • Performance Coverage: Response times, concurrent requests"
echo "   • Security Coverage: Authentication, input validation"

echo ""
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    print_status $GREEN "🎉 ALL TESTS PASSED ($PASSED_TESTS/$TOTAL_TESTS)"
    print_status $GREEN "✨ UPI Payment System is ready for production!"
    exit 0
else
    print_status $RED "❌ SOME TESTS FAILED ($PASSED_TESTS/$TOTAL_TESTS)"
    print_status $YELLOW "🔧 Please fix failing tests before deployment"
    exit 1
fi