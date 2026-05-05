import { handleCorsPreflight, jsonResponse } from '../_shared/http.ts';
import {
  buildTwilioAuthHeader,
  buildTwilioVerifyUrl,
  hasTwilioConfig,
  isValidPhoneNumber,
  loadTwilioConfig,
  normalizePhoneNumber,
  parseTwilioResponse,
  twilioErrorMessage,
} from '../_shared/twilio.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCorsPreflight(req);
  if (corsResponse) {
    return corsResponse;
  }

  if (req.method !== 'POST') {
    return jsonResponse({ success: false, message: 'Method not allowed.' }, 405);
  }

  const config = loadTwilioConfig();
  if (!hasTwilioConfig(config)) {
    return jsonResponse(
      {
        success: false,
        message: 'OTP backend is missing Twilio configuration.',
      },
      500,
    );
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ success: false, message: 'Invalid JSON body.' }, 400);
  }

  const rawPhoneNumber = String(payload.phoneNumber ?? '').trim();
  if (!isValidPhoneNumber(rawPhoneNumber)) {
    return jsonResponse(
      {
        success: false,
        message: 'Invalid phone number format. Use E.164 format with country code.',
      },
      400,
    );
  }

  const phoneNumber = normalizePhoneNumber(rawPhoneNumber);

  const response = await fetch(buildTwilioVerifyUrl(config, 'Verifications'), {
    method: 'POST',
    headers: {
      Authorization: buildTwilioAuthHeader(config),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      To: phoneNumber,
      Channel: 'sms',
    }),
  });

  const body = await parseTwilioResponse(response);
  if (!response.ok) {
    return jsonResponse(
      {
        success: false,
        message: twilioErrorMessage(
          body.code,
          'Failed to send OTP. Try again.',
        ),
        error: body,
      },
      response.status,
    );
  }

  return jsonResponse({
    success: true,
    message: 'OTP sent successfully.',
    status: body.status ?? 'pending',
    sid: body.sid ?? null,
  });
});