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

// Mock MongoDB connection (for demo - replace with real connection)
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

// Get User Resumes
app.get("/api/resumes", authenticateToken, (req, res) => {
  try {
    const userResumes = resumes.filter((r) => r.userId === req.user.userId);
    res.json({ success: true, data: userResumes });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Create Resume
app.post("/api/resumes", authenticateToken, (req, res) => {
  try {
    const resume = {
      id: resumes.length + 1,
      userId: req.user.userId,
      ...req.body,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    resumes.push(resume);
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
app.put("/api/resumes/:id", authenticateToken, (req, res) => {
  try {
    const resumeId = parseInt(req.params.id);
    const resumeIndex = resumes.findIndex(
      (r) => r.id === resumeId && r.userId === req.user.userId
    );

    if (resumeIndex === -1) {
      return res
        .status(404)
        .json({ success: false, message: "Resume not found" });
    }

    resumes[resumeIndex] = {
      ...resumes[resumeIndex],
      ...req.body,
      updatedAt: new Date(),
    };

    res.json({
      success: true,
      message: "Resume updated successfully",
      data: resumes[resumeIndex],
    });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Delete Resume
app.delete("/api/resumes/:id", authenticateToken, (req, res) => {
  try {
    const resumeId = parseInt(req.params.id);
    const resumeIndex = resumes.findIndex(
      (r) => r.id === resumeId && r.userId === req.user.userId
    );

    if (resumeIndex === -1) {
      return res
        .status(404)
        .json({ success: false, message: "Resume not found" });
    }

    resumes.splice(resumeIndex, 1);
    res.json({ success: true, message: "Resume deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Resume Builder API Server running on port ${PORT}`);
  console.log(`📱 API Base URL: http://localhost:${PORT}`);
  console.log(`🌐 Network API URL: http://YOUR_IP:${PORT}`);
  console.log(`🔗 Health Check: http://localhost:${PORT}/`);
  console.log(`\n📋 Available Endpoints:`);
  console.log(`   POST /api/register - User registration`);
  console.log(`   POST /api/login - User login`);
  console.log(`   POST /api/verify-otp - OTP verification`);
  console.log(`   GET /api/resumes - Get user resumes`);
  console.log(`   POST /api/resumes - Create resume`);
  console.log(`   PUT /api/resumes/:id - Update resume`);
  console.log(`   DELETE /api/resumes/:id - Delete resume`);
  console.log(`\n🎯 Ready for Flutter app connections!`);
  console.log(
    `\n📲 For Android testing, use your computer's IP address instead of localhost`
  );
});
