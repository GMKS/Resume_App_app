# Google Play Data Safety Mapping

Date: 2026-05-02
Project: Resumix AI
Scope: Android app code paths present in this repository

## Summary

This document maps observed app data flows to the Google Play Data Safety form. It is intended to support manual Play Console entry. It is not a substitute for reviewing the live backend configuration and production privacy policy before submission.

## Data Collected

### Personal info

- Name
  - Source: resume personal info entered by the user
  - Use: resume editing, preview, export, optional cloud sync
  - Processing: on-device; may sync to backend if cloud sync is enabled
- Email address
  - Source: resume personal info and optional auth providers
  - Use: account auth, resume content, optional sync/account recovery
  - Processing: on-device; may sync to backend/Firebase auth flows
- Phone number
  - Source: resume personal info and OTP auth flow
  - Use: resume content and phone OTP verification
  - Processing: on-device; sent to configured OTP endpoints when phone auth is used
- Postal address
  - Source: resume personal info
  - Use: resume content, preview, export, optional sync
  - Processing: on-device; may sync if cloud sync is enabled

### User-generated content

- Resume content
  - Includes: summary, experience, education, skills, projects, certifications, languages, custom sections
  - Use: editing, preview, PDF export, AI rewrite/tailoring, optional cloud sync
  - Processing: on-device; may be sent to AI providers for user-invoked AI features; may sync to backend/Firebase if enabled
- Profile photo
  - Use: resume preview/export
  - Processing: on-device; may sync with resume data if cloud sync is enabled
- Portfolio and project links
  - Use: resume content and export
  - Processing: on-device; may sync with resume data if cloud sync is enabled

### App activity / diagnostics

- Purchase and subscription state
  - Source: Google Play Billing / local entitlement state
  - Use: unlock premium features, restore purchases
  - Processing: Google Play and local app state
- Authentication state
  - Source: Firebase Auth / provider sign-in state
  - Use: sign-in and account association
  - Processing: Firebase/Auth providers

### Sensitive or user-controlled configuration

- AI API key entered by the user
  - Source: settings and AI tool screens
  - Use: user-triggered AI features only
  - Storage: encrypted local storage via flutter_secure_storage
  - Note: should be disclosed in privacy policy if transmitted to third-party AI APIs during use

## Data Shared / Transferred Off Device

### Firebase

- Auth identifiers and account state through Firebase Auth
- Potential resume/account sync through configured backend services where user enables sync

### AI provider requests

- User resume/job content may be transmitted when AI features are explicitly used
- Includes rewrite, tailoring, bullet generation, enhancement, and related AI tools

### OTP / phone verification endpoints

- Phone number and OTP verification payloads are sent to configured OTP endpoints when phone auth is used

### Social auth providers

- Google sign-in can transmit auth data to Google/Firebase
- Facebook sign-in is disabled by default in production unless explicitly enabled via build configuration

### Payments

- Google Play Billing purchase metadata is exchanged with Google Play
- Razorpay payment metadata may be exchanged if Razorpay flows are enabled/configured

## Data Safety Form Guidance

### Likely "collected"

- Personal info: name, email address, phone number, address
- User content: photos, files/docs, and other user-generated content in resumes
- App info and performance: limited diagnostic/auth/purchase state as applicable

### Likely "shared"

- Personal info and user content may be shared with:
  - Firebase/Auth providers
  - AI providers when the user invokes AI features
  - OTP provider endpoints when phone verification is used
  - Google Play / payment processors for purchases

### Processing purpose candidates

- App functionality
- Account management
- Fraud prevention, security, and compliance for auth/payments
- Developer communications/support only if implemented outside this repo

### User controls observed

- Delete-data flow exists in settings
- Cloud sync is optional
- AI features are user-invoked, not automatic
- Facebook auth is disabled by default unless explicitly enabled at build time

## Submission Notes

- Verify the production privacy policy matches these flows before Play submission.
- Confirm whether resume sync is enabled in production and whether Supabase/Firebase both operate in release.
- Confirm which third-party AI endpoint is used in production and disclose that provider by name if required by policy.
- Confirm whether Razorpay is active in the Play-distributed Android build.
- Manual Play Console entry is still required; this file is a reviewer aid, not the submission itself.