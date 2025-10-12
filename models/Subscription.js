const mongoose = require("mongoose");

const subscriptionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },

    // Subscription Details
    planType: {
      type: String,
      enum: ["monthly", "yearly", "lifetime"],
      required: true,
    },

    status: {
      type: String,
      enum: ["active", "inactive", "cancelled", "expired", "trial"],
      default: "inactive",
    },

    // Pricing Information
    amount: {
      type: Number,
      required: true,
    },

    currency: {
      type: String,
      default: "USD",
    },

    // Subscription Periods
    startDate: {
      type: Date,
      required: true,
    },

    endDate: {
      type: Date,
      required: true,
    },

    // Trial Information
    trialStartDate: {
      type: Date,
    },

    trialEndDate: {
      type: Date,
    },

    isTrialUsed: {
      type: Boolean,
      default: false,
    },

    // Payment Gateway Information
    paymentProvider: {
      type: String,
      enum: ["stripe", "razorpay", "paypal", "test"],
      required: true,
    },

    // Provider-specific IDs
    providerSubscriptionId: {
      type: String,
    },

    providerCustomerId: {
      type: String,
    },

    // Auto-renewal
    autoRenew: {
      type: Boolean,
      default: true,
    },

    // Cancellation
    cancelledAt: {
      type: Date,
    },

    cancellationReason: {
      type: String,
    },

    // Billing History
    nextBillingDate: {
      type: Date,
    },

    // Analytics
    purchaseSource: {
      type: String, // 'app', 'web', 'promotion'
      default: "app",
    },

    promoCode: {
      type: String,
    },

    discountApplied: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
subscriptionSchema.index({ userId: 1 });
subscriptionSchema.index({ status: 1 });
subscriptionSchema.index({ endDate: 1 });
subscriptionSchema.index({ paymentProvider: 1 });

// Virtual for checking if subscription is active
subscriptionSchema.virtual("isActive").get(function () {
  return this.status === "active" && this.endDate > new Date();
});

// Method to check if trial is available
subscriptionSchema.methods.canStartTrial = function () {
  return !this.isTrialUsed && this.status === "inactive";
};

// Method to calculate subscription end date
subscriptionSchema.methods.calculateEndDate = function (
  startDate = new Date()
) {
  const start = new Date(startDate);

  switch (this.planType) {
    case "monthly":
      return new Date(start.setMonth(start.getMonth() + 1));
    case "yearly":
      return new Date(start.setFullYear(start.getFullYear() + 1));
    case "lifetime":
      return new Date("2099-12-31"); // Far future date for lifetime
    default:
      return new Date(start.setMonth(start.getMonth() + 1));
  }
};

// Method to start trial
subscriptionSchema.methods.startTrial = function () {
  const trialDays = 7;
  this.status = "trial";
  this.trialStartDate = new Date();
  this.trialEndDate = new Date(Date.now() + trialDays * 24 * 60 * 60 * 1000);
  this.isTrialUsed = true;
  this.startDate = this.trialStartDate;
  this.endDate = this.trialEndDate;
};

// Static method to get active subscription for user
subscriptionSchema.statics.getActiveSubscription = async function (userId) {
  return await this.findOne({
    userId,
    status: { $in: ["active", "trial"] },
    endDate: { $gt: new Date() },
  });
};

module.exports = mongoose.model("Subscription", subscriptionSchema);
