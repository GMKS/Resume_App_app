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
  const code = String(payload.code ?? '').trim();
  if (!isValidPhoneNumber(rawPhoneNumber)) {
    return jsonResponse(
      {
        success: false,
        message: 'Invalid phone number format. Use E.164 format with country code.',
      },
      400,
    );
  }

  if (!/^\d{4,8}$/.test(code)) {
    return jsonResponse(
      {
        success: false,
        message: 'Invalid OTP. Please try again.',
      },
      400,
    );
  }

  const phoneNumber = normalizePhoneNumber(rawPhoneNumber);

  const response = await fetch(buildTwilioVerifyUrl(config, 'VerificationCheck'), {
    method: 'POST',
    headers: {
      Authorization: buildTwilioAuthHeader(config),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      To: phoneNumber,
      Code: code,
    }),
  });

  const body = await parseTwilioResponse(response);
  if (!response.ok) {
    return jsonResponse(
      {
        success: false,
        message: twilioErrorMessage(
          body.code,
          'Failed to verify OTP. Try again.',
        ),
        error: body,
      },
      response.status,
    );
  }

  const status = String(body.status ?? 'pending');
  const approved = status == 'approved';

  return jsonResponse({
    success: approved,
    message: approved ? 'OTP verified successfully.' : 'Invalid OTP. Please try again.',
    status,
  }, approved ? 200 : 400);
});