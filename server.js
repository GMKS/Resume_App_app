const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
require("dotenv").config();
const app = express();



// Middleware
app.use(cors());
app.use(express.json());

// Diagnose malformed JSON early (express.json will 400 by default with html)
app.use((err, req, res, next) => {
  if (err && err.type === "entity.parse.failed") {
    return res.status(400).json({
      success: false,
      message: "Invalid JSON payload",
      error: err.message,
    });
  }
  next(err);
});

// Import models
const User = require("./models/User");
const Resume = require("./models/Resume");
const Subscription = require("./models/Subscription");
const PaymentTransaction = require("./models/PaymentTransaction");

// Import services
const PaymentService = require("./services/PaymentService");
const SubscriptionService = require("./services/SubscriptionService");

// MongoDB connection
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/resume_builder";

const maskUri = (uri) => {
  try {
    const u = new URL(uri);
    if (u.password) u.password = "***";
    if (u.username) u.username = "***";
    return `${u.protocol}//${u.username ? "***@" : ""}${u.host}${u.pathname}`;
  } catch (_) {
    return uri.includes("@") ? uri.replace(/:\w+@/, ":***@") : uri;
  }
};

const isCloud = process.env.RENDER || process.env.RAILWAY || process.env.PORT;
if (isCloud && !process.env.MONGODB_URI) {
  console.warn(
    "⚠️ Running in a cloud/container environment without MONGODB_URI. Defaulting to localhost which will fail. Set MONGODB_URI to your MongoDB/Atlas connection string."
  );
}

console.log("🚀 Connecting to MongoDB:", maskUri(MONGODB_URI));
const connectMongo = () =>
  mongoose
    .connect(MONGODB_URI, {
      // modern drivers don't require many options; add a reasonable timeout
      serverSelectionTimeoutMS: 10000,
    })
    .then(() => {
      console.log(
        "✅ MongoDB connected successfully to:",
        mongoose.connection.db.databaseName
      );
    })
    .catch((error) => {
      console.error("❌ MongoDB connection error:", error.message);
      console.log("🔄 Retrying connection in 5 seconds...");
      setTimeout(() => {
        connectMongo();
      }, 5000);
    });

connectMongo();

// Handle MongoDB connection events
mongoose.connection.on("disconnected", () => {
  console.log("⚠️ MongoDB disconnected. Attempting to reconnect...");
});

mongoose.connection.on("reconnected", () => {
  console.log("✅ MongoDB reconnected successfully");
});

// DB health endpoint for diagnostics
app.get("/api/health/db", async (req, res) => {
  try {
    const state = mongoose.connection.readyState; // 0=disconnected,1=connected,2=connecting,3=disconnecting
    const name = mongoose.connection.db?.databaseName;
    return res.json({
      success: state === 1,
      state,
      database: name || null,
      uri: maskUri(MONGODB_URI),
    });
  } catch (e) {
    return res.status(500).json({ success: false, error: e.message });
  }
});

// Mock/in-memory collections (used by current auth/OTP routes).
// NOTE: These are used for demo/development flows. The project also includes
// Mongoose models (User/Resume), which can replace these arrays in a future
// refactor. Keeping these ensures routes below don't crash with users is not defined.
const users = [];
const resumes = [];

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || "dev-secret-change-me";
// Control exposing OTPs in API responses (for local testing only)
const EXPOSE_OTP = process.env.EXPOSE_OTP === "true";

// Email transporter setup (optional - for production use real credentials)
let transporter = null;
if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
  transporter = nodemailer.createTransport({
    service: process.env.EMAIL_SERVICE || "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
  console.log(
    "✉️ Email transporter configured for:",
    process.env.EMAIL_SERVICE || "gmail"
  );
} else {
  console.log(
    "✉️ Email transporter not configured - OTPs will be logged to console only (dev mode)"
  );
}

// Routes

// Health check
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Resume Builder API is running!",
    timestamp: new Date().toISOString(),
    endpoints: [
      "POST /api/register - User registration",
      "POST /api/login - User login",
      "POST /api/verify-otp - OTP verification",
      "POST /api/auth/send-otp - Send OTP to existing user",
      "GET /api/auth/verify-token - Verify access token",
      "GET /api/resumes - Get user resumes",
      "POST /api/resumes - Create resume",
      "PUT /api/resumes/:id - Update resume",
      "DELETE /api/resumes/:id - Delete resume",
    ],
  });
});

// API root (handy for quick browser checks)
app.get("/api", (req, res) => {
  res.json({
    success: true,
    message: "API root",
    hint: "See / for a list of endpoints or /api/health/db for DB health",
  });
});

// Auth health/echo endpoint to verify JSON handling remotely
app.post("/api/auth/health", (req, res) => {
  return res.json({ success: true, message: "Auth OK", echo: req.body || {} });
});

// User Registration
app.post("/api/register", async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    // Check if user exists
    const existingUser = users.find((u) => u.email === email);
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = {
      id: users.length + 1,
      name,
      email,
      password: hashedPassword,
      phone,
      verified: false,
      createdAt: new Date(),
    };

    users.push(user);

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000);
    user.otp = otp;
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Send OTP (dev: log to console; prod: send email/SMS if transporter is set)
    if (transporter) {
      try {
        await transporter.sendMail({
          from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
          to: email,
          subject: "Your OTP Code",
          text: `Your verification code is ${otp}`,
        });
      } catch (mailErr) {
        console.warn(
          "Email send failed, falling back to console log:",
          mailErr.message
        );
        console.log(`OTP for ${email}: ${otp}`);
      }
    } else {
      console.log(`OTP for ${email}: ${otp}`);
    }

    const response = {
      success: true,
      message: "User registered successfully. OTP sent to email.",
      data: {
        userId: user.id,
      },
    };
    if (EXPOSE_OTP) {
      response.data.otp = otp;
    }
    res.status(201).json(response);
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// User Login
app.post("/api/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = users.find((u) => u.email === email);
    if (!user) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid credentials" });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid credentials" });
    }

    // Check if verified; if not, send/resend OTP automatically
    if (!user.verified) {
      const otp = Math.floor(100000 + Math.random() * 900000);
      user.otp = otp;
      user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

      if (transporter) {
        try {
          await transporter.sendMail({
            from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
            to: user.email,
            subject: "Your OTP Code",
            text: `Your verification code is ${otp}`,
          });
        } catch (mailErr) {
          console.warn(
            "Email send failed during login, falling back to console log:",
            mailErr.message
          );
          console.log(`OTP for ${user.email}: ${otp}`);
        }
      } else {
        console.log(`OTP for ${user.email}: ${otp}`);
      }

      const payload = {
        success: false,
        message:
          "Please verify your email first. We've sent a verification code to your email.",
      };
      if (EXPOSE_OTP) payload.data = { otp };
      return res.status(400).json(payload);
    }

    // Generate JWT
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: "24h",
    });

    res.json({
      success: true,
      message: "Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Verify OTP (supports email or phone via `identifier`)
app.post("/api/verify-otp", (req, res) => {
  try {
    const { identifier, email, phone, otp } = req.body;
    const id = email || phone || identifier; // Use identifier for flexibility
    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Identifier (email or phone) is required",
      });
    }

    const isEmail = typeof id === "string" && id.includes("@");

    // Find user
    const user = users.find((u) => (isEmail ? u.email === id : u.phone === id));
    if (!user) {
      return res
        .status(400)
        .json({ success: false, message: "User not found" });
    }

    // Check OTP
    if (user.otp !== parseInt(otp) || new Date() > user.otpExpiry) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid or expired OTP" });
    }

    // Verify user
    user.verified = true;
    delete user.otp;
    delete user.otpExpiry;

    // Generate JWT
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: "24h",
    });

    res.json({
      success: true,
      message: "Verification successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res
      .status(401)
      .json({ success: false, message: "Access token required" });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: "Invalid token" });
    }
    req.user = user;
    next();
  });
};

// Send OTP to existing user (for login/reset) using email or phone as identifier
app.post("/api/auth/send-otp", (req, res) => {
  try {
    const { identifier, email, phone } = req.body;
    const id = email || phone || identifier; // Use identifier for flexibility
    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Identifier (email or phone) is required",
      });
    }

    const isEmail = typeof id === "string" && id.includes("@");
    const user = users.find((u) => (isEmail ? u.email === id : u.phone === id));
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000);
    user.otp = otp;
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    if (transporter && isEmail) {
      transporter
        .sendMail({
          from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
          to: user.email,
          subject: "Your OTP Code",
          text: `Your verification code is ${otp}`,
        })
        .catch((e) =>
          console.warn("Email send failed (send-otp), using console log:", e)
        );
    }

    console.log(`OTP for ${isEmail ? user.email : user.phone}: ${otp}`);

    const payload = {
      success: true,
      message: "OTP sent successfully",
    };
    if (EXPOSE_OTP) payload.data = { otp };
    return res.json(payload);
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Verify access token
app.get("/api/auth/verify-token", authenticateToken, (req, res) => {
  return res.json({ success: true, message: "Token is valid" });
});

// Get User Resumes (MongoDB, paginated)
app.get("/api/resumes", authenticateToken, async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit) || 10, 1), 100);
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Resume.find({ userId: req.user.userId })
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit),
      Resume.countDocuments({ userId: req.user.userId }),
    ]);

    res.json({
      success: true,
      data: items,
      meta: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit) || 1,
      },
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Create Resume (MongoDB)
app.post("/api/resumes", authenticateToken, async (req, res) => {
  try {
    const {
      title,
      template,
      personalInfo,
      summary,
      workExperience,
      education,
      skills,
      data,
    } = req.body;

    const resume = await Resume.create({
      userId: req.user.userId,
      title,
      template,
      personalInfo,
      summary,
      workExperience,
      education,
      skills,
      data,
    });

    res.status(201).json({
      success: true,
      message: "Resume created successfully",
      data: resume,
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Update Resume
app.put("/api/resumes/:id", authenticateToken, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const resume = await Resume.findOneAndUpdate(
      { _id: resumeId, userId: req.user.userId },
      { ...req.body },
      { new: true, runValidators: true }
    );

    if (!resume) {
      return res
        .status(404)
        .json({ success: false, message: "Resume not found" });
    }

    res.json({
      success: true,
      message: "Resume updated successfully",
      data: resume,
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Delete Resume
app.delete("/api/resumes/:id", authenticateToken, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const resume = await Resume.findOneAndDelete({
      _id: resumeId,
      userId: req.user.userId,
    });

    if (!resume) {
      return res
        .status(404)
        .json({ success: false, message: "Resume not found" });
    }

    res.json({ success: true, message: "Resume deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// =============================================================================
// PAYMENT & SUBSCRIPTION ROUTES
// =============================================================================

// Get user subscription status
app.get("/api/subscription/status", authenticateToken, async (req, res) => {
  try {
    const subscriptionData = await SubscriptionService.getUserSubscription(
      req.user.userId
    );
    res.json({ success: true, data: subscriptionData });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get subscription status",
      error: error.message,
    });
  }
});

// Check trial eligibility
app.get(
  "/api/subscription/trial/eligibility",
  authenticateToken,
  async (req, res) => {
    try {
      const eligibility = await SubscriptionService.canStartTrial(
        req.user.userId
      );
      res.json({ success: true, data: eligibility });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Failed to check trial eligibility",
        error: error.message,
      });
    }
  }
);

// Start free trial
app.post(
  "/api/subscription/trial/start",
  authenticateToken,
  async (req, res) => {
    try {
      const trialData = await SubscriptionService.startTrial(req.user.userId);
      res.json({
        success: true,
        message: "Trial started successfully",
        data: trialData,
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// Get subscription plans and pricing
app.get("/api/subscription/plans", async (req, res) => {
  try {
    const currency = req.query.currency || "USD";
    const pricing = PaymentService.getPricing(currency);

    const plans = [
      {
        id: "monthly",
        name: "Monthly Premium",
        price: pricing.monthly,
        currency,
        interval: "month",
        features: [
          "All 6 professional templates",
          "Unlimited resumes",
          "Export to PDF, DOCX, TXT",
          "No watermarks",
          "Cloud storage",
          "AI-powered content",
          "Priority support",
        ],
      },
      {
        id: "yearly",
        name: "Yearly Premium",
        price: pricing.yearly,
        currency,
        interval: "year",
        discount: 58,
        popular: true,
        features: [
          "All Monthly features",
          "Save 58% annually",
          "Advanced AI features",
          "Custom branding",
          "Video resume support",
        ],
      },
      {
        id: "lifetime",
        name: "Lifetime Premium",
        price: pricing.lifetime,
        currency,
        interval: "lifetime",
        bestValue: true,
        features: [
          "All Premium features forever",
          "One-time payment",
          "Future updates included",
          "Unlimited everything",
          "Premium support for life",
        ],
      },
    ];

    res.json({ success: true, data: { plans, currency } });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get subscription plans",
      error: error.message,
    });
  }
});

// Create payment intent
app.post("/api/payment/create-intent", authenticateToken, async (req, res) => {
  try {
    const {
      planType,
      currency = "USD",
      paymentProvider,
      paymentMethod = "auto",
    } = req.body;

    if (!planType || !["monthly", "yearly", "lifetime"].includes(planType)) {
      return res.status(400).json({
        success: false,
        message: "Invalid plan type",
      });
    }

    const paymentData = await SubscriptionService.createPaymentIntent(
      req.user.userId,
      planType,
      currency,
      paymentProvider,
      paymentMethod
    );

    res.json({ success: true, data: paymentData });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to create payment intent",
      error: error.message,
    });
  }
});

// Verify payment and activate subscription
app.post("/api/payment/verify", authenticateToken, async (req, res) => {
  try {
    const {
      paymentProvider,
      planType,
      amount,
      currency,
      // Stripe
      paymentIntentId,
      // Razorpay
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
      // PayPal
      paypalOrderId,
      // Test mode
      testMode,
    } = req.body;

    let verificationResult;
    let providerTransactionId;

    // Verify payment based on provider
    switch (paymentProvider) {
      case "stripe":
        verificationResult = await PaymentService.verifyStripePayment(
          paymentIntentId
        );
        providerTransactionId = paymentIntentId;
        break;

      case "razorpay":
        verificationResult = await PaymentService.verifyRazorpayPayment(
          razorpayPaymentId,
          razorpayOrderId,
          razorpaySignature
        );
        providerTransactionId = razorpayPaymentId;
        break;

      case "paypal":
        verificationResult = await PaymentService.verifyPayPalPayment(
          paypalOrderId
        );
        providerTransactionId = paypalOrderId;
        break;

      case "test":
        if (testMode && process.env.NODE_ENV !== "production") {
          verificationResult = { success: true, status: "test_success" };
          providerTransactionId = `test_${Date.now()}`;
        } else {
          throw new Error("Test payments not allowed in production");
        }
        break;

      default:
        throw new Error("Invalid payment provider");
    }

    if (!verificationResult.success) {
      return res.status(400).json({
        success: false,
        message: "Payment verification failed",
        error: verificationResult.error,
      });
    }

    // Activate subscription
    const subscriptionData = await SubscriptionService.activateSubscription(
      req.user.userId,
      {
        planType,
        amount: verificationResult.amount || amount,
        currency: verificationResult.currency || currency,
        provider: paymentProvider,
        providerTransactionId,
      },
      {
        paymentMethod: verificationResult.paymentMethod,
        deviceInfo: {
          platform: req.headers["x-platform"] || "unknown",
          appVersion: req.headers["x-app-version"],
          country: req.headers["x-country"],
          ipAddress: req.ip,
        },
      }
    );

    res.json({
      success: true,
      message: "Payment verified and subscription activated",
      data: subscriptionData,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Cancel subscription
app.post("/api/subscription/cancel", authenticateToken, async (req, res) => {
  try {
    const { reason = "user_request" } = req.body;

    const result = await SubscriptionService.cancelSubscription(
      req.user.userId,
      reason
    );
    res.json({
      success: true,
      message: "Subscription cancelled successfully",
      data: result,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Get payment history
app.get("/api/payment/history", authenticateToken, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const transactions = await PaymentTransaction.getUserTransactions(
      req.user.userId,
      limit
    );

    res.json({ success: true, data: transactions });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get payment history",
      error: error.message,
    });
  }
});

// Webhook endpoints for payment providers
app.post(
  "/api/webhooks/stripe",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["stripe-signature"];
      const event = PaymentService.verifyWebhook(req.body, signature, "stripe");

      // Handle different event types
      switch (event.type) {
        case "payment_intent.succeeded":
          console.log("💳 Stripe payment succeeded:", event.data.object.id);
          break;
        case "payment_intent.payment_failed":
          console.log("❌ Stripe payment failed:", event.data.object.id);
          break;
        case "customer.subscription.deleted":
          console.log(
            "🚫 Stripe subscription cancelled:",
            event.data.object.id
          );
          break;
      }

      res.json({ received: true });
    } catch (error) {
      console.error("Stripe webhook error:", error);
      res.status(400).send(`Webhook Error: ${error.message}`);
    }
  }
);

app.post("/api/webhooks/razorpay", async (req, res) => {
  try {
    const signature = req.headers["x-razorpay-signature"];
    const isValid = PaymentService.verifyWebhook(
      req.body,
      signature,
      "razorpay"
    );

    if (!isValid) {
      return res.status(400).send("Invalid signature");
    }

    const event = req.body;
    console.log(
      "💳 Razorpay webhook event:",
      event.event,
      event.payload.payment.entity.id
    );

    res.json({ status: "ok" });
  } catch (error) {
    console.error("Razorpay webhook error:", error);
    res.status(400).send(`Webhook Error: ${error.message}`);
  }
});

// =============================================================================
// UPI PAYMENT ENDPOINTS (INDIAN USERS)
// =============================================================================

// Get available UPI apps
app.get("/api/payment/upi/apps", (req, res) => {
  try {
    const upiApps = {
      googlepay: {
        name: "Google Pay",
        package: "com.google.android.apps.nbu.paisa.user",
        icon: "💳",
        color: "4285F4",
        supported: true,
      },
      phonepe: {
        name: "PhonePe",
        package: "com.phonepe.app",
        icon: "📱",
        color: "5F259F",
        supported: true,
      },
      paytm: {
        name: "Paytm",
        package: "net.one97.paytm",
        icon: "💰",
        color: "00BAF2",
        supported: true,
      },
      amazonpay: {
        name: "Amazon Pay",
        package: "in.amazon.mShop.android.shopping",
        icon: "🛒",
        color: "FF9900",
        supported: true,
      },
      mobikwik: {
        name: "MobiKwik",
        package: "com.mobikwik_new",
        icon: "🔵",
        color: "E91E63",
        supported: true,
      },
    };

    res.json({
      success: true,
      data: upiApps,
      message: "UPI apps available for Indian users",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get UPI apps",
      error: error.message,
    });
  }
});

// Create UPI payment intent
app.post(
  "/api/payment/upi/create-intent",
  authenticateToken,
  async (req, res) => {
    try {
      const { planType, upiApp = "googlepay", currency = "INR" } = req.body;

      if (!planType || !["monthly", "yearly", "lifetime"].includes(planType)) {
        return res.status(400).json({
          success: false,
          message: "Invalid plan type",
        });
      }

      // Ensure currency is INR for UPI payments
      if (currency !== "INR") {
        return res.status(400).json({
          success: false,
          message: "UPI payments only support INR currency",
        });
      }

      const paymentData = await SubscriptionService.createPaymentIntent(
        req.user.userId,
        planType,
        currency,
        "razorpay", // Force Razorpay for UPI
        upiApp // Pass UPI app preference
      );

      res.json({
        success: true,
        data: {
          ...paymentData,
          upiApp,
          paymentMethod: "upi",
        },
        message: `UPI payment intent created for ${upiApp}`,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Failed to create UPI payment intent",
        error: error.message,
      });
    }
  }
);

// Verify UPI payment
app.post("/api/payment/upi/verify", authenticateToken, async (req, res) => {
  try {
    const {
      planType,
      amount,
      currency = "INR",
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature,
      upiApp,
    } = req.body;

    // Verify payment using existing Razorpay verification
    const verificationResult = await PaymentService.verifyRazorpayPayment(
      razorpayPaymentId,
      razorpayOrderId,
      razorpaySignature
    );

    if (!verificationResult.success) {
      return res.status(400).json({
        success: false,
        message: "UPI payment verification failed",
        error: verificationResult.error,
      });
    }

    // Activate subscription with UPI payment method info
    const subscriptionData = await SubscriptionService.activateSubscription(
      req.user.userId,
      {
        planType,
        amount: verificationResult.amount || amount,
        currency: verificationResult.currency || currency,
        provider: "razorpay",
        providerTransactionId: razorpayPaymentId,
      },
      {
        paymentMethod: {
          type: "upi",
          upiApp,
          method: verificationResult.paymentMethod?.method || "upi",
        },
        deviceInfo: {
          platform: req.headers["x-platform"] || "android",
          appVersion: req.headers["x-app-version"],
          country: "IN",
          ipAddress: req.ip,
        },
      }
    );

    res.json({
      success: true,
      message: `UPI payment verified successfully via ${upiApp}`,
      data: {
        ...subscriptionData,
        paymentMethod: "upi",
        upiApp,
      },
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Check UPI payment status
app.get(
  "/api/payment/upi/status/:paymentId",
  authenticateToken,
  async (req, res) => {
    try {
      const { paymentId } = req.params;

      // Get payment status from Razorpay
      const paymentStatus = await PaymentService.getPaymentStatus(
        paymentId,
        "razorpay"
      );

      res.json({
        success: true,
        data: paymentStatus,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Failed to get UPI payment status",
        error: error.message,
      });
    }
  }
);

// Testing endpoints (remove in production)
if (process.env.NODE_ENV !== "production") {
  // Test subscription activation
  app.post(
    "/api/test/activate-premium",
    authenticateToken,
    async (req, res) => {
      try {
        const { planType = "monthly" } = req.body;

        const subscriptionData = await SubscriptionService.activateSubscription(
          req.user.userId,
          {
            planType,
            amount: 0,
            currency: "USD",
            provider: "test",
            providerTransactionId: `test_${Date.now()}`,
          },
          {
            paymentMethod: { type: "test" },
            deviceInfo: { platform: "test" },
          }
        );

        res.json({
          success: true,
          message: "Test premium activated",
          data: subscriptionData,
        });
      } catch (error) {
        res.status(400).json({
          success: false,
          message: error.message,
        });
      }
    }
  );

  // Test subscription renewal
  app.post(
    "/api/test/renew-subscription",
    authenticateToken,
    async (req, res) => {
      try {
        const result = await SubscriptionService.renewSubscription(
          req.user.userId
        );
        res.json({
          success: true,
          message: "Subscription renewed for testing",
          data: result,
        });
      } catch (error) {
        res.status(400).json({
          success: false,
          message: error.message,
        });
      }
    }
  );
}

// Start server with auto-fallback if port is busy
const DEFAULT_PORT = parseInt(process.env.PORT || 3000, 10);
function startServer(port, retriesLeft = 3) {
  const server = app.listen(port, "0.0.0.0", () => {
    const actualPort = server.address().port;
    console.log(`✅ Resume Builder API Server running on port ${actualPort}`);
    console.log(`📱 API Base URL: http://localhost:${actualPort}`);
    console.log(`🌐 Network API URL: http://YOUR_IP:${actualPort}`);
    console.log(`🔗 Health Check: http://localhost:${actualPort} /`);
    console.log(`\n📋 Available Endpoints:`);
    console.log(`   📝 Authentication:`);
    console.log(`      POST /api/register - User registration`);
    console.log(`      POST /api/login - User login`);
    console.log(`      POST /api/verify-otp - OTP verification`);
    console.log(`   📄 Resume Management:`);
    console.log(`      GET /api/resumes - Get user resumes`);
    console.log(`      POST /api/resumes - Create resume`);
    console.log(`      PUT /api/resumes/:id - Update resume`);
    console.log(`      DELETE /api/resumes/:id - Delete resume`);
    console.log(`   💳 Payment & Subscriptions:`);
    console.log(`      GET /api/subscription/status - Get subscription status`);
    console.log(`      GET /api/subscription/plans - Get pricing plans`);
    console.log(`      POST /api/subscription/trial/start - Start free trial`);
    console.log(`      POST /api/payment/create-intent - Create payment intent`);
    console.log(`      POST /api/payment/verify - Verify payment`);
    console.log(`      POST /api/subscription/cancel - Cancel subscription`);
    console.log(`      GET /api/payment/history - Payment history`);
    console.log(`   🔗 Webhooks:`);
    console.log(`      POST /api/webhooks/stripe - Stripe webhooks`);
    console.log(`      POST /api/webhooks/razorpay - Razorpay webhooks`);
    console.log(`\n🎯 Ready for Flutter app connections!`);
    console.log(
      `\n📲 For Android testing, use your computer's IP address instead of localhost`
    );
  });

  server.on("error", (err) => {
    if (err && err.code === "EADDRINUSE" && retriesLeft > 0) {
      console.warn(
        `⚠️  Port ${port} is in use. Retrying on ${port + 1} (retries left: ${
          retriesLeft - 1
        })...`
      );
      setTimeout(() => startServer(port + 1, retriesLeft - 1), 500);
    } else {
      console.error("❌ Failed to start server:", err.message || err);
      process.exit(1);
    }
  });
}

startServer(DEFAULT_PORT);
