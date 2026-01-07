// Sync usage data
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

    const { usageDate, apps } = await req.json();

    if (!usageDate || !apps || !Array.isArray(apps)) {
      return errorResponse('usageDate and apps array are required', 400);
    }

    const usageDateObj = new Date(usageDate);
    const dateOnly = new Date(usageDateObj.getFullYear(), usageDateObj.getMonth(), usageDateObj.getDate());
    const dateStr = dateOnly.toISOString().split('T')[0];

    let synced = 0;
    const errors: string[] = [];

    // Process apps in batches
    const BATCH_SIZE = 10;
    for (let i = 0; i < apps.length; i += BATCH_SIZE) {
      const batch = apps.slice(i, i + BATCH_SIZE);
      
      const batchPromises = batch.map(async (app: any) => {
        try {
          // Find or create user app
          const { data: userApp, error: appError } = await supabaseAdmin
            .from('user_apps')
            .upsert({
              user_id: user.id,
              bundle_id: app.bundleId,
              app_name: app.appName,
              category_type: categorizeApp(app.bundleId, app.appName),
              last_detected: new Date().toISOString(),
            }, {
              onConflict: 'user_id,bundle_id',
            })
            .select()
            .single();

          if (appError || !userApp) {
            throw appError || new Error('Failed to create user app');
          }

          // Create or update daily usage
          const { data: existingUsage } = await supabaseAdmin
            .from('daily_app_usage')
            .select('id')
            .eq('user_id', user.id)
            .eq('app_id', userApp.id)
            .eq('usage_date', dateStr)
            .maybeSingle();

          if (existingUsage) {
            await supabaseAdmin
              .from('daily_app_usage')
              .update({
                total_minutes: app.totalMinutes,
                synced_at: new Date().toISOString(),
              })
              .eq('id', existingUsage.id);
          } else {
            const { error: insertError } = await supabaseAdmin
              .from('daily_app_usage')
              .insert({
                user_id: user.id,
                app_id: userApp.id,
                usage_date: dateStr,
                total_minutes: app.totalMinutes,
                synced_at: new Date().toISOString(),
              });

            if (insertError) throw insertError;
          }

          return true;
        } catch (error: any) {
          errors.push(`Failed to sync ${app.appName}: ${error.message}`);
          return false;
        }
      });

      const results = await Promise.allSettled(batchPromises);
      results.forEach((result) => {
        if (result.status === 'fulfilled' && result.value) {
          synced++;
        }
      });
    }

    // Get updated budget status
    const budgetStatus = await getDailyUsage(user.id, dateOnly);

    // Calculate category usage
    const categoryUsage: { [key: string]: number } = {};
    const monthlyUsage: { [key: string]: number } = {};
    
    for (const [category, data] of Object.entries(budgetStatus.categories)) {
      categoryUsage[category] = data.totalMinutes;
      monthlyUsage[category] = data.monthlyUsed;
    }

    // Check for alerts and notifications
    const { alerts, notifications } = await checkAndTriggerAlerts(
      user.id,
      dateOnly,
      categoryUsage,
      monthlyUsage
    );

    return successResponse({
      synced,
      budgetStatus: budgetStatus.categories,
      alertsTriggered: alerts,
      notifications,
    });
  } catch (error: any) {
    console.error('Sync usage error:', error);
    return errorResponse(error.message || 'Failed to sync usage', 500);
  }
});

function categorizeApp(bundleId: string, appName: string): string {
  const lowerName = appName.toLowerCase();
  const lowerId = bundleId.toLowerCase();

  if (
    lowerId.includes('instagram') || lowerId.includes('tiktok') ||
    lowerId.includes('twitter') || lowerId.includes('facebook') ||
    lowerId.includes('snapchat') || lowerId.includes('reddit') ||
    lowerId.includes('discord') || lowerName.includes('social')
  ) {
    return 'social_media';
  }

  if (
    lowerId.includes('netflix') || lowerId.includes('youtube') ||
    lowerId.includes('spotify') || lowerId.includes('hulu') ||
    lowerId.includes('disney') || lowerId.includes('twitch') ||
    lowerName.includes('video') || lowerName.includes('music')
  ) {
    return 'entertainment';
  }

  if (lowerName.includes('game') || lowerId.includes('game')) {
    return 'gaming';
  }

  if (
    lowerId.includes('notion') || lowerId.includes('slack') ||
    lowerId.includes('zoom') || lowerId.includes('teams') ||
    lowerId.includes('office') || lowerId.includes('google') ||
    lowerName.includes('work')
  ) {
    return 'productivity';
  }

  if (
    lowerId.includes('amazon') || lowerId.includes('shop') ||
    lowerId.includes('ebay') || lowerName.includes('shop')
  ) {
    return 'shopping';
  }

  if (lowerName.includes('news') || lowerName.includes('read') || lowerId.includes('news')) {
    return 'news_reading';
  }

  if (lowerName.includes('health') || lowerName.includes('fitness') || lowerName.includes('workout')) {
    return 'health_fitness';
  }

  return 'other';
}

async function getDailyUsage(userId: string, date: Date) {
  const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
  const monthEnd = new Date(date.getFullYear(), date.getMonth() + 1, 0);
  const dateStr = date.toISOString().split('T')[0];
  const monthStartStr = monthStart.toISOString().split('T')[0];
  const monthEndStr = monthEnd.toISOString().split('T')[0];

  // Get current budget
  const monthYearStr = monthStart.toISOString().split('T')[0];
  const { data: budget } = await supabaseAdmin
    .from('screen_time_budgets')
    .select('*, category_budgets(*)')
    .eq('user_id', userId)
    .eq('month_year', monthYearStr)
    .single();

  if (!budget) {
    throw new Error('No budget found for current month');
  }

  // Get daily and monthly usage
  const [dailyResult, monthlyResult] = await Promise.all([
    supabaseAdmin
      .from('daily_app_usage')
      .select('total_minutes, user_apps(category_type, app_name)')
      .eq('user_id', userId)
      .eq('usage_date', dateStr),
    supabaseAdmin
      .from('daily_app_usage')
      .select('total_minutes, user_apps(category_type)')
      .eq('user_id', userId)
      .gte('usage_date', monthStartStr)
      .lte('usage_date', monthEndStr),
  ]);

  const dailyUsages = dailyResult.data || [];
  const monthlyUsages = monthlyResult.data || [];

  // Aggregate by category
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

    const daysInMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
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

  return {
    date: date.toISOString(),
    totalMinutes,
    categories,
  };
}

async function checkAndTriggerAlerts(
  userId: string,
  date: Date,
  categoryUsage: { [key: string]: number },
  monthlyUsage: { [key: string]: number }
) {
  const alerts: any[] = [];
  const notifications: any[] = [];

  const dateStr = date.toISOString().split('T')[0];
  const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
  const monthYearStr = monthStart.toISOString().split('T')[0];

  // Get budget
  const { data: budget } = await supabaseAdmin
    .from('screen_time_budgets')
    .select('*, category_budgets(*)')
    .eq('user_id', userId)
    .eq('month_year', monthYearStr)
    .single();

  if (!budget) {
    return { alerts, notifications };
  }

  // Get existing alerts
  const { data: existingAlerts } = await supabaseAdmin
    .from('budget_alerts')
    .select('category_type')
    .eq('user_id', userId)
    .eq('alert_date', dateStr);

  const existingCategoryTypes = new Set((existingAlerts || []).map((a: any) => a.category_type));
  const monthlyNotificationsToday = new Set<string>();

  for (const categoryBudget of budget.category_budgets) {
    if (categoryBudget.is_excluded) continue;

    const categoryType = categoryBudget.category_type;
    const categoryName = categoryBudget.category_name;
    const usedToday = categoryUsage[categoryType] || 0;
    const usedMonthly = monthlyUsage[categoryType] || 0;

    const daysInMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
    const dailyBudget = Math.round((Number(categoryBudget.monthly_hours) * 60) / daysInMonth);
    const monthlyBudgetMinutes = Number(categoryBudget.monthly_hours) * 60;

    // Check daily overage
    if (usedToday > dailyBudget) {
      const overageMinutes = usedToday - dailyBudget;

      if (!existingCategoryTypes.has(categoryType)) {
        await supabaseAdmin.from('budget_alerts').insert({
          user_id: userId,
          category_type: categoryType,
          alert_date: dateStr,
          overage_minutes: overageMinutes,
        });

        alerts.push({
          category: categoryName,
          overageMinutes,
        });
      }

      notifications.push({
        type: 'daily_overage',
        categoryType,
        categoryName,
        overageMinutes,
        usedMinutes: usedToday,
        budgetMinutes: dailyBudget,
        message: `You've exceeded your daily ${categoryName} budget by ${formatMinutes(overageMinutes)}`,
      });
    }

    // Check monthly overage
    if (usedMonthly > monthlyBudgetMinutes) {
      const overageMinutes = usedMonthly - monthlyBudgetMinutes;
      const monthlyKey = `monthly_${categoryType}`;

      if (!monthlyNotificationsToday.has(monthlyKey)) {
        notifications.push({
          type: 'monthly_overage',
          categoryType,
          categoryName,
          overageMinutes,
          usedMinutes: usedMonthly,
          budgetMinutes: monthlyBudgetMinutes,
          message: `You've exceeded your monthly ${categoryName} budget by ${formatMinutes(overageMinutes)}`,
        });
        monthlyNotificationsToday.add(monthlyKey);
      }
    }
  }

  return { alerts, notifications };
}

function formatMinutes(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  if (hours > 0 && remainingMinutes > 0) {
    return `${hours}h ${remainingMinutes}m`;
  } else if (hours > 0) {
    return `${hours}h`;
  } else {
    return `${remainingMinutes}m`;
  }
}

