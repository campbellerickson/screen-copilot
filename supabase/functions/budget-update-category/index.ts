// Update category budget
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
    const categoryId = url.pathname.split('/').pop();

    if (!categoryId) {
      return errorResponse('Category ID is required', 400);
    }

    const { monthlyHours, isExcluded } = await req.json();

    const updateData: any = {};
    if (monthlyHours !== undefined) {
      updateData.monthly_hours = monthlyHours;
    }
    if (isExcluded !== undefined) {
      updateData.is_excluded = isExcluded;
    }

    const { data: category, error } = await supabaseAdmin
      .from('category_budgets')
      .update(updateData)
      .eq('id', categoryId)
      .select()
      .single();

    if (error || !category) {
      return errorResponse('Category not found', 404);
    }

    return successResponse(category);
  } catch (error: any) {
    console.error('Update category error:', error);
    return errorResponse(error.message || 'Failed to update category', 500);
  }
});

