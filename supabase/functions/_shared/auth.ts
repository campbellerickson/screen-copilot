// Authentication helpers for Supabase Edge Functions
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// Supabase automatically provides these environment variables
const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';

export interface AuthUser {
  id: string;
  email: string;
}

/**
 * Get authenticated user from request
 */
export async function getAuthUser(request: Request): Promise<AuthUser | null> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.substring(7);
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  });

  const { data: { user }, error } = await supabase.auth.getUser(token);
  
  if (error || !user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email || '',
  };
}

/**
 * Check if user has active subscription or trial
 */
export async function checkSubscription(userId: string): Promise<{
  hasAccess: boolean;
  status: string;
  message?: string;
}> {
  const { supabaseAdmin } = await import('./database.ts');
  
  const { data: subscription, error } = await supabaseAdmin
    .from('subscriptions')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !subscription) {
    return {
      hasAccess: false,
      status: 'none',
      message: 'Subscription required',
    };
  }

  const now = new Date();
  
  // Check trial
  if (subscription.status === 'trial') {
    const trialEndDate = subscription.trial_end_date ? new Date(subscription.trial_end_date) : null;
    const trialEnded = trialEndDate && trialEndDate < now;
    
    return {
      hasAccess: !trialEnded,
      status: trialEnded ? 'trial_expired' : 'trial',
      message: trialEnded ? 'Trial expired' : 'Active trial',
    };
  }

  // Check active subscription
  if (subscription.status === 'active') {
    const endDate = subscription.subscription_end_date ? new Date(subscription.subscription_end_date) : null;
    const expired = endDate && endDate < now;
    
    return {
      hasAccess: !expired,
      status: expired ? 'expired' : 'active',
      message: expired ? 'Subscription expired' : 'Active subscription',
    };
  }

  return {
    hasAccess: false,
    status: subscription.status,
    message: 'Subscription required',
  };
}

