// Cancel subscription
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
      return errorResponse('No active subscription found', 404);
    }

    // For iOS subscriptions, cancellation is handled through App Store
    // The user cancels in Settings → App Store → Subscriptions
    // We just update the status in our database

    // Update subscription status
    await supabaseAdmin
      .from('subscriptions')
      .update({ status: 'cancelled' })
      .eq('user_id', user.id);

    return successResponse({ message: 'Subscription cancelled successfully' });
  } catch (error: any) {
    console.error('Cancel subscription error:', error);
    return errorResponse(error.message || 'Failed to cancel subscription', 500);
  }
});

