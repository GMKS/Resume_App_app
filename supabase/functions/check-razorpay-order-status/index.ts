import { handleCorsPreflight, jsonResponse } from '../_shared/http.ts';
import {
  buildRazorpayApiUrl,
  buildRazorpayAuthHeader,
  hasRazorpayConfig,
  loadRazorpayConfig,
} from '../_shared/razorpay.ts';

type CheckOrderStatusPayload = {
  plan?: string;
  orderId?: string;
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
        pending: false,
        cancelled: false,
        message: 'Payment backend is missing Razorpay configuration.',
      },
      500,
    );
  }

  let payload: CheckOrderStatusPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Invalid JSON body.',
      },
      400,
    );
  }

  const orderId = String(payload.orderId ?? '').trim();
  if (orderId.length === 0) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Missing required Razorpay order ID.',
      },
      400,
    );
  }

  const authHeader = buildRazorpayAuthHeader(config);
  const [orderResponse, paymentsResponse] = await Promise.all([
    fetch(buildRazorpayApiUrl(`/v1/orders/${orderId}`), {
      method: 'GET',
      headers: {
        Authorization: authHeader,
      },
    }),
    fetch(buildRazorpayApiUrl(`/v1/orders/${orderId}/payments`), {
      method: 'GET',
      headers: {
        Authorization: authHeader,
      },
    }),
  ]);

  const orderBody = await orderResponse.json().catch(() => ({}));
  const paymentsBody = await paymentsResponse.json().catch(() => ({}));

  if (!orderResponse.ok) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Could not fetch Razorpay order details.',
        orderId,
        error: orderBody,
      },
      orderResponse.status,
    );
  }

  if (!paymentsResponse.ok) {
    return jsonResponse(
      {
        success: false,
        verified: false,
        pending: false,
        cancelled: false,
        message: 'Could not fetch Razorpay order payment details.',
        orderId,
        orderStatus: String(orderBody.status ?? '').trim().toLowerCase(),
        error: paymentsBody,
      },
      paymentsResponse.status,
    );
  }

  const orderStatus = String(orderBody.status ?? '').trim().toLowerCase();
  const paymentItems = Array.isArray(paymentsBody.items)
    ? [...paymentsBody.items]
    : [];
  paymentItems.sort((a, b) => Number(b?.created_at ?? 0) - Number(a?.created_at ?? 0));
  const payment = paymentItems[0] ?? null;
  const paymentId = String(payment?.id ?? '').trim();
  const paymentStatus = String(payment?.status ?? '').trim().toLowerCase();

  const isCaptured = orderStatus === 'paid' || paymentStatus === 'captured';
  if (isCaptured) {
    return jsonResponse({
      success: true,
      verified: true,
      pending: false,
      cancelled: false,
      message: 'Razorpay payment confirmed successfully.',
      orderId,
      paymentId,
      orderStatus,
      paymentStatus: paymentStatus || 'captured',
    });
  }

  if (paymentStatus == 'authorized' || paymentStatus == 'created') {
    return jsonResponse({
      success: true,
      verified: false,
      pending: true,
      cancelled: false,
      message: 'Payment confirmation is still pending.',
      orderId,
      paymentId: paymentId || null,
      orderStatus,
      paymentStatus,
    });
  }

  if (paymentStatus == 'failed') {
    return jsonResponse({
      success: true,
      verified: false,
      pending: false,
      cancelled: true,
      message: 'Payment could not be completed. Please try again.',
      orderId,
      paymentId: paymentId || null,
      orderStatus,
      paymentStatus,
    });
  }

  return jsonResponse({
    success: true,
    verified: false,
    pending: false,
    cancelled: true,
    message: 'Payment was cancelled. No amount was charged.',
    orderId,
    paymentId: paymentId || null,
    orderStatus,
    paymentStatus: paymentStatus || null,
  });
});
