// Get break reminder settings
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

    const { data: reminder, error } = await supabaseAdmin
      .from('break_reminders')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (error || !reminder) {
      // Create default
      const { data: newReminder, error: createError } = await supabaseAdmin
        .from('break_reminders')
        .insert({
          user_id: user.id,
          is_enabled: true,
          interval_minutes: 60,
          break_duration_minutes: 5,
        })
        .select()
        .single();

      if (createError || !newReminder) {
        throw createError;
      }

      return successResponse(newReminder);
    }

    return successResponse(reminder);
  } catch (error: any) {
    console.error('Get break reminder error:', error);
    return errorResponse(error.message || 'Failed to get break reminder settings', 500);
  }
});

