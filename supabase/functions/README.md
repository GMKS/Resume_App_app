# OTP Edge Functions

This folder contains Supabase Edge Functions for the release OTP flow.

## Functions

- `send-otp`
  - `POST`
  - body: `{ "phoneNumber": "+15551234567" }`
- `verify-otp`
  - `POST`
  - body: `{ "phoneNumber": "+15551234567", "code": "123456" }`

The Flutter app already matches this contract.

## Required Secrets

Create `supabase/functions/.env.local` with:

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`supabase/.gitignore` already excludes `.env.local`.

## Local Development

Start Supabase locally and serve the functions:

```powershell
supabase start
supabase functions serve send-otp --env-file supabase/functions/.env.local
supabase functions serve verify-otp --env-file supabase/functions/.env.local
```

Use these app URLs for local testing:

```env
OTP_SEND_URL=http://127.0.0.1:54321/functions/v1/send-otp
OTP_VERIFY_URL=http://127.0.0.1:54321/functions/v1/verify-otp
```

## Deploy

```powershell
supabase functions deploy send-otp
supabase functions deploy verify-otp
supabase secrets set TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_VERIFY_SERVICE_SID=...
```

Production app URLs will be:

```text
https://<your-project-ref>.supabase.co/functions/v1/send-otp
https://<your-project-ref>.supabase.co/functions/v1/verify-otp
```