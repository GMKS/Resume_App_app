const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 100,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        "Please enter a valid email",
      ],
    },

    phone: {
      type: String,
      unique: true,
      sparse: true, // Allow null values but enforce uniqueness when present
      trim: true,
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
    },

    // Email/Phone verification
    verified: {
      type: Boolean,
      default: false,
    },

    otp: {
      type: Number,
    },

    otpExpiry: {
      type: Date,
    },

    // Payment provider customer IDs
    stripeCustomerId: {
      type: String,
    },

    razorpayCustomerId: {
      type: String,
    },

    paypalCustomerId: {
      type: String,
    },

    // User preferences and analytics
    country: {
      type: String,
    },

    currency: {
      type: String,
      default: "USD",
    },

    timezone: {
      type: String,
    },

    // Authentication and security
    lastLoginAt: {
      type: Date,
    },

    loginAttempts: {
      type: Number,
      default: 0,
    },

    lockUntil: {
      type: Date,
    },

    // Analytics and tracking
    signupSource: {
      type: String, // 'web', 'ios', 'android', 'referral'
      default: "web",
    },

    referralCode: {
      type: String,
    },

    referredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    // User activity
    lastActiveAt: {
      type: Date,
      default: Date.now,
    },

    resumeCount: {
      type: Number,
      default: 0,
    },

    // Notifications and preferences
    emailNotifications: {
      type: Boolean,
      default: true,
    },

    marketingEmails: {
      type: Boolean,
      default: false,
    },

    // Account status
    isActive: {
      type: Boolean,
      default: true,
    },

    isDeleted: {
      type: Boolean,
      default: false,
    },

    deletedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance and uniqueness
userSchema.index({ email: 1 });
userSchema.index({ phone: 1 });
userSchema.index({ stripeCustomerId: 1 });
userSchema.index({ razorpayCustomerId: 1 });
userSchema.index({ createdAt: -1 });
userSchema.index({ lastActiveAt: -1 });

// Virtual for account lock status
userSchema.virtual("isLocked").get(function () {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Pre-save middleware to hash password
userSchema.pre("save", async function (next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified("password")) return next();

  try {
    // Hash password with cost of 12
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Method to generate OTP
userSchema.methods.generateOTP = function () {
  const otp = Math.floor(100000 + Math.random() * 900000);
  this.otp = otp;
  this.otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return otp;
};

// Method to verify OTP
userSchema.methods.verifyOTP = function (candidateOTP) {
  if (!this.otp || !this.otpExpiry) {
    return false;
  }

  if (this.otpExpiry < new Date()) {
    return false; // OTP expired
  }

  return this.otp === parseInt(candidateOTP);
};

// Method to clear OTP
userSchema.methods.clearOTP = function () {
  this.otp = undefined;
  this.otpExpiry = undefined;
};

// Method to increment login attempts
userSchema.methods.incLoginAttempts = function () {
  // If we have a previous lock that has expired, restart at 1
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return this.updateOne({
      $unset: { lockUntil: 1 },
      $set: { loginAttempts: 1 },
    });
  }

  const updates = { $inc: { loginAttempts: 1 } };

  // Lock account after 5 attempts for 2 hours
  if (this.loginAttempts + 1 >= 5 && !this.isLocked) {
    updates.$set = { lockUntil: Date.now() + 2 * 60 * 60 * 1000 };
  }

  return this.updateOne(updates);
};

// Method to reset login attempts
userSchema.methods.resetLoginAttempts = function () {
  return this.updateOne({
    $unset: { loginAttempts: 1, lockUntil: 1 },
  });
};

// Method to update last active timestamp
userSchema.methods.updateLastActive = function () {
  this.lastActiveAt = new Date();
  return this.save();
};

// Static method to find by email or phone
userSchema.statics.findByEmailOrPhone = function (identifier) {
  const isEmail = identifier.includes("@");
  const query = isEmail
    ? { email: identifier.toLowerCase() }
    : { phone: identifier };
  return this.findOne(query);
};

// Static method to get user analytics
userSchema.statics.getUserAnalytics = async function (startDate, endDate) {
  return await this.aggregate([
    {
      $match: {
        createdAt: {
          $gte: startDate,
          $lte: endDate,
        },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
        },
        signups: { $sum: 1 },
        verifiedUsers: {
          $sum: { $cond: [{ $eq: ["$verified", true] }, 1, 0] },
        },
      },
    },
    { $sort: { _id: 1 } },
  ]);
};

// Static method to clean up expired OTPs
userSchema.statics.cleanupExpiredOTPs = async function () {
  return await this.updateMany(
    { otpExpiry: { $lt: new Date() } },
    { $unset: { otp: 1, otpExpiry: 1 } }
  );
};

module.exports = mongoose.model("User", userSchema);
