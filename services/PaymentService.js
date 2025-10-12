const Stripe = require("stripe");
const Razorpay = require("razorpay");
const paypal = require("@paypal/checkout-server-sdk");
const crypto = require("crypto");

class PaymentService {
  constructor() {
    // Initialize payment providers
    this.initializeProviders();

    // Subscription plans configuration
    this.plans = {
      monthly: {
        amount: 9.99,
        currency: "USD",
        interval: "month",
        name: "Monthly Premium",
      },
      yearly: {
        amount: 49.99,
        currency: "USD",
        interval: "year",
        name: "Yearly Premium",
        discount: 58, // Save 58%
      },
      lifetime: {
        amount: 99.99,
        currency: "USD",
        interval: "lifetime",
        name: "Lifetime Premium",
      },
    };

    // Regional pricing (currency localization)
    this.regionalPricing = {
      USD: { monthly: 9.99, yearly: 49.99, lifetime: 99.99 },
      EUR: { monthly: 8.99, yearly: 44.99, lifetime: 89.99 },
      GBP: { monthly: 7.99, yearly: 39.99, lifetime: 79.99 },
      INR: { monthly: 699, yearly: 3499, lifetime: 6999 },
      CAD: { monthly: 12.99, yearly: 64.99, lifetime: 129.99 },
      AUD: { monthly: 14.99, yearly: 74.99, lifetime: 149.99 },
    };
  }

  initializeProviders() {
    try {
      // Stripe initialization
      if (process.env.STRIPE_SECRET_KEY) {
        this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
        console.log("✅ Stripe payment provider initialized");
      }

      // Razorpay initialization
      if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
        this.razorpay = new Razorpay({
          key_id: process.env.RAZORPAY_KEY_ID,
          key_secret: process.env.RAZORPAY_KEY_SECRET,
        });
        console.log("✅ Razorpay payment provider initialized");
      }

      // PayPal initialization
      if (process.env.PAYPAL_CLIENT_ID && process.env.PAYPAL_CLIENT_SECRET) {
        const environment =
          process.env.NODE_ENV === "production"
            ? new paypal.core.LiveEnvironment(
                process.env.PAYPAL_CLIENT_ID,
                process.env.PAYPAL_CLIENT_SECRET
              )
            : new paypal.core.SandboxEnvironment(
                process.env.PAYPAL_CLIENT_ID,
                process.env.PAYPAL_CLIENT_SECRET
              );

        this.paypalClient = new paypal.core.PayPalHttpClient(environment);
        console.log("✅ PayPal payment provider initialized");
      }

      console.log("💳 Payment service initialized with available providers");
    } catch (error) {
      console.error("❌ Payment provider initialization error:", error.message);
    }
  }

  // Get pricing for user's region/currency
  getPricing(currency = "USD") {
    return this.regionalPricing[currency] || this.regionalPricing.USD;
  }

  // Determine best payment provider based on region/currency
  getBestProvider(currency = "USD", country = "US", paymentMethod = "auto") {
    // UPI payments for India (GPay, PhonePe)
    if (
      (currency === "INR" || country === "IN") &&
      (paymentMethod === "upi" ||
        paymentMethod === "gpay" ||
        paymentMethod === "phonepe")
    ) {
      return this.razorpay ? "razorpay" : "stripe";
    }

    // Razorpay for India (all payment methods)
    if (currency === "INR" || country === "IN") {
      return this.razorpay ? "razorpay" : "stripe";
    }

    // Stripe for most regions
    if (this.stripe) {
      return "stripe";
    }

    // PayPal as fallback
    if (this.paypalClient) {
      return "paypal";
    }

    // Test mode fallback
    return "test";
  }

  // Create payment intent (Stripe)
  async createStripePaymentIntent(amount, currency, customerId, planType) {
    if (!this.stripe) {
      throw new Error("Stripe not configured");
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency.toLowerCase(),
        customer: customerId,
        metadata: {
          planType,
          service: "resume_builder",
        },
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error("Stripe payment intent creation error:", error);
      throw new Error(`Stripe error: ${error.message}`);
    }
  }

  // Create Razorpay order with UPI support
  async createRazorpayOrder(
    amount,
    currency,
    userId,
    planType,
    paymentMethod = "auto"
  ) {
    if (!this.razorpay) {
      throw new Error("Razorpay not configured");
    }

    try {
      const orderData = {
        amount: Math.round(amount * 100), // Convert to paise
        currency: currency.toUpperCase(),
        receipt: `receipt_${userId}_${Date.now()}`,
        notes: {
          planType,
          userId,
          service: "resume_builder",
          paymentMethod,
        },
      };

      // Add UPI-specific configuration for GPay/PhonePe
      if (
        paymentMethod === "upi" ||
        paymentMethod === "gpay" ||
        paymentMethod === "phonepe"
      ) {
        orderData.method = {
          upi: {
            flow: "collect",
            vpa: "user@paytm", // This will be replaced by user's VPA
          },
        };
      }

      const order = await this.razorpay.orders.create(orderData);

      return {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        key: process.env.RAZORPAY_KEY_ID,
        // UPI specific data
        upiEnabled: true,
        supportedUpiApps: [
          "googlepay",
          "phonepe",
          "paytm",
          "amazonpay",
          "mobikwik",
        ],
        preferredUpiApp:
          paymentMethod === "gpay"
            ? "googlepay"
            : paymentMethod === "phonepe"
            ? "phonepe"
            : null,
      };
    } catch (error) {
      console.error("Razorpay order creation error:", error);
      throw new Error(`Razorpay error: ${error.message}`);
    }
  }

  // Create PayPal order
  async createPayPalOrder(amount, currency, planType) {
    if (!this.paypalClient) {
      throw new Error("PayPal not configured");
    }

    try {
      const request = new paypal.orders.OrdersCreateRequest();
      request.prefer("return=representation");
      request.requestBody({
        intent: "CAPTURE",
        purchase_units: [
          {
            amount: {
              currency_code: currency.toUpperCase(),
              value: amount.toFixed(2),
            },
            description: `Resume Builder ${planType} subscription`,
          },
        ],
        application_context: {
          return_url: `${process.env.FRONTEND_URL}/payment/success`,
          cancel_url: `${process.env.FRONTEND_URL}/payment/cancel`,
        },
      });

      const order = await this.paypalClient.execute(request);
      return {
        orderId: order.result.id,
        approvalUrl: order.result.links.find((link) => link.rel === "approve")
          .href,
      };
    } catch (error) {
      console.error("PayPal order creation error:", error);
      throw new Error(`PayPal error: ${error.message}`);
    }
  }

  // Verify Stripe payment
  async verifyStripePayment(paymentIntentId) {
    if (!this.stripe) {
      throw new Error("Stripe not configured");
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(
        paymentIntentId
      );
      return {
        success: paymentIntent.status === "succeeded",
        status: paymentIntent.status,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        paymentMethod: paymentIntent.payment_method,
      };
    } catch (error) {
      console.error("Stripe payment verification error:", error);
      return { success: false, error: error.message };
    }
  }

  // Verify Razorpay payment
  async verifyRazorpayPayment(paymentId, orderId, signature) {
    if (!this.razorpay) {
      throw new Error("Razorpay not configured");
    }

    try {
      // Verify signature
      const generatedSignature = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
        .update(`${orderId}|${paymentId}`)
        .digest("hex");

      if (generatedSignature !== signature) {
        return { success: false, error: "Invalid signature" };
      }

      // Fetch payment details
      const payment = await this.razorpay.payments.fetch(paymentId);
      return {
        success: payment.status === "captured",
        status: payment.status,
        amount: payment.amount / 100,
        currency: payment.currency,
        paymentMethod: payment.method,
      };
    } catch (error) {
      console.error("Razorpay payment verification error:", error);
      return { success: false, error: error.message };
    }
  }

  // Verify PayPal payment
  async verifyPayPalPayment(orderId) {
    if (!this.paypalClient) {
      throw new Error("PayPal not configured");
    }

    try {
      const request = new paypal.orders.OrdersCaptureRequest(orderId);
      const capture = await this.paypalClient.execute(request);

      return {
        success: capture.result.status === "COMPLETED",
        status: capture.result.status,
        amount: parseFloat(
          capture.result.purchase_units[0].payments.captures[0].amount.value
        ),
        currency:
          capture.result.purchase_units[0].payments.captures[0].amount
            .currency_code,
      };
    } catch (error) {
      console.error("PayPal payment verification error:", error);
      return { success: false, error: error.message };
    }
  }

  // Create customer for recurring payments
  async createCustomer(email, name, provider = "stripe") {
    try {
      switch (provider) {
        case "stripe":
          if (!this.stripe) throw new Error("Stripe not configured");
          const customer = await this.stripe.customers.create({
            email,
            name,
          });
          return { customerId: customer.id, provider: "stripe" };

        case "razorpay":
          if (!this.razorpay) throw new Error("Razorpay not configured");
          const rzpCustomer = await this.razorpay.customers.create({
            email,
            name,
            contact: "", // Phone number if available
          });
          return { customerId: rzpCustomer.id, provider: "razorpay" };

        default:
          throw new Error(`Customer creation not supported for ${provider}`);
      }
    } catch (error) {
      console.error(`Customer creation error (${provider}):`, error);
      throw error;
    }
  }

  // Process refund
  async processRefund(transactionId, amount, provider) {
    try {
      switch (provider) {
        case "stripe":
          if (!this.stripe) throw new Error("Stripe not configured");
          const refund = await this.stripe.refunds.create({
            payment_intent: transactionId,
            amount: Math.round(amount * 100),
          });
          return { success: true, refundId: refund.id };

        case "razorpay":
          if (!this.razorpay) throw new Error("Razorpay not configured");
          const rzpRefund = await this.razorpay.payments.refund(transactionId, {
            amount: Math.round(amount * 100),
          });
          return { success: true, refundId: rzpRefund.id };

        case "paypal":
          // PayPal refund implementation
          // Note: Requires capture ID, not order ID
          throw new Error("PayPal refund requires additional implementation");

        default:
          throw new Error(`Refund not supported for ${provider}`);
      }
    } catch (error) {
      console.error(`Refund error (${provider}):`, error);
      return { success: false, error: error.message };
    }
  }

  // Get payment status from provider
  async getPaymentStatus(paymentId, provider) {
    try {
      switch (provider) {
        case "stripe":
          if (!this.stripe) throw new Error("Stripe not configured");
          const paymentIntent = await this.stripe.paymentIntents.retrieve(
            paymentId
          );
          return {
            status: paymentIntent.status,
            amount: paymentIntent.amount / 100,
            currency: paymentIntent.currency,
            paymentMethod: paymentIntent.payment_method,
            created: new Date(paymentIntent.created * 1000),
          };

        case "razorpay":
          if (!this.razorpay) throw new Error("Razorpay not configured");
          const payment = await this.razorpay.payments.fetch(paymentId);
          return {
            status: payment.status,
            amount: payment.amount / 100,
            currency: payment.currency,
            paymentMethod: payment.method,
            created: new Date(payment.created_at * 1000),
            upi: payment.upi || null,
          };

        case "paypal":
          // PayPal status check implementation
          throw new Error(
            "PayPal status check requires additional implementation"
          );

        default:
          throw new Error(`Payment status check not supported for ${provider}`);
      }
    } catch (error) {
      console.error(`Payment status error (${provider}):`, error);
      throw error;
    }
  }

  // Get provider-specific webhook verification
  verifyWebhook(payload, signature, provider) {
    try {
      switch (provider) {
        case "stripe":
          if (!this.stripe) throw new Error("Stripe not configured");
          return this.stripe.webhooks.constructEvent(
            payload,
            signature,
            process.env.STRIPE_WEBHOOK_SECRET
          );

        case "razorpay":
          // Razorpay webhook verification
          const generatedSignature = crypto
            .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
            .update(payload)
            .digest("hex");

          return generatedSignature === signature;

        default:
          throw new Error(`Webhook verification not supported for ${provider}`);
      }
    } catch (error) {
      console.error(`Webhook verification error (${provider}):`, error);
      throw error;
    }
  }
}

module.exports = new PaymentService();
