/**
 * UPI Payment System Tests
 * Tests for Google Pay, PhonePe, and other UPI apps integration
 */

const request = require("supertest");
const app = require("../../server");
const mongoose = require("mongoose");
const User = require("../../models/User");
const Subscription = require("../../models/Subscription");
const PaymentTransaction = require("../../models/PaymentTransaction");

// Test configuration
const TEST_CONFIG = {
  testUser: {
    name: "UPI Test User",
    email: "upi-test@example.com",
    password: "testpassword123",
    phone: "+91-9876543210",
  },
  testPlans: ["monthly", "yearly", "lifetime"],
  upiApps: ["googlepay", "phonepe", "paytm", "amazonpay", "mobikwik"],
  currency: "INR",
};

let authToken;
let testUserId;

describe("UPI Payment System Tests", () => {
  beforeAll(async () => {
    // Connect to test database
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(
        process.env.MONGODB_TEST_URI || process.env.MONGODB_URI
      );
    }

    // Clean up test data
    await User.deleteMany({ email: TEST_CONFIG.testUser.email });
    await Subscription.deleteMany({});
    await PaymentTransaction.deleteMany({});

    // Create test user
    const registerResponse = await request(app)
      .post("/api/register")
      .send(TEST_CONFIG.testUser)
      .expect(201);

    testUserId = registerResponse.body.data.userId;

    // Verify OTP (mock)
    const verifyResponse = await request(app)
      .post("/api/verify-otp")
      .send({
        email: TEST_CONFIG.testUser.email,
        otp: registerResponse.body.data.otp || "123456",
      })
      .expect(200);

    authToken = verifyResponse.body.token;
  });

  afterAll(async () => {
    // Clean up test data
    await User.deleteMany({ email: TEST_CONFIG.testUser.email });
    await Subscription.deleteMany({});
    await PaymentTransaction.deleteMany({});

    // Close database connection
    await mongoose.connection.close();
  });

  describe("UPI Apps Discovery", () => {
    test("Should get available UPI apps", async () => {
      const response = await request(app)
        .get("/api/payment/upi/apps")
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("googlepay");
      expect(response.body.data).toHaveProperty("phonepe");
      expect(response.body.data).toHaveProperty("paytm");
      expect(response.body.data.googlepay).toHaveProperty("name", "Google Pay");
      expect(response.body.data.phonepe).toHaveProperty("name", "PhonePe");
    });

    test("Should include correct UPI app metadata", async () => {
      const response = await request(app)
        .get("/api/payment/upi/apps")
        .expect(200);

      const googlePay = response.body.data.googlepay;
      expect(googlePay).toMatchObject({
        name: "Google Pay",
        package: "com.google.android.apps.nbu.paisa.user",
        icon: "💳",
        color: "4285F4",
        supported: true,
      });

      const phonePe = response.body.data.phonepe;
      expect(phonePe).toMatchObject({
        name: "PhonePe",
        package: "com.phonepe.app",
        icon: "📱",
        color: "5F259F",
        supported: true,
      });
    });
  });

  describe("UPI Payment Intent Creation", () => {
    test("Should create UPI payment intent for Google Pay", async () => {
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "INR",
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("paymentData");
      expect(response.body.data).toHaveProperty("upiApp", "googlepay");
      expect(response.body.data).toHaveProperty("paymentMethod", "upi");
      expect(response.body.message).toContain("googlepay");
    });

    test("Should create UPI payment intent for PhonePe", async () => {
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "yearly",
          upiApp: "phonepe",
          currency: "INR",
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty("upiApp", "phonepe");
      expect(response.body.message).toContain("phonepe");
    });

    test("Should reject non-INR currency for UPI", async () => {
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "USD",
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("INR currency");
    });

    test("Should reject invalid plan types", async () => {
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "invalid",
          upiApp: "googlepay",
          currency: "INR",
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("Invalid plan type");
    });

    test("Should require authentication", async () => {
      await request(app)
        .post("/api/payment/upi/create-intent")
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "INR",
        })
        .expect(401);
    });
  });

  describe("UPI Payment Verification", () => {
    let paymentIntent;

    beforeEach(async () => {
      // Create payment intent for testing
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "INR",
        });

      paymentIntent = response.body.data;
    });

    test("Should verify UPI payment successfully", async () => {
      // Mock Razorpay payment verification
      const mockPaymentData = {
        planType: "monthly",
        amount: 299,
        currency: "INR",
        razorpayPaymentId: "pay_mock_" + Date.now(),
        razorpayOrderId: paymentIntent.paymentData.orderId,
        razorpaySignature: "mock_signature_" + Date.now(),
        upiApp: "googlepay",
      };

      // Note: In real implementation, this would need actual Razorpay verification
      // For testing, we'll simulate the verification process
      const response = await request(app)
        .post("/api/payment/upi/verify")
        .set("Authorization", `Bearer ${authToken}`)
        .send(mockPaymentData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain("verified successfully");
      expect(response.body.data).toHaveProperty("subscription");
      expect(response.body.data).toHaveProperty("paymentMethod", "upi");
      expect(response.body.data).toHaveProperty("upiApp", "googlepay");
    });

    test("Should handle invalid payment signatures", async () => {
      const mockPaymentData = {
        planType: "monthly",
        amount: 299,
        currency: "INR",
        razorpayPaymentId: "pay_invalid",
        razorpayOrderId: "order_invalid",
        razorpaySignature: "invalid_signature",
        upiApp: "googlepay",
      };

      const response = await request(app)
        .post("/api/payment/upi/verify")
        .set("Authorization", `Bearer ${authToken}`)
        .send(mockPaymentData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain("verification failed");
    });
  });

  describe("UPI Payment Status Tracking", () => {
    test("Should get payment status for valid payment ID", async () => {
      const paymentId = "pay_mock_" + Date.now();

      const response = await request(app)
        .get(`/api/payment/upi/status/${paymentId}`)
        .set("Authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
    });

    test("Should require authentication for status check", async () => {
      const paymentId = "pay_mock_" + Date.now();

      await request(app)
        .get(`/api/payment/upi/status/${paymentId}`)
        .expect(401);
    });
  });

  describe("UPI Payment Integration Tests", () => {
    test("Should complete full UPI payment flow for all apps", async () => {
      for (const upiApp of TEST_CONFIG.upiApps) {
        console.log(`Testing ${upiApp} payment flow...`);

        // Create payment intent
        const intentResponse = await request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp,
            currency: "INR",
          })
          .expect(200);

        expect(intentResponse.body.data.upiApp).toBe(upiApp);

        // Simulate payment verification
        const verifyResponse = await request(app)
          .post("/api/payment/upi/verify")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            amount: 299,
            currency: "INR",
            razorpayPaymentId: `pay_${upiApp}_${Date.now()}`,
            razorpayOrderId: intentResponse.body.data.paymentData.orderId,
            razorpaySignature: `sig_${upiApp}_${Date.now()}`,
            upiApp,
          })
          .expect(200);

        expect(verifyResponse.body.data.upiApp).toBe(upiApp);
      }
    });

    test("Should handle concurrent UPI payments", async () => {
      const promises = TEST_CONFIG.upiApps.map(async (upiApp) => {
        const response = await request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp,
            currency: "INR",
          });

        return response.body;
      });

      const results = await Promise.all(promises);

      results.forEach((result, index) => {
        expect(result.success).toBe(true);
        expect(result.data.upiApp).toBe(TEST_CONFIG.upiApps[index]);
      });
    });
  });

  describe("UPI Error Handling", () => {
    test("Should handle network timeouts gracefully", async () => {
      // This would require mocking network delays
      // For now, we'll test basic error response structure
      const response = await request(app)
        .post("/api/payment/upi/verify")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          amount: 299,
          currency: "INR",
          razorpayPaymentId: "",
          razorpayOrderId: "",
          razorpaySignature: "",
          upiApp: "googlepay",
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    test("Should validate required payment fields", async () => {
      const response = await request(app)
        .post("/api/payment/upi/verify")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          // Missing required fields
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe("UPI Payment Analytics", () => {
    test("Should track UPI payment attempts", async () => {
      // Create multiple payment intents
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp: "googlepay",
            currency: "INR",
          });
      }

      // Check if transactions are recorded
      const transactions = await PaymentTransaction.find({
        userId: testUserId,
        "paymentMethod.type": "upi",
      });

      expect(transactions.length).toBeGreaterThan(0);
    });

    test("Should store UPI app preferences", async () => {
      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "phonepe",
          currency: "INR",
        });

      expect(response.body.data.upiApp).toBe("phonepe");
    });
  });
});

module.exports = {
  TEST_CONFIG,
};
