import { handleCorsPreflight, jsonResponse } from '../_shared/http.ts';
import { loadAiConfig, runAiGateway } from '../_shared/ai.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCorsPreflight(req);
  if (corsResponse) {
    return corsResponse;
  }

  if (req.method !== 'POST') {
    return jsonResponse({ success: false, message: 'Method not allowed.' }, 405);
  }

  return runAiGateway(req, loadAiConfig());
});