// Get daily usage
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
    const dateParam = url.searchParams.get('date');
    const usageDate = dateParam ? new Date(dateParam) : new Date();

    const monthStart = new Date(usageDate.getFullYear(), usageDate.getMonth(), 1);
    const dateStr = usageDate.toISOString().split('T')[0];
    const monthStartStr = monthStart.toISOString().split('T')[0];

    // Get budget
    const { data: budget } = await supabaseAdmin
      .from('screen_time_budgets')
      .select('*, category_budgets(*)')
      .eq('user_id', user.id)
      .eq('month_year', monthStartStr)
      .single();

    if (!budget) {
      return errorResponse('No budget found for current month', 404);
    }

    const monthEnd = new Date(usageDate.getFullYear(), usageDate.getMonth() + 1, 0);
    const monthEndStr = monthEnd.toISOString().split('T')[0];

    // Get daily and monthly usage
    const [dailyResult, monthlyResult] = await Promise.all([
      supabaseAdmin
        .from('daily_app_usage')
        .select('total_minutes, user_apps(category_type, app_name)')
        .eq('user_id', user.id)
        .eq('usage_date', dateStr),
      supabaseAdmin
        .from('daily_app_usage')
        .select('total_minutes, user_apps(category_type)')
        .eq('user_id', user.id)
        .gte('usage_date', monthStartStr)
        .lte('usage_date', monthEndStr),
    ]);

    const dailyUsages = dailyResult.data || [];
    const monthlyUsages = monthlyResult.data || [];

    // Aggregate
    const categoryMap = new Map<string, { totalMinutes: number; monthlyUsed: number; apps: any[] }>();

    for (const usage of dailyUsages) {
      const category = usage.user_apps?.category_type || 'other';
      if (!categoryMap.has(category)) {
        categoryMap.set(category, { totalMinutes: 0, monthlyUsed: 0, apps: [] });
      }
      const data = categoryMap.get(category)!;
      data.totalMinutes += usage.total_minutes;
      data.apps.push({
        name: usage.user_apps?.app_name || '',
        minutes: usage.total_minutes,
      });
    }

    for (const usage of monthlyUsages) {
      const category = usage.user_apps?.category_type || 'other';
      const data = categoryMap.get(category);
      if (data) {
        data.monthlyUsed += usage.total_minutes;
      }
    }

    // Build response
    const categories: any = {};
    let totalMinutes = 0;

    for (const categoryBudget of budget.category_budgets) {
      const categoryData = categoryMap.get(categoryBudget.category_type) || {
        totalMinutes: 0,
        monthlyUsed: 0,
        apps: [],
      };

      const daysInMonth = new Date(usageDate.getFullYear(), usageDate.getMonth() + 1, 0).getDate();
      const dailyBudget = Math.round((Number(categoryBudget.monthly_hours) * 60) / daysInMonth);
      const monthlyBudgetMinutes = Number(categoryBudget.monthly_hours) * 60;

      categories[categoryBudget.category_type] = {
        totalMinutes: categoryData.totalMinutes,
        dailyBudget,
        monthlyBudget: monthlyBudgetMinutes,
        monthlyUsed: categoryData.monthlyUsed,
        status:
          categoryData.totalMinutes > dailyBudget
            ? 'over'
            : categoryData.totalMinutes === dailyBudget
            ? 'at_limit'
            : 'under',
        apps: categoryData.apps,
      };

      totalMinutes += categoryData.totalMinutes;
    }

    return successResponse({
      date: usageDate.toISOString(),
      totalMinutes,
      categories,
    });
  } catch (error: any) {
    console.error('Get daily usage error:', error);
    return errorResponse(error.message || 'Failed to get daily usage', 500);
  }
});

