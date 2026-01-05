import { Router } from 'express';
import * as subscriptionController from '../controllers/subscriptionController';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * GET /api/v1/subscription/status
 * Get subscription status (requires authentication)
 */
router.get('/status', authenticate, subscriptionController.getSubscriptionStatus);

/**
 * POST /api/v1/subscription/validate-receipt
 * Validate iOS App Store receipt (requires authentication)
 */
router.post('/validate-receipt', authenticate, subscriptionController.validateIOSReceipt);

/**
 * POST /api/v1/subscription/create-checkout
 * Create Stripe checkout session for web (requires authentication)
 */
router.post('/create-checkout', authenticate, subscriptionController.createStripeCheckout);

/**
 * POST /api/v1/subscription/webhook
 * Stripe webhook handler (no authentication required)
 */
router.post('/webhook', subscriptionController.handleStripeWebhook);

/**
 * POST /api/v1/subscription/cancel
 * Cancel subscription (requires authentication)
 */
router.post('/cancel', authenticate, subscriptionController.cancelSubscription);

export default router;
