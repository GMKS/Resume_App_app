export type RazorpayConfig = {
  keyId: string;
  keySecret: string;
};

export function loadRazorpayConfig(): RazorpayConfig {
  return {
    keyId: Deno.env.get('RAZORPAY_KEY_ID')?.trim() ?? '',
    keySecret: Deno.env.get('RAZORPAY_KEY_SECRET')?.trim() ?? '',
  };
}

export function hasRazorpayConfig(config: RazorpayConfig): boolean {
  return config.keyId.length > 0 && config.keySecret.length > 0;
}

export function buildRazorpayAuthHeader(config: RazorpayConfig): string {
  return `Basic ${btoa(`${config.keyId}:${config.keySecret}`)}`;
}

export function buildRazorpayApiUrl(path: string): string {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `https://api.razorpay.com${normalizedPath}`;
}

export async function createRazorpaySignature(
  orderId: string,
  paymentId: string,
  keySecret: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(keySecret),
    {
      name: 'HMAC',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${orderId}|${paymentId}`),
  );
  return bytesToHex(new Uint8Array(signature));
}

export function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }

  let mismatch = 0;
  for (let index = 0; index < a.length; index += 1) {
    mismatch |= a.charCodeAt(index) ^ b.charCodeAt(index);
  }
  return mismatch === 0;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((value) => value.toString(16).padStart(2, '0'))
    .join('');
}