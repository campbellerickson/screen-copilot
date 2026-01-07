/**
 * Test Helpers and Utilities
 * 
 * Common utilities for API testing including authentication helpers,
 * test data generators, and database cleanup utilities.
 */

import request from 'supertest';
import app from '../server';
import prisma from '../config/database';
import { generateToken } from '../utils/auth';

/**
 * Generate a test JWT token for a user
 */
export function generateTestToken(userId: string, email: string = 'test@example.com'): string {
  return generateToken({ userId, email });
}

/**
 * Create a test user in the database
 */
export async function createTestUser(
  userId?: string,
  email: string = `test-${Date.now()}@example.com`,
  password: string = 'Test123!'
) {
  const finalUserId = userId || `test-user-${Date.now()}`;
  
  // Check if user already exists
  let user = await prisma.user.findUnique({
    where: { id: finalUserId },
  });

  if (!user) {
    user = await prisma.user.create({
      data: {
        id: finalUserId,
        email,
        password: password, // In real app, this would be hashed
        name: 'Test User',
      },
    });
  }

  return user;
}

/**
 * Create a test subscription for a user
 */
export async function createTestSubscription(
  userId: string,
  status: 'trial' | 'active' | 'cancelled' | 'expired' = 'active',
  trialDays: number = 7
) {
  const trialEndDate = new Date();
  trialEndDate.setDate(trialEndDate.getDate() + trialDays);

  const subscriptionEndDate = new Date();
  subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);

  return await prisma.subscription.upsert({
    where: { userId },
    create: {
      userId,
      status,
      platform: 'ios',
      trialStartDate: status === 'trial' ? new Date() : null,
      trialEndDate: status === 'trial' ? trialEndDate : null,
      subscriptionStartDate: status === 'active' ? new Date() : null,
      subscriptionEndDate: status === 'active' ? subscriptionEndDate : null,
    },
    update: {
      status,
      trialStartDate: status === 'trial' ? new Date() : null,
      trialEndDate: status === 'trial' ? trialEndDate : null,
      subscriptionStartDate: status === 'active' ? new Date() : null,
      subscriptionEndDate: status === 'active' ? subscriptionEndDate : null,
    },
  });
}

/**
 * Create a test budget for a user
 */
export async function createTestBudget(
  userId: string,
  monthYear: Date = new Date()
) {
  const budget = await prisma.screenTimeBudget.create({
    data: {
      userId,
      monthYear: new Date(monthYear.getFullYear(), monthYear.getMonth(), 1),
      isActive: true,
      categories: {
        create: [
          {
            categoryType: 'social_media',
            categoryName: 'Social Media',
            monthlyHours: 30,
            isExcluded: false,
          },
          {
            categoryType: 'entertainment',
            categoryName: 'Entertainment',
            monthlyHours: 40,
            isExcluded: false,
          },
        ],
      },
    },
    include: {
      categories: true,
    },
  });

  return budget;
}

/**
 * Clean up test data for a user
 */
export async function cleanupTestUser(userId: string) {
  await prisma.budgetAlert.deleteMany({ where: { userId } });
  await prisma.dailyAppUsage.deleteMany({ where: { userId } });
  await prisma.userApp.deleteMany({ where: { userId } });
  await prisma.categoryBudget.deleteMany({
    where: {
      budget: {
        userId,
      },
    },
  });
  await prisma.screenTimeBudget.deleteMany({ where: { userId } });
  await prisma.subscription.deleteMany({ where: { userId } });
  await prisma.user.deleteMany({ where: { id: userId } });
}

/**
 * Make an authenticated request
 */
export function authenticatedRequest(
  method: 'get' | 'post' | 'put' | 'delete' | 'patch',
  url: string,
  token: string
) {
  return request(app)[method](url).set('Authorization', `Bearer ${token}`);
}

/**
 * Generate test usage data
 */
export function generateTestUsageData(userId: string, date: Date = new Date()) {
  return {
    userId,
    usageDate: date.toISOString().split('T')[0],
    apps: [
      {
        bundleId: 'com.instagram.instagram',
        appName: 'Instagram',
        totalMinutes: 60,
      },
      {
        bundleId: 'com.netflix.Netflix',
        appName: 'Netflix',
        totalMinutes: 90,
      },
    ],
  };
}

/**
 * Wait for async operations to complete
 */
export function wait(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

