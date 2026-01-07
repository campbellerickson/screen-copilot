// Get current user profile
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { getAuthUser } from '../_shared/auth.ts';
import { supabaseAdmin } from '../_shared/database.ts';

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthUser(req);
    if (!user) {
      return errorResponse('Authentication required', 401);
    }

    // Get user from database
    const { data: userData, error: userError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single();

    if (userError || !userData) {
      return errorResponse('User not found', 404);
    }

    // Get subscription
    const { data: subscription } = await supabaseAdmin
      .from('subscriptions')
      .select('*')
      .eq('user_id', user.id)
      .single();

    const subscriptionStatus = checkSubscriptionStatus(subscription);

    return successResponse({
      user: {
        id: userData.id,
        email: userData.email,
        name: userData.name,
        profileImage: userData.profile_image,
        createdAt: userData.created_at,
      },
      subscription: subscriptionStatus,
    });
  } catch (error: any) {
    console.error('Get current user error:', error);
    return errorResponse(error.message || 'Failed to get user profile', 500);
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

