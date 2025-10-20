# Razorpay Integration Setup Guide

## Overview

This guide helps you set up Razorpay payment integration for the Resume Builder app.

## 🔧 Quick Setup Steps

### 1. Get Razorpay Credentials

1. **Sign up/Login to Razorpay**

   - Visit: https://dashboard.razorpay.com/
   - Create account or login

2. **Generate API Keys**

   - Go to Settings → API Keys
   - Generate Test Keys for development
   - Generate Live Keys for production

3. **Copy Your Credentials**
   - Copy your `Key ID` (starts with `rzp_test_` or `rzp_live_`)
   - Copy your `Key Secret`

### 2. Update Environment File

1. **Open `.env` file** in the project root
2. **Replace the placeholder values**:
   ```bash
   # Replace these with your actual Razorpay credentials
   RAZORPAY_KEY_ID=rzp_test_your_actual_key_id_here
   RAZORPAY_KEY_SECRET=your_actual_key_secret_here
   ```

### 3. Test the Integration

1. **Start the server**:

   ```bash
   node server.js
   ```

2. **Run the Flutter app**:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
   ```

3. **Test payment flow**:
   - Open the app
   - Go to premium/payment section
   - Try a UPI payment
   - Use test UPI ID: `success@razorpay` (always succeeds)

## 🔄 Payment Flow

```
Flutter App → Create Payment Intent → Razorpay Checkout → Payment Success → Server Verification → Subscription Activated
```

## 🧪 Test Credentials

For testing, Razorpay provides test credentials and test payment methods:

- **Test UPI ID**: `success@razorpay` (always succeeds)
- **Test UPI ID**: `failure@razorpay` (always fails)
- **Test Cards**: Available in Razorpay documentation

## 🚀 Going Live

When ready for production:

1. **Get Live Keys** from Razorpay Dashboard
2. **Update `.env`** with live credentials:
   ```bash
   RAZORPAY_KEY_ID=rzp_live_your_live_key_id
   RAZORPAY_KEY_SECRET=your_live_key_secret
   ```
3. **Deploy server** with production environment variables
4. **Update Flutter app** with production API URL:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://your-production-server.com/api
   ```

## 🛡️ Security Notes

- ✅ Never commit real credentials to version control
- ✅ Use test credentials during development
- ✅ Verify payments on server-side (already implemented)
- ✅ Use HTTPS in production
- ✅ Implement proper webhook handling (already implemented)

## 🐛 Troubleshooting

**Payment fails with "Invalid key" error:**

- Check that `RAZORPAY_KEY_ID` is correctly set in `.env`
- Verify the key format (should start with `rzp_test_` or `rzp_live_`)

**Server can't verify payments:**

- Check that `RAZORPAY_KEY_SECRET` is correctly set in `.env`
- Ensure no extra spaces in the secret key

**App can't connect to server:**

- Verify server is running on correct port (3000 by default)
- Check API_BASE_URL in Flutter run command
- For Android device, use your PC's IP address instead of 127.0.0.1

## 📚 Resources

- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Dashboard](https://dashboard.razorpay.com/)
- [Test Cards & Methods](https://razorpay.com/docs/payments/payments/test-card-upi-details/)
