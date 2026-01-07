// Login with email and password
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { supabaseAdmin } from '../_shared/database.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return errorResponse('Email and password are required', 400);
    }

    // Sign in with Supabase Auth
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email.toLowerCase(),
      password,
    });

    if (authError || !authData.user) {
      return errorResponse('Invalid email or password', 401);
    }

    // Update last login
    await supabaseAdmin
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', authData.user.id);

    // Get subscription status
    const { data: subscription } = await supabaseAdmin
      .from('subscriptions')
      .select('*')
      .eq('user_id', authData.user.id)
      .single();

    const subscriptionStatus = checkSubscriptionStatus(subscription);

    return successResponse({
      user: {
        id: authData.user.id,
        email: authData.user.email,
        name: authData.user.user_metadata?.name || null,
        profileImage: authData.user.user_metadata?.avatar_url || null,
      },
      token: authData.session?.access_token,
      subscription: subscriptionStatus,
    });
  } catch (error: any) {
    console.error('Login error:', error);
    return errorResponse(error.message || 'Failed to login', 500);
  }
});

function checkSubscriptionStatus(subscription: any) {
  if (!subscription) {
    return { status: 'none', hasAccess: false };
  }

  const now = new Date();
  
  if (subscription.status === 'trial') {
    const trialEnded = subscription.trial_end_date && new Date(subscription.trial_end_date) < now;
    return {
      status: trialEnded ? 'trial_expired' : 'trial',
      hasAccess: !trialEnded,
      trialEndDate: subscription.trial_end_date,
      daysRemaining: trialEnded
        ? 0
        : Math.ceil(
            (new Date(subscription.trial_end_date).getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          ),
    };
  }

  if (subscription.status === 'active') {
    const expired = subscription.subscription_end_date && new Date(subscription.subscription_end_date) < now;
    return {
      status: expired ? 'expired' : 'active',
      hasAccess: !expired,
      renewalDate: subscription.renewal_date,
    };
  }

  return { status: subscription.status, hasAccess: false };
}

