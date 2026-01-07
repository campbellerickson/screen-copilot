// Validate iOS App Store receipt
import { handleCors } from '../_shared/cors.ts';
import { successResponse, errorResponse } from '../_shared/response.ts';
import { getAuthUser, checkSubscription } from '../_shared/auth.ts';
import { supabaseAdmin } from '../_shared/database.ts';

const APPLE_SHARED_SECRET = Deno.env.get('APPLE_SHARED_SECRET');
const APPLE_VERIFY_RECEIPT_URL_PRODUCTION = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_VERIFY_RECEIPT_URL_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthUser(req);
    if (!user) {
      return errorResponse('Authentication required', 401);
    }

    const { receiptData, transactionId } = await req.json();

    if (!receiptData) {
      return errorResponse('Receipt data is required', 400);
    }

    // Verify receipt with Apple
    let receiptValidation: any;
    
    if (APPLE_SHARED_SECRET) {
      // Try production first
      let response = await fetch(APPLE_VERIFY_RECEIPT_URL_PRODUCTION, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          'receipt-data': receiptData,
          'password': APPLE_SHARED_SECRET,
          'exclude-old-transactions': true,
        }),
      });

      receiptValidation = await response.json();

      // If production returns 21007 (sandbox receipt), try sandbox
      if (receiptValidation.status === 21007) {
        response = await fetch(APPLE_VERIFY_RECEIPT_URL_SANDBOX, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            'receipt-data': receiptData,
            'password': APPLE_SHARED_SECRET,
            'exclude-old-transactions': true,
          }),
        });
        receiptValidation = await response.json();
      }

      // Check if receipt is valid
      if (receiptValidation.status !== 0) {
        return errorResponse(`Invalid receipt: ${receiptValidation.status}`, 400);
      }
    } else {
      // If no shared secret configured, accept receipt (for development)
      console.warn('APPLE_SHARED_SECRET not configured - accepting receipt without validation');
      receiptValidation = { status: 0 };
    }

    // Extract subscription info from receipt
    const latestReceiptInfo = receiptValidation.latest_receipt_info?.[0] || receiptValidation.receipt?.in_app?.[0];
    
    if (!latestReceiptInfo && !transactionId) {
      return errorResponse('No subscription found in receipt', 400);
    }

    const now = new Date();
    let renewalDate = new Date();
    renewalDate.setMonth(renewalDate.getMonth() + 1); // Default: monthly subscription

    // If we have receipt info, use actual dates
    if (latestReceiptInfo?.expires_date_ms) {
      renewalDate = new Date(parseInt(latestReceiptInfo.expires_date_ms));
    }

    // Update subscription in database
    const { data: subscription, error: subError } = await supabaseAdmin
      .from('subscriptions')
      .upsert({
        user_id: user.id,
        status: 'active',
        platform: 'ios',
        subscription_start_date: now.toISOString(),
        renewal_date: renewalDate.toISOString(),
        subscription_end_date: renewalDate.toISOString(),
        ios_transaction_id: transactionId || latestReceiptInfo?.transaction_id,
        ios_receipt_data: receiptData,
      }, {
        onConflict: 'user_id',
      })
      .select()
      .single();

    if (subError) {
      throw subError;
    }

    return successResponse({
      subscription: {
        status: subscription.status,
        renewalDate: subscription.renewal_date,
      },
    });
  } catch (error: any) {
    console.error('Receipt validation error:', error);
    return errorResponse(error.message || 'Failed to validate receipt', 500);
  }
});

