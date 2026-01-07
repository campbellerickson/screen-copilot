// Database client using Supabase PostgREST
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// Supabase automatically provides SUPABASE_URL and SUPABASE_ANON_KEY
// We only need SERVICE_ROLE_KEY as a custom secret (without SUPABASE_ prefix)
const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') || '';

// Service role client for admin operations
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Helper to get authenticated user's Supabase client
export function getSupabaseClient(authToken: string) {
  return createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: {
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
    },
  });
}

