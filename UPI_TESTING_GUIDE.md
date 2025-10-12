# UPI Payment Testing Guide

This document provides comprehensive instructions for testing the UPI payment system integration for Google Pay, PhonePe, and other Indian UPI apps.

## Quick Start

### Windows

```bash
./test_upi_system.bat
```

### Linux/macOS

```bash
chmod +x test_upi_system.sh
./test_upi_system.sh
```

## Test Structure

### 1. Backend API Tests (`test/upi/upi_payment_test.js`)

- **UPI Apps Discovery**: Tests the `/api/payment/upi/apps` endpoint
- **Payment Intent Creation**: Tests UPI payment intent creation for each app
- **Payment Verification**: Tests the payment verification flow
- **Error Handling**: Tests various error scenarios
- **Integration Flow**: End-to-end testing for all UPI apps

### 2. Performance Tests (`test/upi/upi_performance_test.js`)

- **Response Time**: Ensures UPI endpoints respond under 500ms
- **Concurrent Requests**: Tests handling of multiple simultaneous requests
- **Memory Usage**: Monitors memory consumption during UPI operations
- **Database Performance**: Tests database operation efficiency

### 3. Flutter Service Tests (`test/upi/upi_payment_service_test.dart`)

- **Service Methods**: Tests all UpiPaymentService methods
- **UPI App Management**: Tests app discovery and metadata
- **Payment Flow**: Tests payment intent creation and verification
- **Error Handling**: Tests network and authentication errors

### 4. Flutter Widget Tests (`test/upi/upi_payment_widget_test.dart`)

- **UI Rendering**: Tests widget display and layout
- **User Interactions**: Tests app selection and payment initiation
- **State Management**: Tests loading states and error handling
- **Accessibility**: Tests accessibility compliance

## Manual Testing

### 1. Start the Development Server

```bash
npm run dev
# or
node server.js
```

### 2. Test UPI Endpoints

#### Get Available UPI Apps

```bash
curl -X GET http://localhost:3000/api/payment/upi/apps
```

Expected response:

```json
{
  "success": true,
  "data": {
    "googlepay": {
      "name": "Google Pay",
      "package": "com.google.android.apps.nbu.paisa.user",
      "icon": "💳",
      "color": "4285F4",
      "supported": true
    },
    "phonepe": {
      "name": "PhonePe",
      "package": "com.phonepe.app",
      "icon": "📱",
      "color": "5F259F",
      "supported": true
    }
    // ... other UPI apps
  }
}
```

#### Create UPI Payment Intent

```bash
curl -X POST http://localhost:3000/api/payment/upi/create-intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "planType": "monthly",
    "upiApp": "googlepay",
    "currency": "INR"
  }'
```

#### Verify UPI Payment

```bash
curl -X POST http://localhost:3000/api/payment/upi/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "planType": "monthly",
    "amount": 299,
    "currency": "INR",
    "razorpayPaymentId": "pay_test_123",
    "razorpayOrderId": "order_test_123",
    "razorpaySignature": "signature_test_123",
    "upiApp": "googlepay"
  }'
```

### 3. Flutter App Testing

#### Run Flutter Tests

```bash
flutter test test/upi/
```

#### Test UPI Widget Integration

1. Open the Flutter app
2. Navigate to subscription/payment page
3. Verify UPI payment section appears for Indian users
4. Test UPI app selection (Google Pay, PhonePe, etc.)
5. Test payment flow initiation

## Test Scenarios

### Functional Testing

#### 1. UPI App Selection

- [ ] All UPI apps display correctly
- [ ] App icons and colors are correct
- [ ] App selection works properly
- [ ] Selected app is highlighted

#### 2. Payment Intent Creation

- [ ] Creates intent for Google Pay
- [ ] Creates intent for PhonePe
- [ ] Creates intent for Paytm
- [ ] Creates intent for Amazon Pay
- [ ] Creates intent for MobiKwik
- [ ] Rejects non-INR currency
- [ ] Validates plan types

#### 3. Payment Verification

- [ ] Verifies valid payments
- [ ] Rejects invalid signatures
- [ ] Handles network errors
- [ ] Updates subscription status
- [ ] Records transaction history

#### 4. Error Handling

- [ ] Authentication errors
- [ ] Network timeouts
- [ ] Invalid parameters
- [ ] Server errors
- [ ] Database connection issues

### Performance Testing

#### 1. Response Times

- [ ] UPI apps endpoint < 100ms
- [ ] Payment intent creation < 500ms
- [ ] Payment verification < 1000ms
- [ ] End-to-end flow < 2000ms

#### 2. Concurrent Users

- [ ] Handle 10 concurrent payment intents
- [ ] Handle 50 concurrent UPI app requests
- [ ] No memory leaks under load
- [ ] Database performance remains stable

### Security Testing

#### 1. Authentication

- [ ] All UPI endpoints require authentication
- [ ] Invalid tokens are rejected
- [ ] Expired tokens are handled

#### 2. Input Validation

- [ ] Invalid plan types rejected
- [ ] Invalid currencies rejected
- [ ] SQL injection prevention
- [ ] XSS prevention

#### 3. Payment Security

- [ ] Razorpay signature verification
- [ ] Secure payment data handling
- [ ] PCI compliance measures

## Test Data

### Test User Credentials

```json
{
  "email": "upi-test@example.com",
  "password": "testpassword123",
  "phone": "+91-9876543210"
}
```

### Test Plan Types

- `monthly` - ₹299
- `yearly` - ₹1999
- `lifetime` - ₹4999

### UPI Apps for Testing

- `googlepay` - Google Pay
- `phonepe` - PhonePe
- `paytm` - Paytm
- `amazonpay` - Amazon Pay
- `mobikwik` - MobiKwik

## Debugging

### Common Issues

#### 1. Server Won't Start

```bash
# Check if port is in use
netstat -ano | findstr :3000

# Kill process using port
taskkill /PID <PID> /F
```

#### 2. Authentication Failures

```bash
# Check JWT token validity
node -e "
const jwt = require('jsonwebtoken');
const token = 'YOUR_TOKEN';
console.log(jwt.decode(token));
"
```

#### 3. Database Connection Issues

```bash
# Check MongoDB connection
mongosh --eval "db.runCommand('ismaster')"
```

#### 4. Flutter Test Failures

```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Run with verbose output
flutter test --reporter=verbose
```

### Debug Tools

#### Backend Debugging

```bash
# Enable debug logging
NODE_ENV=development DEBUG=* node server.js

# Test with curl verbose
curl -v http://localhost:3000/api/payment/upi/apps
```

#### Frontend Debugging

```bash
# Flutter debugging
flutter run --debug
flutter logs

# Widget inspector
flutter inspector
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: UPI Payment Tests

on: [push, pull_request]

jobs:
  test-upi:
    runs-on: ubuntu-latest

    services:
      mongodb:
        image: mongo:5.0
        ports:
          - 27017:27017

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "18"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.16.0"

      - name: Install dependencies
        run: |
          npm install
          flutter pub get

      - name: Run UPI tests
        run: ./test_upi_system.sh
```

## Production Deployment

### Pre-deployment Checklist

- [ ] All tests pass
- [ ] Performance benchmarks met
- [ ] Security tests pass
- [ ] Real Razorpay credentials configured
- [ ] Webhook endpoints tested
- [ ] Error monitoring configured

### Environment Variables

```bash
# Production Razorpay credentials
RAZORPAY_KEY_ID=rzp_live_your_key_id
RAZORPAY_KEY_SECRET=your_live_secret_key
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret

# Database
MONGODB_URI=mongodb://production_uri

# Security
JWT_SECRET=strong_production_secret
NODE_ENV=production
```

This testing guide ensures comprehensive validation of the UPI payment system before production deployment.
