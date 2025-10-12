const Subscription = require("../models/Subscription");
const PaymentTransaction = require("../models/PaymentTransaction");
const User = require("../models/User");
const PaymentService = require("./PaymentService");

class SubscriptionService {
  constructor() {
    // Trial configuration
    this.trialDays = 7;

    // Plan configurations
    this.planFeatures = {
      free: {
        maxResumes: 3,
        templates: ["Classic", "Minimal"],
        exportFormats: ["PDF"],
        hasWatermark: true,
        cloudStorage: false,
        aiFeatures: false,
        prioritySupport: false,
      },
      premium: {
        maxResumes: -1, // Unlimited
        templates: [
          "Classic",
          "Modern",
          "Minimal",
          "Professional",
          "Creative",
          "OnePage",
        ],
        exportFormats: ["PDF", "DOCX", "TXT"],
        hasWatermark: false,
        cloudStorage: true,
        aiFeatures: true,
        prioritySupport: true,
        videoResume: true,
        customBranding: true,
      },
    };
  }

  // Get user's current subscription
  async getUserSubscription(userId) {
    try {
      const subscription = await Subscription.getActiveSubscription(userId);

      if (!subscription) {
        return {
          status: "free",
          plan: "free",
          features: this.planFeatures.free,
          isActive: false,
          daysRemaining: 0,
        };
      }

      const daysRemaining = Math.ceil(
        (subscription.endDate - new Date()) / (1000 * 60 * 60 * 24)
      );

      return {
        status: subscription.status,
        plan: subscription.planType,
        features: this.planFeatures.premium,
        isActive: subscription.isActive,
        daysRemaining: Math.max(0, daysRemaining),
        endDate: subscription.endDate,
        autoRenew: subscription.autoRenew,
        subscription: subscription,
      };
    } catch (error) {
      console.error("Get user subscription error:", error);
      throw new Error("Failed to get subscription status");
    }
  }

  // Check if user can start trial
  async canStartTrial(userId) {
    try {
      const existingSubscription = await Subscription.findOne({ userId });

      if (!existingSubscription) {
        return { canStart: true, reason: "new_user" };
      }

      if (existingSubscription.isTrialUsed) {
        return { canStart: false, reason: "trial_already_used" };
      }

      if (existingSubscription.status === "active") {
        return { canStart: false, reason: "already_premium" };
      }

      return { canStart: true, reason: "eligible" };
    } catch (error) {
      console.error("Check trial eligibility error:", error);
      throw new Error("Failed to check trial eligibility");
    }
  }

  // Start free trial
  async startTrial(userId) {
    try {
      const trialCheck = await this.canStartTrial(userId);

      if (!trialCheck.canStart) {
        throw new Error(`Cannot start trial: ${trialCheck.reason}`);
      }

      let subscription = await Subscription.findOne({ userId });

      if (!subscription) {
        subscription = new Subscription({
          userId,
          planType: "monthly", // Default plan for trial
          amount: 0,
          paymentProvider: "trial",
        });
      }

      subscription.startTrial();
      await subscription.save();

      return {
        success: true,
        trialEndDate: subscription.trialEndDate,
        daysRemaining: this.trialDays,
      };
    } catch (error) {
      console.error("Start trial error:", error);
      throw error;
    }
  }

  // Create payment intent for subscription
  async createPaymentIntent(
    userId,
    planType,
    currency = "USD",
    paymentProvider = null,
    paymentMethod = "auto"
  ) {
    try {
      const user = await User.findById(userId);
      if (!user) {
        throw new Error("User not found");
      }

      const pricing = PaymentService.getPricing(currency);
      const amount = pricing[planType];

      if (!amount) {
        throw new Error("Invalid plan type");
      }

      // Determine best payment provider
      const provider =
        paymentProvider ||
        PaymentService.getBestProvider(currency, "IN", paymentMethod);

      let paymentData;

      switch (provider) {
        case "stripe":
          // Create or get Stripe customer
          let customerId = user.stripeCustomerId;
          if (!customerId) {
            const customer = await PaymentService.createCustomer(
              user.email,
              user.name,
              "stripe"
            );
            customerId = customer.customerId;
            user.stripeCustomerId = customerId;
            await user.save();
          }

          paymentData = await PaymentService.createStripePaymentIntent(
            amount,
            currency,
            customerId,
            planType
          );
          break;

        case "razorpay":
          paymentData = await PaymentService.createRazorpayOrder(
            amount,
            currency,
            userId,
            planType,
            paymentMethod
          );
          break;

        case "paypal":
          paymentData = await PaymentService.createPayPalOrder(
            amount,
            currency,
            planType
          );
          break;

        case "test":
          // Test mode - simulate payment
          paymentData = {
            testMode: true,
            amount,
            currency,
            planType,
          };
          break;

        default:
          throw new Error(`Payment provider ${provider} not supported`);
      }

      return {
        success: true,
        provider,
        amount,
        currency,
        planType,
        paymentData,
      };
    } catch (error) {
      console.error("Create payment intent error:", error);
      throw error;
    }
  }

  // Process successful payment and activate subscription
  async activateSubscription(userId, paymentData, transactionData) {
    try {
      const { planType, amount, currency, provider, providerTransactionId } =
        paymentData;

      // Create or update subscription
      let subscription = await Subscription.findOne({ userId });

      if (!subscription) {
        subscription = new Subscription({
          userId,
          planType,
          amount,
          currency,
          paymentProvider: provider,
          providerSubscriptionId: providerTransactionId,
        });
      } else {
        // Upgrade existing subscription
        subscription.planType = planType;
        subscription.amount = amount;
        subscription.currency = currency;
        subscription.paymentProvider = provider;
        subscription.providerSubscriptionId = providerTransactionId;
      }

      // Set subscription dates
      subscription.status = "active";
      subscription.startDate = new Date();
      subscription.endDate = subscription.calculateEndDate();
      subscription.autoRenew = true;

      if (planType !== "lifetime") {
        subscription.nextBillingDate = subscription.endDate;
      }

      await subscription.save();

      // Create payment transaction record
      const transaction = new PaymentTransaction({
        userId,
        subscriptionId: subscription._id,
        transactionId: `txn_${Date.now()}_${userId}`,
        amount,
        currency,
        paymentProvider: provider,
        providerTransactionId,
        status: "completed",
        type: subscription.isTrialUsed ? "subscription" : "upgrade",
        ...transactionData,
      });

      transaction.markCompleted();
      await transaction.save();

      return {
        success: true,
        subscription,
        transaction,
        features: this.planFeatures.premium,
      };
    } catch (error) {
      console.error("Activate subscription error:", error);
      throw error;
    }
  }

  // Cancel subscription
  async cancelSubscription(userId, reason = "user_request") {
    try {
      const subscription = await Subscription.getActiveSubscription(userId);

      if (!subscription) {
        throw new Error("No active subscription found");
      }

      subscription.status = "cancelled";
      subscription.cancelledAt = new Date();
      subscription.cancellationReason = reason;
      subscription.autoRenew = false;

      await subscription.save();

      return {
        success: true,
        message: "Subscription cancelled successfully",
        endDate: subscription.endDate,
      };
    } catch (error) {
      console.error("Cancel subscription error:", error);
      throw error;
    }
  }

  // Renew subscription (for testing or manual renewal)
  async renewSubscription(userId) {
    try {
      const subscription = await Subscription.findOne({ userId });

      if (!subscription) {
        throw new Error("No subscription found");
      }

      if (
        subscription.status === "active" &&
        subscription.endDate > new Date()
      ) {
        throw new Error("Subscription is already active");
      }

      subscription.status = "active";
      subscription.startDate = new Date();
      subscription.endDate = subscription.calculateEndDate();

      if (subscription.planType !== "lifetime") {
        subscription.nextBillingDate = subscription.endDate;
      }

      await subscription.save();

      return {
        success: true,
        subscription,
        endDate: subscription.endDate,
      };
    } catch (error) {
      console.error("Renew subscription error:", error);
      throw error;
    }
  }

  // Get subscription analytics
  async getSubscriptionAnalytics(startDate, endDate) {
    try {
      const analytics = await Subscription.aggregate([
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
              planType: "$planType",
              status: "$status",
              paymentProvider: "$paymentProvider",
            },
            count: { $sum: 1 },
            totalRevenue: { $sum: "$amount" },
            avgAmount: { $avg: "$amount" },
          },
        },
      ]);

      return analytics;
    } catch (error) {
      console.error("Get subscription analytics error:", error);
      throw error;
    }
  }

  // Check and expire overdue subscriptions (cron job)
  async checkExpiredSubscriptions() {
    try {
      const expiredSubscriptions = await Subscription.find({
        status: { $in: ["active", "trial"] },
        endDate: { $lt: new Date() },
        autoRenew: false,
      });

      for (const subscription of expiredSubscriptions) {
        subscription.status = "expired";
        await subscription.save();

        console.log(
          `Subscription ${subscription._id} expired for user ${subscription.userId}`
        );
      }

      return {
        expiredCount: expiredSubscriptions.length,
        expiredSubscriptions,
      };
    } catch (error) {
      console.error("Check expired subscriptions error:", error);
      throw error;
    }
  }

  // Process refund
  async processRefund(userId, transactionId, reason) {
    try {
      const transaction = await PaymentTransaction.findOne({
        userId,
        transactionId,
        status: "completed",
      });

      if (!transaction) {
        throw new Error("Transaction not found or not eligible for refund");
      }

      // Process refund with payment provider
      const refundResult = await PaymentService.processRefund(
        transaction.providerTransactionId,
        transaction.amount,
        transaction.paymentProvider
      );

      if (refundResult.success) {
        // Update transaction
        transaction.processRefund(transaction.amount, reason);
        await transaction.save();

        // Cancel subscription
        await this.cancelSubscription(userId, "refund");

        return {
          success: true,
          refundId: refundResult.refundId,
          amount: transaction.amount,
        };
      } else {
        throw new Error(refundResult.error || "Refund failed");
      }
    } catch (error) {
      console.error("Process refund error:", error);
      throw error;
    }
  }
}

module.exports = new SubscriptionService();
