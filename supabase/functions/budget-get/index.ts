// Get current budget
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

    const now = new Date();
    const monthYear = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthYearStr = monthYear.toISOString().split('T')[0];

    const { data: budget, error: budgetError } = await supabaseAdmin
      .from('screen_time_budgets')
      .select('*, category_budgets(*)')
      .eq('user_id', user.id)
      .eq('month_year', monthYearStr)
      .single();

    if (budgetError || !budget) {
      return errorResponse('No budget found for current month', 404);
    }

    return successResponse(budget);
  } catch (error: any) {
    console.error('Get budget error:', error);
    return errorResponse(error.message || 'Failed to get budget', 500);
  }
});

