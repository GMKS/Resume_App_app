const verifyBaseUrl = 'https://verify.twilio.com/v2';

export interface TwilioConfig {
  accountSid: string;
  authToken: string;
  verifyServiceSid: string;
}

export function loadTwilioConfig(): TwilioConfig {
  return {
    accountSid: Deno.env.get('TWILIO_ACCOUNT_SID')?.trim() ?? '',
    authToken: Deno.env.get('TWILIO_AUTH_TOKEN')?.trim() ?? '',
    verifyServiceSid: Deno.env.get('TWILIO_VERIFY_SERVICE_SID')?.trim() ?? '',
  };
}

export function hasTwilioConfig(config: TwilioConfig): boolean {
  return config.accountSid.length > 0 &&
      config.authToken.length > 0 &&
      config.verifyServiceSid.length > 0;
}

export function buildTwilioVerifyUrl(
  config: TwilioConfig,
  path: 'Verifications' | 'VerificationCheck',
): string {
  return `${verifyBaseUrl}/Services/${config.verifyServiceSid}/${path}`;
}

export function buildTwilioAuthHeader(config: TwilioConfig): string {
  return `Basic ${btoa(`${config.accountSid}:${config.authToken}`)}`;
}

export function normalizePhoneNumber(phoneNumber: string): string {
  const cleaned = phoneNumber.replace(/[^\d+]/g, '').trim();
  if (cleaned.startsWith('+')) {
    return cleaned;
  }
  return `+${cleaned}`;
}

export function isValidPhoneNumber(phoneNumber: string): boolean {
  const normalized = normalizePhoneNumber(phoneNumber);
  return /^\+[1-9]\d{7,14}$/.test(normalized);
}

export async function parseTwilioResponse(response: Response): Promise<Record<string, unknown>> {
  const responseText = await response.text();
  if (!responseText.trim()) {
    return {};
  }

  try {
    const parsed = JSON.parse(responseText);
    if (typeof parsed === 'object' && parsed !== null) {
      return parsed as Record<string, unknown>;
    }
  } catch (_) {
    // Fall back to wrapping the raw response.
  }

  return { message: responseText };
}

export function twilioErrorMessage(code: unknown, fallback: string): string {
  switch (code) {
    case 60033:
      return 'This number is not verified on the current Twilio trial account.';
    case 60200:
      return 'Invalid phone number format. Use E.164 format with country code.';
    case 60203:
      return 'Too many OTP attempts for this number. Please wait and try again.';
    case 60212:
      return 'Too many OTP requests. Please wait a moment before requesting again.';
    case 20003:
      return 'Twilio authentication failed. Check backend secrets.';
    case 20404:
      return 'Twilio Verify Service was not found. Check backend secrets.';
    default:
      return fallback;
  }
}