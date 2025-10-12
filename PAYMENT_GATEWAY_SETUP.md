# 💳 Payment Gateway Setup Guide for Resume Builder

## Overview

This guide helps you set up payment gateways for your Resume Builder app with support for **Stripe**, **Razorpay**, and **PayPal** to handle global subscriptions.

## 🎯 **Features Implemented**

### **Backend Payment System:**

- ✅ **Multi-provider support** (Stripe, Razorpay, PayPal)
- ✅ **Subscription management** with MongoDB persistence
- ✅ **Payment verification** and webhook handling
- ✅ **Regional pricing** and currency localization
- ✅ **Free trial system** (7 days)
- ✅ **Payment transaction logging**
- ✅ **Refund processing**
- ✅ **Test mode** for development

### **Frontend Integration:**

- ✅ **Payment service** for Flutter integration
- ✅ **Subscription status tracking**
- ✅ **Payment history**
- ✅ **Currency formatting**
- ✅ **Error handling** and user feedback

## 🛠️ **Setup Instructions**

### **1. Environment Configuration**

Copy the example environment file and configure your payment providers:

```bash
cp .env.example .env
```

Edit `.env` with your payment gateway credentials:

```env
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_stripe_webhook_secret_here

# Razorpay Configuration (for India)
RAZORPAY_KEY_ID=rzp_test_your_razorpay_key_id_here
RAZORPAY_KEY_SECRET=your_razorpay_key_secret_here
RAZORPAY_WEBHOOK_SECRET=your_razorpay_webhook_secret_here

# PayPal Configuration
PAYPAL_CLIENT_ID=your_paypal_client_id_here
PAYPAL_CLIENT_SECRET=your_paypal_client_secret_here
```

### **2. Payment Provider Setup**

#### **🟣 Stripe Setup (Global)**

1. **Create Stripe Account:**

   - Go to https://dashboard.stripe.com/
   - Sign up or login to your account

2. **Get API Keys:**

   - Navigate to **Developers** → **API Keys**
   - Copy **Secret Key** (starts with `sk_test_`) to `STRIPE_SECRET_KEY`
   - Copy **Publishable Key** (starts with `pk_test_`) to `STRIPE_PUBLISHABLE_KEY`

3. **Setup Webhooks:**
   - Go to **Developers** → **Webhooks**
   - Click **Add endpoint**
   - URL: `https://yourdomain.com/api/webhooks/stripe`
   - Select events:
     - `payment_intent.succeeded`
     - `payment_intent.payment_failed`
     - `customer.subscription.deleted`
   - Copy **Webhook Secret** to `STRIPE_WEBHOOK_SECRET`

#### **🟠 Razorpay Setup (India)**

1. **Create Razorpay Account:**

   - Go to https://dashboard.razorpay.com/
   - Complete business verification

2. **Generate API Keys:**

   - Go to **Settings** → **API Keys**
   - Click **Generate Test Key**
   - Copy **Key ID** to `RAZORPAY_KEY_ID`
   - Copy **Key Secret** to `RAZORPAY_KEY_SECRET`

3. **Setup Webhooks:**
   - Go to **Settings** → **Webhooks**
   - Click **Add New Webhook**
   - URL: `https://yourdomain.com/api/webhooks/razorpay`
   - Select events:
     - `payment.captured`
     - `payment.failed`
   - Copy **Webhook Secret** to `RAZORPAY_WEBHOOK_SECRET`

#### **🔵 PayPal Setup (Global)**

1. **Create PayPal Developer Account:**

   - Go to https://developer.paypal.com/
   - Login with PayPal account

2. **Create Application:**

   - Go to **My Apps & Credentials**
   - Click **Create App**
   - Choose **Sandbox** for testing
   - Copy **Client ID** to `PAYPAL_CLIENT_ID`
   - Copy **Client Secret** to `PAYPAL_CLIENT_SECRET`

3. **For Production:**
   - Create new app with **Live** environment
   - Update credentials in production `.env`

### **3. Start Your Server**

```bash
# Install dependencies (already done)
npm install

# Start the server
node server.js
```

You should see:

```
✅ Stripe payment provider initialized
✅ Razorpay payment provider initialized
✅ PayPal payment provider initialized
💳 Payment service initialized with available providers
```

## 📋 **API Endpoints**

### **Subscription Management:**

- `GET /api/subscription/status` - Get user subscription status
- `GET /api/subscription/plans` - Get pricing plans
- `POST /api/subscription/trial/start` - Start free trial
- `POST /api/subscription/cancel` - Cancel subscription

### **Payment Processing:**

- `POST /api/payment/create-intent` - Create payment intent
- `POST /api/payment/verify` - Verify and activate subscription
- `GET /api/payment/history` - Get payment history

### **Webhooks:**

- `POST /api/webhooks/stripe` - Stripe webhook handler
- `POST /api/webhooks/razorpay` - Razorpay webhook handler

### **Testing (Development Only):**

- `POST /api/test/activate-premium` - Test premium activation
- `POST /api/test/renew-subscription` - Test subscription renewal

## 🧪 **Testing Your Setup**

### **1. Test Subscription Status**

```bash
curl -X GET http://localhost:3000/api/subscription/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### **2. Test Pricing Plans**

```bash
curl -X GET "http://localhost:3000/api/subscription/plans?currency=USD"
```

### **3. Test Payment Intent Creation**

```bash
curl -X POST http://localhost:3000/api/payment/create-intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"planType": "monthly", "currency": "USD"}'
```

### **4. Test Premium Activation (Development)**

```bash
curl -X POST http://localhost:3000/api/test/activate-premium \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"planType": "yearly"}'
```

## 💰 **Pricing Configuration**

Current pricing structure (customizable in `PaymentService.js`):

```javascript
regionalPricing = {
  USD: { monthly: 9.99, yearly: 49.99, lifetime: 99.99 },
  EUR: { monthly: 8.99, yearly: 44.99, lifetime: 89.99 },
  GBP: { monthly: 7.99, yearly: 39.99, lifetime: 79.99 },
  INR: { monthly: 699, yearly: 3499, lifetime: 6999 },
  CAD: { monthly: 12.99, yearly: 64.99, lifetime: 129.99 },
  AUD: { monthly: 14.99, yearly: 74.99, lifetime: 149.99 },
};
```

## 📱 **Flutter Integration**

### **1. Add Payment Service to Your App**

The `PaymentService` class is already created in `lib/services/payment_service.dart` with methods for:

- Getting subscription status
- Starting free trials
- Creating payment intents
- Verifying payments
- Cancelling subscriptions
- Payment history

### **2. Example Usage in Flutter**

```dart
// Check subscription status
final subscription = await PaymentService.getSubscriptionStatus();
if (subscription['status'] == 'active') {
  // User has premium
}

// Start free trial
final trial = await PaymentService.startFreeTrial();
print('Trial ends: ${trial['trialEndDate']}');

// Create payment for yearly plan
final paymentIntent = await PaymentService.createPaymentIntent(
  planType: 'yearly',
  currency: 'USD',
);

// Verify payment after user completes payment
final result = await PaymentService.verifyPayment(
  paymentProvider: 'stripe',
  planType: 'yearly',
  amount: 49.99,
  currency: 'USD',
  paymentIntentId: 'pi_xxxxxxxxxxxx',
);
```

## 🔒 **Security Considerations**

### **Production Checklist:**

- [ ] Use **live API keys** (not test keys)
- [ ] Enable **webhook signature verification**
- [ ] Use **HTTPS** for all webhook endpoints
- [ ] Set strong **JWT secrets**
- [ ] Enable **rate limiting**
- [ ] Monitor **failed payment attempts**
- [ ] Set up **backup payment methods**
- [ ] Implement **fraud detection**

### **Data Protection:**

- [ ] **PCI compliance** (handled by payment providers)
- [ ] **GDPR compliance** for EU users
- [ ] **Data encryption** in transit and at rest
- [ ] **Secure credential storage**

## 📊 **Analytics & Monitoring**

The system includes built-in analytics for:

- **Subscription metrics** (signups, cancellations, revenue)
- **Payment analytics** (success rates, provider performance)
- **User behavior** (trial conversions, plan preferences)
- **Regional insights** (currency preferences, geographic distribution)

Access analytics via:

```bash
# Get subscription analytics
curl -X GET "http://localhost:3000/api/analytics/subscriptions?start=2024-01-01&end=2024-12-31" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

## 🚨 **Troubleshooting**

### **Common Issues:**

**1. Payment Provider Not Initialized**

```
❌ Stripe payment provider initialization error
```

- Check your API keys in `.env`
- Ensure keys start with correct prefixes (`sk_test_`, `pk_test_`)

**2. Webhook Verification Failed**

```
❌ Webhook verification error
```

- Verify webhook secrets are correct
- Check webhook URL is publicly accessible
- Ensure HTTPS for production webhooks

**3. Payment Verification Failed**

```
❌ Payment verification failed
```

- Check payment provider response
- Verify signature/parameters are correct
- Check payment amount matches plan price

**4. Database Connection Issues**

```
❌ MongoDB connection error
```

- Ensure MongoDB is running
- Check connection string in `.env`
- Verify database permissions

### **Debug Mode:**

Enable debug logging by setting:

```env
NODE_ENV=development
```

This will show detailed payment processing logs.

## 🚀 **Production Deployment**

### **1. Environment Setup**

- Use **production API keys**
- Set `NODE_ENV=production`
- Configure **HTTPS** endpoints
- Set up **monitoring** and **alerting**

### **2. Webhook Configuration**

- Update webhook URLs to production domain
- Test webhook delivery
- Monitor webhook success rates

### **3. Database Setup**

- Use **MongoDB Atlas** or production MongoDB
- Set up **automated backups**
- Configure **monitoring**

### **4. Security**

- Enable **rate limiting**
- Set up **DDoS protection**
- Monitor for **suspicious activity**

## 📞 **Support**

For payment gateway issues:

- **Stripe:** https://support.stripe.com/
- **Razorpay:** https://razorpay.com/support/
- **PayPal:** https://developer.paypal.com/support/

For implementation help, check the API documentation and test the endpoints with the provided examples.

---

**Your Resume Builder now has a complete payment gateway system with multi-provider support, subscription management, and global currency handling! 🎉**
