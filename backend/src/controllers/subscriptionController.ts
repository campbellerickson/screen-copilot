import { Request, Response } from 'express';
import Stripe from 'stripe';
import prisma from '../config/database';
const stripe = process.env.STRIPE_SECRET_KEY
  ? new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2025-12-15.clover' })
  : null;

/**
 * Get subscription status
 * GET /api/v1/subscription/status
 */
export async function getSubscriptionStatus(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;

    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.status(200).json({
        success: true,
        data: {
          status: 'none',
          hasAccess: false,
          message: 'No subscription found. Start your 7-day free trial!',
        },
      });
    }

    const now = new Date();
    let hasAccess = false;
    let message = '';

    // Check trial
    if (subscription.status === 'trial') {
      const trialEnded = subscription.trialEndDate && new Date(subscription.trialEndDate) < now;
      hasAccess = !trialEnded;
      const daysRemaining = subscription.trialEndDate
        ? Math.ceil(
            (new Date(subscription.trialEndDate).getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          )
        : 0;
      message = trialEnded
        ? 'Trial expired. Subscribe for $0.99/mo to continue.'
        : `${daysRemaining} days remaining in your free trial`;
    }

    // Check active subscription
    else if (subscription.status === 'active') {
      const subscriptionExpired =
        subscription.subscriptionEndDate && new Date(subscription.subscriptionEndDate) < now;
      hasAccess = !subscriptionExpired;
      message = subscriptionExpired ? 'Subscription expired' : 'Active subscription';
    } else {
      message = 'Subscription required';
    }

    return res.status(200).json({
      success: true,
      data: {
        status: subscription.status,
        hasAccess,
        platform: subscription.platform,
        trialEndDate: subscription.trialEndDate,
        renewalDate: subscription.renewalDate,
        priceUSD: subscription.priceUSD,
        message,
      },
    });
  } catch (error) {
    console.error('Get subscription status error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get subscription status',
    });
  }
}

/**
 * Validate iOS App Store receipt
 * POST /api/v1/subscription/validate-receipt
 */
export async function validateIOSReceipt(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;
    const { receiptData, transactionId } = req.body;

    if (!receiptData) {
      return res.status(400).json({
        success: false,
        error: 'Receipt data is required',
      });
    }

    // TODO: Implement App Store receipt validation
    // This requires calling Apple's verifyReceipt API
    // For now, we'll create a placeholder that you'll need to implement

    /*
    const verifyReceiptUrl = process.env.NODE_ENV === 'production'
      ? 'https://buy.itunes.apple.com/verifyReceipt'
      : 'https://sandbox.itunes.apple.com/verifyReceipt';

    const response = await fetch(verifyReceiptUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET,
      }),
    });

    const receiptValidation = await response.json();
    */

    // For now, accept the receipt and update subscription
    const now = new Date();
    const renewalDate = new Date();
    renewalDate.setMonth(renewalDate.getMonth() + 1); // Monthly subscription

    const subscription = await prisma.subscription.upsert({
      where: { userId },
      create: {
        userId,
        status: 'active',
        platform: 'ios',
        subscriptionStartDate: now,
        renewalDate: renewalDate,
        appleTransactionId: transactionId,
        appleOriginalTransactionId: transactionId,
      },
      update: {
        status: 'active',
        subscriptionStartDate: now,
        renewalDate: renewalDate,
        appleTransactionId: transactionId,
      },
    });

    return res.status(200).json({
      success: true,
      data: {
        subscription: {
          status: subscription.status,
          renewalDate: subscription.renewalDate,
        },
      },
    });
  } catch (error) {
    console.error('Receipt validation error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to validate receipt',
    });
  }
}

/**
 * Create Stripe checkout session (for web subscriptions)
 * POST /api/v1/subscription/create-checkout
 */
export async function createStripeCheckout(req: Request, res: Response) {
  try {
    if (!stripe) {
      return res.status(500).json({
        success: false,
        error: 'Stripe is not configured',
      });
    }

    const userId = (req as any).userId;
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Create or retrieve Stripe customer
    let stripeCustomerId = (await prisma.subscription.findUnique({ where: { userId } }))
      ?.stripeCustomerId;

    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { userId },
      });
      stripeCustomerId = customer.id;
    }

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Screen Budget Pro',
              description: 'Monthly subscription to Screen Budget',
            },
            unit_amount: 99, // $0.99 in cents
            recurring: {
              interval: 'month',
            },
          },
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/subscription/success`,
      cancel_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/subscription/cancel`,
      subscription_data: {
        trial_period_days: 7,
        metadata: { userId },
      },
    });

    return res.status(200).json({
      success: true,
      data: {
        sessionId: session.id,
        url: session.url,
      },
    });
  } catch (error) {
    console.error('Create checkout error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to create checkout session',
    });
  }
}

/**
 * Stripe webhook handler
 * POST /api/v1/subscription/webhook
 */
export async function handleStripeWebhook(req: Request, res: Response) {
  try {
    if (!stripe) {
      return res.status(500).send('Stripe is not configured');
    }

    const sig = req.headers['stripe-signature'] as string;
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      console.error('Stripe webhook secret not configured');
      return res.status(500).send('Webhook secret not configured');
    }

    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      return res.status(400).send('Webhook signature verification failed');
    }

    // Handle the event
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.userId;

        if (userId) {
          const renewalDate = new Date(subscription.current_period_end * 1000);
          const endDate = new Date(subscription.current_period_end * 1000);

          await prisma.subscription.upsert({
            where: { userId },
            create: {
              userId,
              status: subscription.status === 'active' ? 'active' : subscription.status,
              platform: 'web',
              stripeCustomerId: subscription.customer as string,
              stripeSubscriptionId: subscription.id,
              subscriptionStartDate: new Date(subscription.current_period_start * 1000),
              subscriptionEndDate: endDate,
              renewalDate: renewalDate,
            },
            update: {
              status: subscription.status === 'active' ? 'active' : subscription.status,
              stripeSubscriptionId: subscription.id,
              subscriptionEndDate: endDate,
              renewalDate: renewalDate,
            },
          });
        }
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = subscription.metadata.userId;

        if (userId) {
          await prisma.subscription.update({
            where: { userId },
            data: { status: 'cancelled' },
          });
        }
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;
        const subscription = invoice.subscription as string;

        if (subscription) {
          const sub = await stripe.subscriptions.retrieve(subscription);
          const userId = sub.metadata.userId;

          if (userId) {
            await prisma.subscription.update({
              where: { userId },
              data: { status: 'expired' },
            });
          }
        }
        break;
      }
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({
      success: false,
      error: 'Webhook processing failed',
    });
  }
}

/**
 * Cancel subscription
 * POST /api/v1/subscription/cancel
 */
export async function cancelSubscription(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;

    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        error: 'No active subscription found',
      });
    }

    // Cancel Stripe subscription if it exists
    if (subscription.stripeSubscriptionId && stripe) {
      await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);
    }

    // Update subscription status
    await prisma.subscription.update({
      where: { userId },
      data: { status: 'cancelled' },
    });

    return res.status(200).json({
      success: true,
      message: 'Subscription cancelled successfully',
    });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to cancel subscription',
    });
  }
}
