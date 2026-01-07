// Set weekly goal
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { getAuthUser, checkSubscription } from '../_shared/auth.ts';
import { supabaseAdmin } from '../_shared/database.ts';

function getWeekStartDate(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(d.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return monday;
}

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

    const { targetMinutes, weekStartDate } = await req.json();

    if (!targetMinutes || targetMinutes <= 0) {
      return errorResponse('Target minutes must be greater than 0', 400);
    }

    const weekStart = weekStartDate
      ? getWeekStartDate(new Date(weekStartDate))
      : getWeekStartDate(new Date());
    const weekStartStr = weekStart.toISOString().split('T')[0];

    const { data: goal, error } = await supabaseAdmin
      .from('weekly_goals')
      .upsert({
        user_id: user.id,
        week_start_date: weekStartStr,
        target_minutes: targetMinutes,
        current_minutes: 0,
        days_completed: 0,
        is_active: true,
      }, {
        onConflict: 'user_id,week_start_date',
      })
      .select()
      .single();

    if (error) {
      throw error;
    }

    return successResponse(goal);
  } catch (error: any) {
    console.error('Set weekly goal error:', error);
    return errorResponse(error.message || 'Failed to set weekly goal', 500);
  }
});

