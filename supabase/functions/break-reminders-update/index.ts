// Update break reminder settings
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

    const { isEnabled, intervalMinutes, breakDurationMinutes, quietHoursStart, quietHoursEnd } = await req.json();

    const updateData: any = {};
    if (isEnabled !== undefined) updateData.is_enabled = isEnabled;
    if (intervalMinutes !== undefined) updateData.interval_minutes = intervalMinutes;
    if (breakDurationMinutes !== undefined) updateData.break_duration_minutes = breakDurationMinutes;
    if (quietHoursStart !== undefined) updateData.quiet_hours_start = quietHoursStart;
    if (quietHoursEnd !== undefined) updateData.quiet_hours_end = quietHoursEnd;

    const { data: reminder, error } = await supabaseAdmin
      .from('break_reminders')
      .upsert({
        user_id: user.id,
        is_enabled: isEnabled ?? true,
        interval_minutes: intervalMinutes ?? 60,
        break_duration_minutes: breakDurationMinutes ?? 5,
        quiet_hours_start: quietHoursStart ?? null,
        quiet_hours_end: quietHoursEnd ?? null,
        ...updateData,
      }, {
        onConflict: 'user_id',
      })
      .select()
      .single();

    if (error) {
      throw error;
    }

    return successResponse(reminder);
  } catch (error: any) {
    console.error('Update break reminder error:', error);
    return errorResponse(error.message || 'Failed to update break reminder settings', 500);
  }
});

