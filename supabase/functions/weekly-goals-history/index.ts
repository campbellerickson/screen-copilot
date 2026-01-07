// Get weekly goal history
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { getAuthUser, checkSubscription } from '../_shared/auth.ts';
import { supabaseAdmin } from '../_shared/database.ts';

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthUser(req);
    if (!user) {
      return errorResponse('Authentication required', 401);
    }

    const subscriptionCheck = await checkSubscription(user.id);
    if (!subscriptionCheck.hasAccess) {
      return errorResponse(subscriptionCheck.message || 'Subscription required', 403, true);
    }

    const url = new URL(req.url);
    const limit = parseInt(url.searchParams.get('limit') || '4');

    const { data: goals, error } = await supabaseAdmin
      .from('weekly_goals')
      .select('*')
      .eq('user_id', user.id)
      .order('week_start_date', { ascending: false })
      .limit(limit);

    if (error) {
      throw error;
    }

    return successResponse(goals || []);
  } catch (error: any) {
    console.error('Get goal history error:', error);
    return errorResponse(error.message || 'Failed to get goal history', 500);
  }
});

