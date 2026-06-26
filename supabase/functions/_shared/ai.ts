import { corsHeaders, jsonResponse } from './http.ts';

export type AiGatewayPayload = {
  prompt?: string;
  temperature?: number;
  preferJsonObjectMode?: boolean;
  requestType?: string;
  correlationId?: string;
  maxTokens?: number;
};

export type AiBackendConfig = {
  environment: string;
  provider: 'groq';
  apiKey: string;
  model: string;
  upstreamTimeoutMs: number;
  maxRetries: number;
};

type GroqRequestArgs = {
  payload: AiGatewayPayload;
  config: AiBackendConfig;
  correlationId: string;
  attempt?: number;
};

const groqChatCompletionsUrl = 'https://api.groq.com/openai/v1/chat/completions';
const groqModelsUrl = 'https://api.groq.com/openai/v1/models';
const defaultModel = 'llama-3.3-70b-versatile';
const defaultTimeoutMs = 45000;
const defaultMaxRetries = 2;

export function loadAiConfig(): AiBackendConfig {
  return {
    environment: readEnv('AI_ENV', 'development'),
    provider: 'groq',
    apiKey: readEnv('GROQ_API_KEY'),
    model: readEnv('GROQ_MODEL', defaultModel),
    upstreamTimeoutMs: readPositiveIntEnv('AI_UPSTREAM_TIMEOUT_MS', defaultTimeoutMs),
    maxRetries: readPositiveIntEnv('AI_MAX_RETRIES', defaultMaxRetries),
  };
}

export function hasAiConfig(config: AiBackendConfig): boolean {
  return config.apiKey.trim().length > 0;
}

export async function runAiGateway(
  req: Request,
  config: AiBackendConfig,
): Promise<Response> {
  let payload: AiGatewayPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({
      success: false,
      code: 'invalid_json',
      message: 'Invalid JSON body.',
    }, 400);
  }

  const prompt = String(payload.prompt ?? '').trim();
  if (prompt.length === 0) {
    return jsonResponse({
      success: false,
      code: 'invalid_prompt',
      message: 'AI request prompt is required.',
    }, 400);
  }

  if (!hasAiConfig(config)) {
    logAi('AI gateway missing server configuration', {
      environment: config.environment,
    }, 'error');
    return jsonResponse({
      success: false,
      code: 'missing_configuration',
      message: 'AI service configuration is incomplete on the server.',
      provider: config.provider,
      environment: config.environment,
    }, 500);
  }

  const correlationId = String(payload.correlationId ?? crypto.randomUUID()).trim() || crypto.randomUUID();
  return requestGroqChatCompletion({
    payload: {
      ...payload,
      prompt,
      correlationId,
    },
    config,
    correlationId,
  });
}

export async function runAiHealthCheck(
  req: Request,
  config: AiBackendConfig,
): Promise<Response> {
  const url = new URL(req.url);
  const probe = url.searchParams.get('probe')?.trim().toLowerCase() ?? 'provider';
  const configured = hasAiConfig(config);

  if (!configured) {
    return jsonResponse({
      success: false,
      configured: false,
      reachable: false,
      provider: config.provider,
      environment: config.environment,
      message: 'AI service configuration is missing on the server.',
    }, 503);
  }

  if (probe !== 'provider') {
    return jsonResponse({
      success: true,
      configured: true,
      reachable: true,
      provider: config.provider,
      environment: config.environment,
      message: 'AI gateway is configured.',
    });
  }

  const controller = AbortSignal.timeout(Math.min(config.upstreamTimeoutMs, 10000));
  try {
    const response = await fetch(groqModelsUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
      },
      signal: controller,
    });
    const bodyText = await response.text();

    if (!response.ok) {
      logAi('AI health provider probe failed', {
        statusCode: response.status,
        bodyPreview: summarizeBody(bodyText),
        environment: config.environment,
      }, 'warn');
      return jsonResponse({
        success: false,
        configured: true,
        reachable: false,
        provider: config.provider,
        environment: config.environment,
        message: extractProviderErrorMessage(safeJsonDecode(bodyText), bodyText) ??
            'AI provider health probe failed.',
      }, 503);
    }

    return jsonResponse({
      success: true,
      configured: true,
      reachable: true,
      provider: config.provider,
      environment: config.environment,
      model: config.model,
      message: 'AI service is healthy.',
    });
  } catch (error) {
    logAi('AI health provider probe threw exception', {
      error: String(error),
      environment: config.environment,
    }, 'error');
    return jsonResponse({
      success: false,
      configured: true,
      reachable: false,
      provider: config.provider,
      environment: config.environment,
      message: looksLikeTimeout(error)
          ? 'AI health probe timed out.'
          : 'AI health probe could not reach the provider.',
    }, 503);
  }
}

async function requestGroqChatCompletion({
  payload,
  config,
  correlationId,
  attempt = 0,
}: GroqRequestArgs): Promise<Response> {
  const prompt = String(payload.prompt ?? '').trim();
  const preferJsonObjectMode = payload.preferJsonObjectMode !== false;
  const temperature = normalizeTemperature(payload.temperature);
  const maxTokens = Number.isFinite(payload.maxTokens)
    ? Math.max(256, Math.min(Number(payload.maxTokens), 4096))
    : 2048;

  const requestBody: Record<string, unknown> = {
    model: config.model,
    messages: [
      {
        role: 'system',
        content:
          'You are an expert resume writer. Always respond with a single valid JSON object only, with no markdown and no extra text.',
      },
      {
        role: 'user',
        content: prompt,
      },
    ],
    temperature,
    max_tokens: maxTokens,
  };

  if (preferJsonObjectMode) {
    requestBody.response_format = { type: 'json_object' };
  }

  logAi('Dispatching AI gateway request', {
    correlationId,
    attempt: attempt + 1,
    requestType: String(payload.requestType ?? 'generic'),
    jsonObjectMode: preferJsonObjectMode,
    temperature,
    environment: config.environment,
    promptLength: prompt.length,
  });

  try {
    const response = await fetch(groqChatCompletionsUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify(requestBody),
      signal: AbortSignal.timeout(config.upstreamTimeoutMs),
    });
    const bodyText = await response.text();

    logAi('Received AI gateway provider response', {
      correlationId,
      attempt: attempt + 1,
      statusCode: response.status,
      bodyPreview: summarizeBody(bodyText),
    });

    if (response.ok) {
      return new Response(bodyText, {
        status: 200,
        headers: {
          ...corsHeaders,
          'X-Correlation-Id': correlationId,
        },
      });
    }

    const errorData = safeJsonDecode(bodyText);
    if (
      response.status === 400 &&
      preferJsonObjectMode &&
      isJsonGenerationFailure(errorData, bodyText)
    ) {
      const fallbackTemperature = temperature > 0.35 ? 0.35 : temperature;
      return requestGroqChatCompletion({
        payload: {
          ...payload,
          temperature: fallbackTemperature,
          preferJsonObjectMode: false,
        },
        config,
        correlationId,
        attempt,
      });
    }

    if ((response.status === 429 || response.status >= 500) && attempt < config.maxRetries) {
      await sleep(backoffDelayMs(attempt));
      return requestGroqChatCompletion({
        payload,
        config,
        correlationId,
        attempt: attempt + 1,
      });
    }

    return jsonResponse({
      success: false,
      code: mapProviderErrorCode(response.status),
      message: extractProviderErrorMessage(errorData, bodyText) ?? mapFallbackMessage(response.status),
      provider: config.provider,
      environment: config.environment,
      correlationId,
    }, mapClientStatus(response.status));
  } catch (error) {
    logAi('AI gateway provider request threw exception', {
      correlationId,
      attempt: attempt + 1,
      error: String(error),
    }, 'error');

    if ((looksLikeTimeout(error) || looksLikeNetworkError(error)) && attempt < config.maxRetries) {
      await sleep(backoffDelayMs(attempt));
      return requestGroqChatCompletion({
        payload,
        config,
        correlationId,
        attempt: attempt + 1,
      });
    }

    const status = looksLikeTimeout(error) ? 504 : 503;
    return jsonResponse({
      success: false,
      code: looksLikeTimeout(error) ? 'timeout' : 'network_error',
      message: looksLikeTimeout(error)
          ? 'AI provider request timed out.'
          : 'AI provider request failed due to a network error.',
      provider: config.provider,
      environment: config.environment,
      correlationId,
    }, status);
  }
}

export function logAi(
  message: string,
  details: Record<string, unknown> = {},
  level: 'log' | 'warn' | 'error' = 'log',
): void {
  console[level](`[ai] ${message} ${JSON.stringify(details)}`);
}

function readEnv(name: string, fallback = ''): string {
  return Deno.env.get(name)?.trim() || fallback;
}

function readPositiveIntEnv(name: string, fallback: number): number {
  const raw = readEnv(name);
  if (raw.length === 0) {
    return fallback;
  }
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function normalizeTemperature(value: unknown): number {
  const parsed = typeof value === 'number' ? value : Number(value ?? 0.7);
  if (!Number.isFinite(parsed)) {
    return 0.7;
  }
  return Math.max(0, Math.min(parsed, 1.5));
}

function safeJsonDecode(source: string): Record<string, unknown> | null {
  try {
    const decoded = JSON.parse(source);
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      return decoded as Record<string, unknown>;
    }
  } catch (_) {
    return null;
  }
  return null;
}

function isJsonGenerationFailure(
  errorData: Record<string, unknown> | null,
  rawBody: string,
): boolean {
  const body = rawBody.toLowerCase();
  if (body.includes('json_object') || body.includes('response_format')) {
    return true;
  }

  const error = errorData?.error;
  if (error && typeof error === 'object' && !Array.isArray(error)) {
    const message = String((error as Record<string, unknown>).message ?? '').toLowerCase();
    return message.includes('json') || message.includes('response_format');
  }

  return false;
}

function extractProviderErrorMessage(
  errorData: Record<string, unknown> | null,
  rawBody: string,
): string | null {
  const error = errorData?.error;
  if (error && typeof error === 'object' && !Array.isArray(error)) {
    const message = String((error as Record<string, unknown>).message ?? '').trim();
    if (message.length > 0) {
      return message;
    }
  }

  const message = String(errorData?.message ?? '').trim();
  if (message.length > 0) {
    return message;
  }

  const normalizedBody = rawBody.replace(/\s+/g, ' ').trim();
  if (normalizedBody.length > 0 && normalizedBody.length <= 240) {
    return normalizedBody;
  }

  return null;
}

function summarizeBody(body: string): string {
  const normalized = body.replace(/\s+/g, ' ').trim();
  if (normalized.length === 0) {
    return '<empty>';
  }
  return normalized.length <= 240 ? normalized : `${normalized.slice(0, 240)}...`;
}

function backoffDelayMs(attempt: number): number {
  return 800 * (2 ** attempt);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function mapProviderErrorCode(statusCode: number): string {
  if (statusCode === 401 || statusCode === 403) {
    return 'invalid_server_key';
  }
  if (statusCode === 429) {
    return 'rate_limit';
  }
  if (statusCode >= 500) {
    return 'provider_server_error';
  }
  if (statusCode === 400) {
    return 'invalid_request';
  }
  return 'provider_error';
}

function mapFallbackMessage(statusCode: number): string {
  if (statusCode === 401 || statusCode === 403) {
    return 'AI provider credentials are invalid on the server.';
  }
  if (statusCode === 429) {
    return 'AI provider rate limit reached.';
  }
  if (statusCode >= 500) {
    return 'AI provider is temporarily unavailable.';
  }
  if (statusCode === 400) {
    return 'AI request payload was rejected by the provider.';
  }
  return 'AI provider request failed.';
}

function mapClientStatus(statusCode: number): number {
  if (statusCode === 401 || statusCode === 403) {
    return 502;
  }
  if (statusCode === 429) {
    return 429;
  }
  if (statusCode >= 500) {
    return 503;
  }
  if (statusCode === 400) {
    return 400;
  }
  return 502;
}

function looksLikeTimeout(error: unknown): boolean {
  return String(error).toLowerCase().includes('timeout');
}

function looksLikeNetworkError(error: unknown): boolean {
  const message = String(error).toLowerCase();
  return message.includes('network') ||
    message.includes('connection') ||
    message.includes('dns') ||
    message.includes('socket');
}