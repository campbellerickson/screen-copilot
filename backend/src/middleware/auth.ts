import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { verifyToken, extractTokenFromHeader } from '../utils/auth';

const prisma = new PrismaClient();

/**
 * Authentication middleware
 * Verifies JWT token and attaches userId to request
 */
export async function authenticate(req: Request, res: Response, next: NextFunction) {
  try {
    const token = extractTokenFromHeader(req.headers.authorization);

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
      });
    }

    // Verify token
    const payload = verifyToken(token);

    // Attach userId to request for downstream use
    (req as any).userId = payload.userId;
    (req as any).userEmail = payload.email;

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token',
    });
  }
}

/**
 * Subscription verification middleware
 * Checks if user has active subscription or trial
 */
export async function requireSubscription(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = (req as any).userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
      });
    }

    // Get user's subscription
    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.status(403).json({
        success: false,
        error: 'Subscription required',
        requiresSubscription: true,
      });
    }

    const now = new Date();

    // Check trial status
    if (subscription.status === 'trial') {
      const trialEnded = subscription.trialEndDate && new Date(subscription.trialEndDate) < now;
      if (trialEnded) {
        return res.status(403).json({
          success: false,
          error: 'Trial expired. Please subscribe to continue.',
          requiresSubscription: true,
          trialExpired: true,
        });
      }
    }

    // Check active subscription
    else if (subscription.status === 'active') {
      const subscriptionExpired =
        subscription.subscriptionEndDate && new Date(subscription.subscriptionEndDate) < now;
      if (subscriptionExpired) {
        return res.status(403).json({
          success: false,
          error: 'Subscription expired. Please renew to continue.',
          requiresSubscription: true,
          subscriptionExpired: true,
        });
      }
    }

    // For any other status (cancelled, expired, etc.)
    else {
      return res.status(403).json({
        success: false,
        error: 'Active subscription required',
        requiresSubscription: true,
      });
    }

    // Attach subscription to request for downstream use
    (req as any).subscription = subscription;

    next();
  } catch (error) {
    console.error('Subscription verification error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to verify subscription',
    });
  }
}

/**
 * Optional authentication middleware
 * Attaches userId if token is present, but doesn't fail if missing
 */
export async function optionalAuth(req: Request, res: Response, next: NextFunction) {
  try {
    const token = extractTokenFromHeader(req.headers.authorization);

    if (token) {
      const payload = verifyToken(token);
      (req as any).userId = payload.userId;
      (req as any).userEmail = payload.email;
    }

    next();
  } catch (error) {
    // Token is invalid, but we don't fail the request
    next();
  }
}
