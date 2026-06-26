import { handleCorsPreflight, jsonResponse } from '../_shared/http.ts';
import {
  buildRazorpayApiUrl,
  buildRazorpayAuthHeader,
  constantTimeEquals,
  createRazorpaySignature,
  hasRazorpayConfig,
  loadRazorpayConfig,
} from '../_shared/razorpay.ts';

type VerifyPaymentPayload = {
  plan?: string;
  paymentId?: string;
  orderId?: string;
  signature?: string;
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
        verified: false,
        message: 'Payment backend is missing Razorpay configuration.',
      },
      500,
    );
  }

  let payload: VerifyPaymentPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        message: 'Invalid JSON body.',
      },
      400,
    );
  }

  const paymentId = String(payload.paymentId ?? '').trim();
  const orderId = String(payload.orderId ?? '').trim();
  const signature = String(payload.signature ?? '').trim();
  if (paymentId.length === 0 || orderId.length === 0 || signature.length === 0) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        message: 'Missing required Razorpay verification fields.',
      },
      400,
    );
  }

  const expectedSignature = await createRazorpaySignature(
    orderId,
    paymentId,
    config.keySecret,
  );
  const signatureVerified = constantTimeEquals(expectedSignature, signature);
  if (!signatureVerified) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        signatureVerified: false,
        message: 'Razorpay signature verification failed.',
        paymentId,
        orderId,
      },
      400,
    );
  }

  const paymentResponse = await fetch(
    buildRazorpayApiUrl(`/v1/payments/${paymentId}`),
    {
      method: 'GET',
      headers: {
        Authorization: buildRazorpayAuthHeader(config),
      },
    },
  );
  const paymentBody = await paymentResponse.json().catch(() => ({}));
  if (!paymentResponse.ok) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        signatureVerified: true,
        message: 'Could not fetch Razorpay payment details.',
        paymentId,
        orderId,
        error: paymentBody,
      },
      paymentResponse.status,
    );
  }

  const paymentOrderId = String(paymentBody.order_id ?? '').trim();
  const paymentStatus = String(paymentBody.status ?? '').trim().toLowerCase();
  const captured = paymentBody.captured === true || paymentStatus === 'captured';
  if (paymentOrderId != orderId || !captured) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        signatureVerified: true,
        message: 'Razorpay payment is not captured for this order.',
        paymentId,
        orderId,
        paymentStatus,
      },
      400,
    );
  }

  return jsonResponse({
    success: true,
    verified: true,
    signatureVerified: true,
    message: 'Razorpay payment verified successfully.',
    paymentId,
    orderId,
    paymentStatus,
  });
});