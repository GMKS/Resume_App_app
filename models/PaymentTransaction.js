const mongoose = require("mongoose");

const paymentTransactionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    subscriptionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscription",
      required: true,
    },

    // Transaction Details
    transactionId: {
      type: String,
      required: true,
      unique: true,
    },

    amount: {
      type: Number,
      required: true,
    },

    currency: {
      type: String,
      default: "USD",
    },

    // Payment Provider Information
    paymentProvider: {
      type: String,
      enum: ["stripe", "razorpay", "paypal", "test"],
      required: true,
    },

    providerTransactionId: {
      type: String,
      required: true,
    },

    providerPaymentMethodId: {
      type: String,
    },

    // Transaction Status
    status: {
      type: String,
      enum: ["pending", "completed", "failed", "refunded", "cancelled"],
      default: "pending",
    },

    // Transaction Type
    type: {
      type: String,
      enum: ["subscription", "renewal", "upgrade", "refund"],
      default: "subscription",
    },

    // Payment Method Details
    paymentMethod: {
      type: {
        type: String,
        enum: ["card", "bank_transfer", "wallet", "upi", "other"],
      },
      last4: String,
      brand: String, // visa, mastercard, etc.
      country: String,
    },

    // Billing Address
    billingAddress: {
      name: String,
      email: String,
      phone: String,
      line1: String,
      line2: String,
      city: String,
      state: String,
      postalCode: String,
      country: String,
    },

    // Failure Information
    failureReason: {
      type: String,
    },

    failureCode: {
      type: String,
    },

    // Refund Information
    refundedAt: {
      type: Date,
    },

    refundAmount: {
      type: Number,
    },

    refundReason: {
      type: String,
    },

    // Provider-specific data
    providerData: {
      type: mongoose.Schema.Types.Mixed, // Store provider-specific response data
    },

    // Analytics
    deviceInfo: {
      platform: String, // iOS, Android, Web
      appVersion: String,
      country: String,
      ipAddress: String,
    },

    // Promotions
    promoCode: {
      type: String,
    },

    discountAmount: {
      type: Number,
      default: 0,
    },

    // Processing times
    processedAt: {
      type: Date,
    },

    completedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance and querying
paymentTransactionSchema.index({ userId: 1 });
paymentTransactionSchema.index({ subscriptionId: 1 });
paymentTransactionSchema.index({ transactionId: 1 });
paymentTransactionSchema.index({ providerTransactionId: 1 });
paymentTransactionSchema.index({ status: 1 });
paymentTransactionSchema.index({ paymentProvider: 1 });
paymentTransactionSchema.index({ createdAt: -1 });

// Virtual for formatted amount
paymentTransactionSchema.virtual("formattedAmount").get(function () {
  return `${this.currency} ${this.amount.toFixed(2)}`;
});

// Method to mark transaction as completed
paymentTransactionSchema.methods.markCompleted = function () {
  this.status = "completed";
  this.completedAt = new Date();
  this.processedAt = this.processedAt || new Date();
};

// Method to mark transaction as failed
paymentTransactionSchema.methods.markFailed = function (reason, code) {
  this.status = "failed";
  this.failureReason = reason;
  this.failureCode = code;
  this.processedAt = new Date();
};

// Method to process refund
paymentTransactionSchema.methods.processRefund = function (amount, reason) {
  this.status = "refunded";
  this.refundedAt = new Date();
  this.refundAmount = amount || this.amount;
  this.refundReason = reason;
};

// Static method to get user transaction history
paymentTransactionSchema.statics.getUserTransactions = async function (
  userId,
  limit = 10
) {
  return await this.find({ userId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate("subscriptionId", "planType status");
};

// Static method to get revenue analytics
paymentTransactionSchema.statics.getRevenueAnalytics = async function (
  startDate,
  endDate
) {
  return await this.aggregate([
    {
      $match: {
        status: "completed",
        completedAt: {
          $gte: startDate,
          $lte: endDate,
        },
      },
    },
    {
      $group: {
        _id: {
          provider: "$paymentProvider",
          currency: "$currency",
        },
        totalAmount: { $sum: "$amount" },
        transactionCount: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      },
    },
  ]);
};

module.exports = mongoose.model("PaymentTransaction", paymentTransactionSchema);
