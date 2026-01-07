// Create budget
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

    const { monthYear, categories } = await req.json();

    if (!monthYear || !categories || !Array.isArray(categories)) {
      return errorResponse('monthYear and categories array are required', 400);
    }

    const monthYearDate = new Date(monthYear);
    
    // Delete existing budget for this month
    await supabaseAdmin
      .from('screen_time_budgets')
      .delete()
      .eq('user_id', user.id)
      .eq('month_year', monthYearDate.toISOString().split('T')[0]);

    // Create new budget
    const { data: budget, error: budgetError } = await supabaseAdmin
      .from('screen_time_budgets')
      .insert({
        user_id: user.id,
        month_year: monthYearDate.toISOString().split('T')[0],
      })
      .select()
      .single();

    if (budgetError || !budget) {
      throw budgetError;
    }

    // Create categories
    const categoryInserts = categories.map((cat: any) => ({
      budget_id: budget.id,
      category_type: cat.categoryType,
      category_name: cat.categoryName,
      monthly_hours: cat.monthlyHours,
      is_excluded: cat.isExcluded || false,
    }));

    const { data: createdCategories, error: categoriesError } = await supabaseAdmin
      .from('category_budgets')
      .insert(categoryInserts)
      .select();

    if (categoriesError) {
      // Rollback: delete budget
      await supabaseAdmin.from('screen_time_budgets').delete().eq('id', budget.id);
      throw categoriesError;
    }

    return successResponse({
      ...budget,
      categories: createdCategories,
    }, 201);
  } catch (error: any) {
    console.error('Create budget error:', error);
    return errorResponse(error.message || 'Failed to create budget', 500);
  }
});

