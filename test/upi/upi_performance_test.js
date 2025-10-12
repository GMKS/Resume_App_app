/**
 * UPI Payment Service Performance Tests
 * Load testing and performance benchmarks for UPI payments
 */

const request = require("supertest");
const app = require("../../server");
const mongoose = require("mongoose");
const { performance } = require("perf_hooks");
const { TEST_CONFIG } = require("./upi_payment_test");

describe("UPI Payment Performance Tests", () => {
  let authToken;

  beforeAll(async () => {
    // Setup test user and auth token (reuse from main test)
    const registerResponse = await request(app)
      .post("/api/register")
      .send({
        ...TEST_CONFIG.testUser,
        email: "perf-test@example.com",
      });

    const verifyResponse = await request(app)
      .post("/api/verify-otp")
      .send({
        email: "perf-test@example.com",
        otp: registerResponse.body.data.otp || "123456",
      });

    authToken = verifyResponse.body.token;
  });

  describe("Payment Intent Creation Performance", () => {
    test("Should create UPI payment intent under 500ms", async () => {
      const startTime = performance.now();

      const response = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "INR",
        })
        .expect(200);

      const endTime = performance.now();
      const duration = endTime - startTime;

      expect(response.body.success).toBe(true);
      expect(duration).toBeLessThan(500); // 500ms threshold
      console.log(`Payment intent creation took ${duration.toFixed(2)}ms`);
    });

    test("Should handle concurrent payment intent requests", async () => {
      const concurrentRequests = 10;
      const startTime = performance.now();

      const promises = Array.from({ length: concurrentRequests }, (_, i) =>
        request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp: i % 2 === 0 ? "googlepay" : "phonepe",
            currency: "INR",
          })
      );

      const results = await Promise.all(promises);
      const endTime = performance.now();
      const totalDuration = endTime - startTime;

      // All requests should succeed
      results.forEach((result) => {
        expect(result.status).toBe(200);
        expect(result.body.success).toBe(true);
      });

      // Average time per request should be reasonable
      const avgDuration = totalDuration / concurrentRequests;
      expect(avgDuration).toBeLessThan(1000); // 1s average threshold

      console.log(
        `${concurrentRequests} concurrent requests took ${totalDuration.toFixed(
          2
        )}ms total`
      );
      console.log(`Average: ${avgDuration.toFixed(2)}ms per request`);
    });
  });

  describe("UPI Apps Endpoint Performance", () => {
    test("Should return UPI apps under 100ms", async () => {
      const startTime = performance.now();

      const response = await request(app)
        .get("/api/payment/upi/apps")
        .expect(200);

      const endTime = performance.now();
      const duration = endTime - startTime;

      expect(response.body.success).toBe(true);
      expect(duration).toBeLessThan(100); // 100ms threshold for static data
      console.log(`UPI apps fetch took ${duration.toFixed(2)}ms`);
    });

    test("Should handle high-frequency UPI apps requests", async () => {
      const requestCount = 50;
      const promises = Array.from({ length: requestCount }, () =>
        request(app).get("/api/payment/upi/apps")
      );

      const startTime = performance.now();
      const results = await Promise.all(promises);
      const endTime = performance.now();

      const totalDuration = endTime - startTime;
      const avgDuration = totalDuration / requestCount;

      results.forEach((result) => {
        expect(result.status).toBe(200);
      });

      expect(avgDuration).toBeLessThan(50); // Very fast for cached data
      console.log(
        `${requestCount} UPI apps requests: ${avgDuration.toFixed(2)}ms average`
      );
    });
  });

  describe("Payment Flow End-to-End Performance", () => {
    test("Should complete full UPI payment flow under 2 seconds", async () => {
      const startTime = performance.now();

      // Step 1: Create payment intent
      const intentResponse = await request(app)
        .post("/api/payment/upi/create-intent")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          upiApp: "googlepay",
          currency: "INR",
        });

      const intentTime = performance.now();

      // Step 2: Verify payment
      const verifyResponse = await request(app)
        .post("/api/payment/upi/verify")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          planType: "monthly",
          amount: 299,
          currency: "INR",
          razorpayPaymentId: `pay_perf_${Date.now()}`,
          razorpayOrderId: intentResponse.body.data.paymentData.orderId,
          razorpaySignature: `sig_perf_${Date.now()}`,
          upiApp: "googlepay",
        });

      const endTime = performance.now();

      const intentDuration = intentTime - startTime;
      const verifyDuration = endTime - intentTime;
      const totalDuration = endTime - startTime;

      expect(intentResponse.body.success).toBe(true);
      expect(verifyResponse.body.success).toBe(true);
      expect(totalDuration).toBeLessThan(2000); // 2s total threshold

      console.log(`Payment intent: ${intentDuration.toFixed(2)}ms`);
      console.log(`Payment verify: ${verifyDuration.toFixed(2)}ms`);
      console.log(`Total flow: ${totalDuration.toFixed(2)}ms`);
    });
  });

  describe("Memory and Resource Usage", () => {
    test("Should not leak memory during multiple UPI operations", async () => {
      const initialMemory = process.memoryUsage();

      // Perform many UPI operations
      for (let i = 0; i < 20; i++) {
        await request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp: i % 2 === 0 ? "googlepay" : "phonepe",
            currency: "INR",
          });
      }

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }

      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;

      // Memory increase should be reasonable (less than 10MB)
      expect(memoryIncrease).toBeLessThan(10 * 1024 * 1024);

      console.log(
        `Memory increase: ${(memoryIncrease / 1024 / 1024).toFixed(2)}MB`
      );
    });
  });

  describe("Database Performance", () => {
    test("Should handle UPI payment database operations efficiently", async () => {
      const dbOperationTimes = [];

      for (let i = 0; i < 5; i++) {
        const startTime = performance.now();

        await request(app)
          .post("/api/payment/upi/create-intent")
          .set("Authorization", `Bearer ${authToken}`)
          .send({
            planType: "monthly",
            upiApp: "googlepay",
            currency: "INR",
          });

        const endTime = performance.now();
        dbOperationTimes.push(endTime - startTime);
      }

      const avgDbTime =
        dbOperationTimes.reduce((a, b) => a + b, 0) / dbOperationTimes.length;
      const maxDbTime = Math.max(...dbOperationTimes);

      expect(avgDbTime).toBeLessThan(300); // 300ms average
      expect(maxDbTime).toBeLessThan(500); // 500ms max

      console.log(
        `DB operations - Avg: ${avgDbTime.toFixed(
          2
        )}ms, Max: ${maxDbTime.toFixed(2)}ms`
      );
    });
  });
});
