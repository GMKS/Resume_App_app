# 📊 Analytics Dashboard Setup Guide

## 🔥 Firebase Analytics Dashboard

### 1. Setting Up Custom Events

Your app already tracks these key events. Here's how to monitor them:

#### Revenue Events

- `purchase_initiated` - User starts premium purchase
- `purchase_completed` - Successful premium purchase
- `subscription_renewed` - Auto-renewal success
- `subscription_cancelled` - User cancels subscription

#### Engagement Events

- `premium_feature_attempted` - Free user tries premium feature
- `resume_exported` - User exports resume (track format)
- `template_selected` - Template usage analytics
- `onboarding_completed` - New user completes setup

#### Retention Events

- `notification_opened` - Push notification effectiveness
- `app_reopened` - User returns after inactivity
- `daily_active_user` - Daily engagement tracking

### 2. Firebase Analytics Custom Dimensions

Set up these custom dimensions in Firebase Console:

```dart
// User Properties (set once per user)
await FirebaseAnalytics.instance.setUserProperty(
  name: 'user_type',
  value: 'premium', // or 'free'
);

await FirebaseAnalytics.instance.setUserProperty(
  name: 'subscription_type',
  value: 'monthly', // 'yearly', 'lifetime', or null
);

await FirebaseAnalytics.instance.setUserProperty(
  name: 'registration_date',
  value: '2025-09-25',
);

await FirebaseAnalytics.instance.setUserProperty(
  name: 'acquisition_source',
  value: 'organic', // 'facebook_ads', 'google_ads', etc.
);
```

### 3. Key Conversion Funnels

#### Premium Conversion Funnel

1. **App Install** → `first_open`
2. **Registration** → `sign_up`
3. **Feature Discovery** → `premium_feature_attempted`
4. **Purchase Intent** → `purchase_initiated`
5. **Purchase Complete** → `purchase_completed`

#### Onboarding Funnel

1. **First Launch** → `first_open`
2. **Onboarding Start** → `onboarding_started`
3. **Step 1 Complete** → `onboarding_step_1`
4. **Step 2 Complete** → `onboarding_step_2`
5. **Onboarding Finish** → `onboarding_completed`

## 📈 Google Analytics 4 Integration

### 1. Enhanced E-commerce Setup

Link Firebase Analytics to GA4 for advanced reporting:

```dart
// Track purchases with detailed product info
await FirebaseAnalytics.instance.logPurchase(
  currency: 'USD',
  value: 4.99,
  parameters: {
    'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    'item_name': 'Monthly Premium',
    'item_id': 'premium_monthly',
    'item_category': 'subscription',
    'item_variant': 'standard',
    'quantity': 1,
    'price': 4.99,
    'payment_type': 'google_play',
  },
);
```

### 2. Custom Audiences

Create audiences in GA4 for:

- **High-Value Users**: Made purchase within 30 days
- **At-Risk Users**: Haven't opened app in 7 days
- **Feature Enthusiasts**: Used 3+ premium features
- **Template Collectors**: Downloaded 5+ templates

## 📊 Revenue Analytics Dashboard

### 1. Key Metrics to Track

#### Monthly Recurring Revenue (MRR)

```dart
// Track subscription revenue
Map<String, dynamic> revenueData = {
  'monthly_subscribers': monthlyCount,
  'yearly_subscribers': yearlyCount,
  'lifetime_purchases': lifetimeCount,
  'total_mrr': calculateMRR(),
  'churn_rate': calculateChurnRate(),
};

await FirebaseAnalytics.instance.logEvent(
  name: 'monthly_revenue_report',
  parameters: revenueData,
);
```

#### Average Revenue Per User (ARPU)

- Total Revenue ÷ Total Active Users
- Track monthly to see trends
- Segment by user acquisition source

#### Customer Lifetime Value (LTV)

- Average subscription duration × Average monthly revenue
- Track by subscription type
- Use for marketing budget allocation

### 2. Cohort Analysis Setup

Track user behavior by registration date:

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'cohort_analysis',
  parameters: {
    'cohort_month': '2025-09',
    'days_since_install': daysSinceInstall,
    'is_active': isUserActive,
    'has_made_purchase': hasPurchased,
    'total_sessions': totalSessions,
  },
);
```

## 🎯 A/B Testing Analytics

### 1. Firebase Remote Config Experiments

Track experiment performance:

```dart
// Track A/B test participation
await FirebaseAnalytics.instance.logEvent(
  name: 'ab_test_assignment',
  parameters: {
    'experiment_name': 'pricing_test_v1',
    'variant': 'variant_b', // or 'control'
    'user_id': currentUserId,
  },
);

// Track conversion for each variant
await FirebaseAnalytics.instance.logEvent(
  name: 'ab_test_conversion',
  parameters: {
    'experiment_name': 'pricing_test_v1',
    'variant': currentVariant,
    'converted': true,
    'conversion_value': 4.99,
  },
);
```

### 2. Experiments to Run

1. **Pricing Tests**:

   - Monthly: $3.99 vs $4.99 vs $5.99
   - Yearly discount: 50% vs 58% vs 65%

2. **Onboarding Tests**:

   - Feature-focused vs Value-focused
   - 3 steps vs 5 steps vs skip option

3. **Paywall Tests**:
   - Soft paywall vs Hard paywall
   - Feature limit: 3 vs 5 vs unlimited trial

## 📱 AdMob Revenue Analytics

### 1. Ad Performance Tracking

```dart
// Track ad impressions and revenue
await FirebaseAnalytics.instance.logEvent(
  name: 'ad_impression',
  parameters: {
    'ad_platform': 'admob',
    'ad_unit_name': 'banner_main_screen',
    'ad_format': 'banner',
    'estimated_earnings': 0.02, // eCPM estimation
  },
);

// Track ad clicks
await FirebaseAnalytics.instance.logEvent(
  name: 'ad_click',
  parameters: {
    'ad_platform': 'admob',
    'ad_unit_name': 'banner_main_screen',
    'user_type': 'free',
  },
);
```

### 2. Ad Revenue Optimization

- Monitor eCPM by placement
- Track ad-to-premium conversion
- A/B test ad frequency

## 🔔 Retention Analytics

### 1. Notification Campaign Tracking

```dart
// Track notification effectiveness
await FirebaseAnalytics.instance.logEvent(
  name: 'notification_campaign_result',
  parameters: {
    'campaign_type': 'retention_day_7',
    'notification_opened': true,
    'app_opened_within_hour': true,
    'action_completed': false, // user completed intended action
    'user_segment': 'inactive_users',
  },
);
```

### 2. Churn Prediction

Track leading indicators:

- Days since last app open
- Feature usage decline
- Session duration decrease
- Export frequency drop

## 📋 Custom Dashboard Setup

### 1. Firebase Analytics Custom Reports

Create custom reports for:

- Weekly cohort retention
- Premium conversion by acquisition source
- Feature usage heat map
- Revenue attribution by campaign

### 2. Third-Party Analytics Tools

#### Mixpanel Integration (Optional)

```dart
// For advanced funnel analysis
await Mixpanel.track('Premium Feature Attempted', {
  'feature_name': 'pdf_export',
  'user_tier': 'free',
  'attempt_number': 3,
  'session_duration': sessionDuration,
});
```

#### Amplitude Integration (Optional)

```dart
// For user journey analysis
await Amplitude.track('Resume Creation Flow', {
  'step': 'template_selection',
  'template_category': 'professional',
  'time_spent': 45, // seconds
  'completion_rate': 0.8,
});
```

## 📊 Automated Reporting

### 1. Daily Reports

Set up automated reports for:

- Daily Active Users (DAU)
- Daily Revenue
- Conversion Rate
- Top performing features

### 2. Weekly Business Review

- Weekly Active Users (WAU)
- Cohort retention analysis
- A/B test results
- Customer support metrics

### 3. Monthly Deep Dive

- Monthly Active Users (MAU)
- Lifetime Value analysis
- Churn analysis and prediction
- Feature adoption rates
- Competitive analysis

## 🎯 Key Performance Indicators (KPIs)

### User Acquisition

- **Install-to-Registration Rate**: Target >70%
- **Cost Per Install (CPI)**: Track by channel
- **Organic vs Paid Split**: Target 60/40

### Engagement

- **Daily Active Users**: Growth target +10% monthly
- **Session Duration**: Target >3 minutes
- **Screens per Session**: Target >5

### Monetization

- **Free-to-Premium Conversion**: Target 3-5%
- **Monthly Churn Rate**: Target <5%
- **Average Revenue Per User**: Target $2/month

### Retention

- **Day 1 Retention**: Target >40%
- **Day 7 Retention**: Target >20%
- **Day 30 Retention**: Target >10%

---

## 🚀 Dashboard URLs (Update with your actual links)

- **Firebase Analytics**: https://console.firebase.google.com/project/YOUR_PROJECT/analytics
- **Google Analytics 4**: https://analytics.google.com/analytics/web/#/YOUR_GA4_PROPERTY
- **AdMob**: https://apps.admob.com/v2/apps/YOUR_APP_ID/reporting
- **Play Console**: https://play.google.com/console/developers/YOUR_DEVELOPER_ID/app/YOUR_APP_ID/statistics

**Pro Tip**: Set up automated alerts for critical metrics like sudden drops in DAU or conversion rates!
