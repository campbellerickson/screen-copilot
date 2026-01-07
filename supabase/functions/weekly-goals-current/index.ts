// Get current week's goal
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

async function getAverageWeeklyUsage(userId: string): Promise<number> {
  const now = new Date();
  const weekAgo = new Date(now);
  weekAgo.setDate(weekAgo.getDate() - 7);
  const weekAgoStr = weekAgo.toISOString().split('T')[0];
  const nowStr = now.toISOString().split('T')[0];

  const { data: usage } = await supabaseAdmin
    .from('daily_app_usage')
    .select('total_minutes')
    .eq('user_id', userId)
    .gte('usage_date', weekAgoStr)
    .lte('usage_date', nowStr);

  const totalMinutes = (usage || []).reduce((sum, u) => sum + u.total_minutes, 0);
  return totalMinutes || 1680; // Default: 4 hours/day * 7 days
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

    const weekStart = getWeekStartDate(new Date());
    const weekStartStr = weekStart.toISOString().split('T')[0];

    const { data: goal, error } = await supabaseAdmin
      .from('weekly_goals')
      .select('*')
      .eq('user_id', user.id)
      .eq('week_start_date', weekStartStr)
      .single();

    if (error || !goal) {
      // Create default goal
      const averageMinutes = await getAverageWeeklyUsage(user.id);
      const targetMinutes = Math.round(averageMinutes * 0.8);

      const { data: newGoal, error: createError } = await supabaseAdmin
        .from('weekly_goals')
        .insert({
          user_id: user.id,
          week_start_date: weekStartStr,
          target_minutes: targetMinutes,
          current_minutes: 0,
          days_completed: 0,
          is_active: true,
        })
        .select()
        .single();

      if (createError || !newGoal) {
        throw createError;
      }

      return successResponse(newGoal);
    }

    return successResponse(goal);
  } catch (error: any) {
    console.error('Get weekly goal error:', error);
    return errorResponse(error.message || 'Failed to get weekly goal', 500);
  }
});

