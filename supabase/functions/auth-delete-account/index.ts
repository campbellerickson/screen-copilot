// Delete user account
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { getAuthUser } from '../_shared/auth.ts';
import { supabaseAdmin } from '../_shared/database.ts';

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthUser(req);
    if (!user) {
      return errorResponse('Authentication required', 401);
    }

    // Get subscription
    const { data: subscription } = await supabaseAdmin
      .from('subscriptions')
      .select('*')
      .eq('user_id', user.id)
      .single();

    // Cancel subscription if exists
    // For iOS subscriptions, cancellation is handled through App Store
    // We just mark it as cancelled in our database
    if (subscription) {
      await supabaseAdmin
        .from('subscriptions')
        .update({
          status: 'cancelled',
          subscription_end_date: new Date().toISOString(),
        })
        .eq('user_id', user.id);
    }

    // Delete user (cascade delete will handle all related data)
    await supabaseAdmin.from('users').delete().eq('id', user.id);

    // Delete auth user
    await supabaseAdmin.auth.admin.deleteUser(user.id);

    return successResponse({ message: 'Account deleted successfully' });
  } catch (error: any) {
    console.error('Delete account error:', error);
    return errorResponse(error.message || 'Failed to delete account', 500);
  }
});

