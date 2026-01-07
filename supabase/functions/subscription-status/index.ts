// Get subscription status
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

    const { data: subscription, error } = await supabaseAdmin
      .from('subscriptions')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (error || !subscription) {
      return successResponse({
        status: 'none',
        hasAccess: false,
        message: 'No subscription found. Start your 7-day free trial!',
      });
    }

    const now = new Date();
    let hasAccess = false;
    let message = '';

    if (subscription.status === 'trial') {
      const trialEnded = subscription.trial_end_date && new Date(subscription.trial_end_date) < now;
      hasAccess = !trialEnded;
      const daysRemaining = subscription.trial_end_date
        ? Math.ceil(
            (new Date(subscription.trial_end_date).getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          )
        : 0;
      message = trialEnded
        ? 'Trial expired. Subscribe for $0.99/mo to continue.'
        : `${daysRemaining} days remaining in your free trial`;
    } else if (subscription.status === 'active') {
      const expired = subscription.subscription_end_date && new Date(subscription.subscription_end_date) < now;
      hasAccess = !expired;
      message = expired ? 'Subscription expired' : 'Active subscription';
    } else {
      message = 'Subscription required';
    }

    return successResponse({
      status: subscription.status,
      hasAccess,
      platform: subscription.platform,
      trialEndDate: subscription.trial_end_date,
      renewalDate: subscription.renewal_date,
      priceUSD: subscription.price_usd,
      message,
    });
  } catch (error: any) {
    console.error('Get subscription status error:', error);
    return errorResponse(error.message || 'Failed to get subscription status', 500);
  }
});

