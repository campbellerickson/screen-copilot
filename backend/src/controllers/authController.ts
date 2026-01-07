import { Request, Response } from 'express';
import appleSigninAuth from 'apple-signin-auth';
import prisma from '../config/database';
import {
  hashPassword,
  comparePassword,
  generateToken,
  isValidEmail,
  isValidPassword,
} from '../utils/auth';

/**
 * Sign up with email and password
 * POST /api/v1/auth/signup
 */
export async function signup(req: Request, res: Response) {
  try {
    const { email, password, name } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required',
      });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format',
      });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        success: false,
        error: 'Password must be at least 8 characters and contain a number and letter',
      });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: 'User with this email already exists',
      });
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Create user
    const user = await prisma.user.create({
      data: {
        email: email.toLowerCase(),
        password: hashedPassword,
        name: name || null,
        lastLoginAt: new Date(),
      },
    });

    // Create 7-day trial subscription
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 7);

    await prisma.subscription.create({
      data: {
        userId: user.id,
        status: 'trial',
        platform: 'ios',
        trialStartDate: new Date(),
        trialEndDate: trialEndDate,
      },
    });

    // Generate JWT token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    return res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          createdAt: user.createdAt,
        },
        token,
        subscription: {
          status: 'trial',
          trialEndDate: trialEndDate,
        },
      },
    });
  } catch (error) {
    console.error('Signup error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to create account',
    });
  }
}

/**
 * Login with email and password
 * POST /api/v1/auth/login
 */
export async function login(req: Request, res: Response) {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required',
      });
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      include: {
        subscription: true,
      },
    });

    if (!user || !user.password) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password',
      });
    }

    // Verify password
    const isPasswordValid = await comparePassword(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password',
      });
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Generate JWT token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    // Check subscription status
    const subscriptionStatus = checkSubscriptionStatus(user.subscription);

    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          profileImage: user.profileImage,
        },
        token,
        subscription: subscriptionStatus,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to login',
    });
  }
}

/**
 * Sign in with Apple
 * POST /api/v1/auth/apple
 */
export async function handleAppleSignIn(req: Request, res: Response) {
  try {
    const { identityToken, user: appleUser } = req.body;

    if (!identityToken) {
      return res.status(400).json({
        success: false,
        error: 'Identity token is required',
      });
    }

    // Verify Apple identity token
    let appleResponse;
    try {
      appleResponse = await appleSigninAuth.verifyIdToken(identityToken, {
        audience: process.env.APPLE_BUNDLE_ID || 'com.campbell.ScreenTimeCopilot',
        ignoreExpiration: false,
      });
    } catch (error) {
      console.error('Apple token verification failed:', error);
      return res.status(401).json({
        success: false,
        error: 'Invalid Apple Sign In token',
      });
    }

    const appleId = appleResponse.sub;
    const email = appleResponse.email || `${appleId}@appleid.private`;

    // Check if user exists with this Apple ID
    let user = await prisma.user.findUnique({
      where: { appleId },
      include: { subscription: true },
    });

    // If not found by Apple ID, check by email
    if (!user && appleResponse.email) {
      user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() },
        include: { subscription: true },
      });

      // Link Apple ID to existing account
      if (user) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { appleId },
          include: { subscription: true },
        });
      }
    }

    // Create new user if doesn't exist
    if (!user) {
      user = await prisma.user.create({
        data: {
          email: email.toLowerCase(),
          appleId,
          name: appleUser?.name?.firstName
            ? `${appleUser.name.firstName} ${appleUser.name.lastName || ''}`.trim()
            : null,
          lastLoginAt: new Date(),
        },
        include: { subscription: true },
      });

      // Create 7-day trial subscription
      const trialEndDate = new Date();
      trialEndDate.setDate(trialEndDate.getDate() + 7);

      await prisma.subscription.create({
        data: {
          userId: user.id,
          status: 'trial',
          platform: 'ios',
          trialStartDate: new Date(),
          trialEndDate: trialEndDate,
        },
      });

      user.subscription = await prisma.subscription.findUnique({
        where: { userId: user.id },
      });
    } else {
      // Update last login
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
    }

    // Generate JWT token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    // Check subscription status
    const subscriptionStatus = checkSubscriptionStatus(user.subscription);

    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          profileImage: user.profileImage,
        },
        token,
        subscription: subscriptionStatus,
        isNewUser: !user.lastLoginAt,
      },
    });
  } catch (error) {
    console.error('Apple Sign In error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to sign in with Apple',
    });
  }
}

/**
 * Get current user profile
 * GET /api/v1/auth/me
 */
export async function getCurrentUser(req: Request, res: Response) {
  try {
    const userId = (req as any).userId; // Set by auth middleware

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { subscription: true },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    const subscriptionStatus = checkSubscriptionStatus(user.subscription);

    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          profileImage: user.profileImage,
          createdAt: user.createdAt,
        },
        subscription: subscriptionStatus,
      },
    });
  } catch (error) {
    console.error('Get current user error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get user profile',
    });
  }
}

/**
 * Delete user account
 * DELETE /api/v1/auth/account
 * This will:
 * 1. Cancel/delete subscription (if exists)
 * 2. Delete all user data (cascade delete)
 * 3. Return success
 */
export async function deleteAccount(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;

    // Get user with subscription
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { subscription: true },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Use transaction to ensure atomicity
    await prisma.$transaction(async (tx) => {
      // Cancel subscription if it exists
      if (user.subscription) {
        // Update subscription status to cancelled
        await tx.subscription.update({
          where: { userId },
          data: {
            status: 'cancelled',
            subscriptionEndDate: new Date(),
          },
        });

        // Note: For iOS subscriptions, Apple handles cancellation through App Store
        // For Stripe subscriptions, we would cancel here, but since we're deleting
        // the user, we just mark it as cancelled
      }

      // Delete user (cascade delete will handle all related data)
      await tx.user.delete({
        where: { id: userId },
      });
    });

    return res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    console.error('Delete account error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to delete account',
    });
  }
}

/**
 * Helper function to check subscription status
 */
function checkSubscriptionStatus(subscription: any) {
  if (!subscription) {
    return {
      status: 'none',
      hasAccess: false,
    };
  }

  const now = new Date();

  // Check trial status
  if (subscription.status === 'trial') {
    const trialEnded = subscription.trialEndDate && new Date(subscription.trialEndDate) < now;
    return {
      status: trialEnded ? 'trial_expired' : 'trial',
      hasAccess: !trialEnded,
      trialEndDate: subscription.trialEndDate,
      daysRemaining: trialEnded
        ? 0
        : Math.ceil(
            (new Date(subscription.trialEndDate).getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          ),
    };
  }

  // Check active subscription
  if (subscription.status === 'active') {
    const subscriptionExpired =
      subscription.subscriptionEndDate && new Date(subscription.subscriptionEndDate) < now;
    return {
      status: subscriptionExpired ? 'expired' : 'active',
      hasAccess: !subscriptionExpired,
      renewalDate: subscription.renewalDate,
    };
  }

  return {
    status: subscription.status,
    hasAccess: false,
  };
}
