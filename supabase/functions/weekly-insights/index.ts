// Get weekly insights
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

    const url = new URL(req.url);
    const weekStartDateParam = url.searchParams.get('weekStartDate');
    const weekStart = weekStartDateParam
      ? getWeekStartDate(new Date(weekStartDateParam))
      : getWeekStartDate(new Date());

    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    const weekStartStr = weekStart.toISOString().split('T')[0];
    const weekEndStr = weekEnd.toISOString().split('T')[0];

    // Get usage for the week
    const { data: weekUsage } = await supabaseAdmin
      .from('daily_app_usage')
      .select('total_minutes, usage_date, user_apps(category_type, app_name)')
      .eq('user_id', user.id)
      .gte('usage_date', weekStartStr)
      .lte('usage_date', weekEndStr);

    // Calculate totals
    const categoryTotals = new Map<string, number>();
    const appTotals = new Map<string, number>();
    const dailyTotals = new Map<string, number>();

    for (const usage of weekUsage || []) {
      const category = usage.user_apps?.category_type || 'other';
      categoryTotals.set(category, (categoryTotals.get(category) || 0) + usage.total_minutes);

      const appName = usage.user_apps?.app_name || '';
      appTotals.set(appName, (appTotals.get(appName) || 0) + usage.total_minutes);

      const dateStr = usage.usage_date;
      dailyTotals.set(dateStr, (dailyTotals.get(dateStr) || 0) + usage.total_minutes);
    }

    // Get previous week
    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setDate(prevWeekStart.getDate() - 7);
    const prevWeekEnd = new Date(weekStart);
    prevWeekEnd.setDate(prevWeekEnd.getDate() - 1);
    const prevWeekStartStr = prevWeekStart.toISOString().split('T')[0];
    const prevWeekEndStr = prevWeekEnd.toISOString().split('T')[0];

    const { data: prevWeekUsage } = await supabaseAdmin
      .from('daily_app_usage')
      .select('total_minutes')
      .eq('user_id', user.id)
      .gte('usage_date', prevWeekStartStr)
      .lte('usage_date', prevWeekEndStr);

    const prevWeekTotal = (prevWeekUsage || []).reduce((sum, u) => sum + u.total_minutes, 0);
    const currentWeekTotal = Array.from(dailyTotals.values()).reduce((sum, m) => sum + m, 0);

    // Get top categories and apps
    const topCategories = Array.from(categoryTotals.entries())
      .map(([category, minutes]) => ({ category, minutes }))
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 5);

    const topApps = Array.from(appTotals.entries())
      .map(([appName, minutes]) => ({ appName, minutes }))
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 5);

    const dailyBreakdown = Array.from(dailyTotals.entries()).map(([date, minutes]) => ({
      date,
      minutes,
    }));

    return successResponse({
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
      totalMinutes: currentWeekTotal,
      previousWeekTotal: prevWeekTotal,
      change: currentWeekTotal - prevWeekTotal,
      changePercent: prevWeekTotal > 0 ? ((currentWeekTotal - prevWeekTotal) / prevWeekTotal) * 100 : 0,
      averageDailyMinutes: Math.round(currentWeekTotal / 7),
      topCategories,
      topApps,
      dailyBreakdown,
    });
  } catch (error: any) {
    console.error('Get weekly insights error:', error);
    return errorResponse(error.message || 'Failed to get weekly insights', 500);
  }
});

