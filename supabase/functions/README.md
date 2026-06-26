# OTP Edge Functions

This folder contains Supabase Edge Functions for the release OTP flow.

## Functions

- `send-otp`
  - `POST`
  - body: `{ "phoneNumber": "+15551234567" }`
- `verify-otp`
  - `POST`
  - body: `{ "phoneNumber": "+15551234567", "code": "123456" }`
- `create-razorpay-order`
  - `POST`
  - body: `{ "plan": "weekly", "amount": 14900, "currency": "INR", "receipt": "resume_weekly_..." }`
- `check-razorpay-order-status`
  - `POST`
  - body: `{ "plan": "weekly", "orderId": "order_..." }`
- `verify-razorpay-payment`
  - `POST`
  - body: `{ "plan": "weekly", "paymentId": "pay_...", "orderId": "order_...", "signature": "..." }`
- `ai-gateway`
  - `POST`
  - body: `{ "prompt": "...", "temperature": 0.6, "preferJsonObjectMode": true, "requestType": "roast_resume" }`
- `ai-health`
  - `GET`
  - optional query: `?probe=provider`

The Flutter app already matches this contract.

## Required Secrets

Create `supabase/functions/.env.local` with:

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_server_side_secret
GROQ_API_KEY=gsk_live_xxxxxxxxxxxxx
GROQ_MODEL=llama-3.3-70b-versatile
AI_ENV=development
AI_UPSTREAM_TIMEOUT_MS=45000
AI_MAX_RETRIES=2
```

`supabase/.gitignore` already excludes `.env.local`.

## Local Development

Start Supabase locally and serve the functions:

```powershell
supabase start
supabase functions serve send-otp --env-file supabase/functions/.env.local
supabase functions serve verify-otp --env-file supabase/functions/.env.local
supabase functions serve create-razorpay-order --env-file supabase/functions/.env.local
supabase functions serve check-razorpay-order-status --env-file supabase/functions/.env.local
supabase functions serve verify-razorpay-payment --env-file supabase/functions/.env.local
supabase functions serve ai-gateway --env-file supabase/functions/.env.local
supabase functions serve ai-health --env-file supabase/functions/.env.local
```

Use these app URLs for local testing:

```env
OTP_SEND_URL=http://127.0.0.1:54321/functions/v1/send-otp
OTP_VERIFY_URL=http://127.0.0.1:54321/functions/v1/verify-otp
AI_BASE_URL=http://127.0.0.1:54321/functions/v1
AI_ENV=development
```

The Flutter app derives the Razorpay function URLs from the same Supabase
functions base URL.

## Deploy

```powershell
supabase functions deploy send-otp
supabase functions deploy verify-otp
supabase functions deploy create-razorpay-order
supabase functions deploy check-razorpay-order-status
supabase functions deploy verify-razorpay-payment
supabase functions deploy ai-gateway
supabase functions deploy ai-health
supabase secrets set TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_VERIFY_SERVICE_SID=... RAZORPAY_KEY_ID=... RAZORPAY_KEY_SECRET=... GROQ_API_KEY=... GROQ_MODEL=llama-3.3-70b-versatile AI_ENV=production AI_UPSTREAM_TIMEOUT_MS=45000 AI_MAX_RETRIES=2
```

Production app URLs will be:

```text
https://<your-project-ref>.supabase.co/functions/v1/send-otp
https://<your-project-ref>.supabase.co/functions/v1/verify-otp
https://<your-project-ref>.supabase.co/functions/v1/create-razorpay-order
https://<your-project-ref>.supabase.co/functions/v1/check-razorpay-order-status
https://<your-project-ref>.supabase.co/functions/v1/verify-razorpay-payment
https://<your-project-ref>.supabase.co/functions/v1/ai-gateway
https://<your-project-ref>.supabase.co/functions/v1/ai-health
```

The Flutter app should only receive `AI_BASE_URL` and never the Groq API key.