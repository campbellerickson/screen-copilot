// Response helpers for Supabase Edge Functions
import { corsHeaders } from './cors.ts';

export function successResponse(data: any, status = 200): Response {
  return new Response(
    JSON.stringify({
      success: true,
      data,
    }),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    }
  );
}

export function errorResponse(
  error: string,
  status = 400,
  requiresSubscription = false
): Response {
  return new Response(
    JSON.stringify({
      success: false,
      error,
      requiresSubscription,
    }),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    }
  );
}

