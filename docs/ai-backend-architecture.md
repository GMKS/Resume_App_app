# AI Backend Architecture

## Overview

All AI-powered Flutter features call a single backend gateway hosted as Supabase Edge Functions.

- Flutter client calls `AI_BASE_URL/ai-gateway`
- Flutter startup validation calls `AI_BASE_URL/ai-health?probe=provider`
- Supabase Edge Functions read `GROQ_API_KEY` from server-side secrets
- Groq key rotation happens only on the server, with no APK/AAB rebuild required

## Environments

Use separate values for each environment:

### Development

```env
AI_BASE_URL=http://10.0.2.2:54321/functions/v1
AI_ENV=development
```

For a physical device, replace `10.0.2.2` with a reachable LAN host or deployed staging URL.

### Staging

```env
AI_BASE_URL=https://<staging-project-ref>.supabase.co/functions/v1
AI_ENV=staging
```

### Production

```env
AI_BASE_URL=https://<prod-project-ref>.supabase.co/functions/v1
AI_ENV=production
```

## Server Secrets

Store only on Supabase:

```env
GROQ_API_KEY=gsk_live_xxxxxxxxxxxxx
GROQ_MODEL=llama-3.3-70b-versatile
AI_ENV=production
AI_UPSTREAM_TIMEOUT_MS=45000
AI_MAX_RETRIES=2
```

## Functions

- `ai-gateway`
  - Receives prompt payloads from the app
  - Applies retries and timeout handling
  - Calls Groq with server-side credentials
  - Returns the provider response to the centralized Flutter AI service
- `ai-health`
  - Validates server configuration
  - Optionally probes Groq reachability
  - Supports startup health checks and monitoring

## Deployment

```powershell
supabase functions deploy ai-gateway
supabase functions deploy ai-health
supabase secrets set GROQ_API_KEY=... GROQ_MODEL=llama-3.3-70b-versatile AI_ENV=production AI_UPSTREAM_TIMEOUT_MS=45000 AI_MAX_RETRIES=2
```

## Monitoring

- Edge Functions emit structured logs with correlation IDs, request type, attempt count, status codes, and provider errors.
- Flutter logs backend availability checks and request failures through the centralized AI service.
- Use Supabase function logs and your app log pipeline to monitor AI failures, rate limits, and upstream outages.

## Client Contract

The app never stores or receives the Groq API key. It only needs:

```env
AI_BASE_URL=https://<environment>.supabase.co/functions/v1
AI_ENV=production
```