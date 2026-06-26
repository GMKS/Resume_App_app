import { handleCorsPreflight, jsonResponse } from '../_shared/http.ts';
import {
  buildRazorpayApiUrl,
  buildRazorpayAuthHeader,
  hasRazorpayConfig,
  loadRazorpayConfig,
} from '../_shared/razorpay.ts';

type CreateOrderPayload = {
  plan?: string;
  amount?: number;
  currency?: string;
  receipt?: string;
  displayPrice?: string;
  periodLabel?: string;
};

Deno.serve(async (req: Request) => {
  const corsResponse = handleCorsPreflight(req);
  if (corsResponse) {
    return corsResponse;
  }

  if (req.method !== 'POST') {
    return jsonResponse({ success: false, message: 'Method not allowed.' }, 405);
  }

  const config = loadRazorpayConfig();
  if (!hasRazorpayConfig(config)) {
    return jsonResponse(
      {
        success: false,
        message: 'Payment backend is missing Razorpay configuration.',
      },
      500,
    );
  }

  let payload: CreateOrderPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ success: false, message: 'Invalid JSON body.' }, 400);
  }

  const plan = String(payload.plan ?? '').trim();
  const amount = Number(payload.amount ?? 0);
  const currency = String(payload.currency ?? '').trim().toUpperCase();
  const receipt = String(payload.receipt ?? '').trim();
  if (plan.length === 0 || !Number.isInteger(amount) || amount <= 0 || currency.length != 3) {
    return jsonResponse(
      {
        success: false,
        message: 'Invalid payment order payload.',
      },
      400,
    );
  }

  const response = await fetch(buildRazorpayApiUrl('/v1/orders'), {
    method: 'POST',
    headers: {
      Authorization: buildRazorpayAuthHeader(config),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount,
      currency,
      receipt,
      payment_capture: 1,
      notes: {
        plan,
        displayPrice: String(payload.displayPrice ?? '').trim(),
        periodLabel: String(payload.periodLabel ?? '').trim(),
      },
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    return jsonResponse(
      {
        success: false,
        message: 'Could not create Razorpay order.',
        error: body,
      },
      response.status,
    );
  }

  return jsonResponse({
    success: true,
    message: 'Razorpay order created successfully.',
    orderId: String(body.id ?? ''),
    amount: Number(body.amount ?? amount),
    currency: String(body.currency ?? currency),
    receipt: String(body.receipt ?? receipt),
    status: String(body.status ?? 'created'),
  });
});