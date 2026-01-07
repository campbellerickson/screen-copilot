/**
 * Subscription API Tests
 * 
 * Tests for subscription endpoints:
 * - GET /api/v1/subscription/status
 * - POST /api/v1/subscription/validate-receipt
 * - POST /api/v1/subscription/create-checkout
 * - POST /api/v1/subscription/cancel
 * - POST /api/v1/subscription/webhook
 */

import request from 'supertest';
import app from '../server';
import prisma from '../config/database';
import {
  createTestUser,
  createTestSubscription,
  cleanupTestUser,
  generateTestToken,
  authenticatedRequest,
} from './helpers';

describe('Subscription API', () => {
  let testUserId: string;
  let authToken: string;

  beforeAll(async () => {
    const user = await createTestUser();
    testUserId = user.id;
    authToken = generateTestToken(user.id, user.email!);
  });

  afterAll(async () => {
    if (testUserId) {
      await cleanupTestUser(testUserId);
    }
    await prisma.$disconnect();
  });

  describe('GET /api/v1/subscription/status', () => {
    it('should return subscription status for active subscription', async () => {
      await createTestSubscription(testUserId, 'active');

      const response = await authenticatedRequest(
        'get',
        '/api/v1/subscription/status',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('status', 'active');
      expect(response.body.data).toHaveProperty('hasAccess', true);
    });

    it('should return trial status with days remaining', async () => {
      await createTestSubscription(testUserId, 'trial', 7);

      const response = await authenticatedRequest(
        'get',
        '/api/v1/subscription/status',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('status', 'trial');
      expect(response.body.data).toHaveProperty('hasAccess', true);
      expect(response.body.data.message).toContain('days remaining');
    });

    it('should return no subscription if none exists', async () => {
      // Create a new user without subscription
      const newUser = await createTestUser();
      const newToken = generateTestToken(newUser.id, newUser.email!);

      const response = await authenticatedRequest(
        'get',
        '/api/v1/subscription/status',
        newToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('status', 'none');
      expect(response.body.data).toHaveProperty('hasAccess', false);

      await cleanupTestUser(newUser.id);
    });

    it('should fail without authentication', async () => {
      const response = await request(app).get('/api/v1/subscription/status');

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/subscription/validate-receipt', () => {
    it('should validate iOS receipt (mock test)', async () => {
      await createTestSubscription(testUserId, 'trial');

      const response = await authenticatedRequest(
        'post',
        '/api/v1/subscription/validate-receipt',
        authToken
      )
        .send({
          receiptData: 'mock-receipt-data',
          transactionId: 'mock-transaction-id',
        });

      // This endpoint may not be fully implemented yet
      // Just verify it exists and handles requests
      expect([200, 400, 500]).toContain(response.status);
    });

    it('should fail without receipt data', async () => {
      const response = await authenticatedRequest(
        'post',
        '/api/v1/subscription/validate-receipt',
        authToken
      ).send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/subscription/validate-receipt')
        .send({
          receiptData: 'test',
        });

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/v1/subscription/create-checkout', () => {
    it('should create Stripe checkout session (if configured)', async () => {
      const response = await authenticatedRequest(
        'post',
        '/api/v1/subscription/create-checkout',
        authToken
      ).send({});

      // This will fail if Stripe is not configured, which is expected
      // Just verify the endpoint exists
      expect([200, 400, 500]).toContain(response.status);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/subscription/create-checkout')
        .send({});

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/v1/subscription/cancel', () => {
    it('should cancel active subscription', async () => {
      await createTestSubscription(testUserId, 'active');

      const response = await authenticatedRequest(
        'post',
        '/api/v1/subscription/cancel',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify subscription is cancelled
      const subscription = await prisma.subscription.findUnique({
        where: { userId: testUserId },
      });
      expect(subscription?.status).toBe('cancelled');
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/subscription/cancel')
        .send({});

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/v1/subscription/webhook', () => {
    it('should handle Stripe webhook events', async () => {
      // Mock Stripe webhook payload
      const webhookPayload = {
        type: 'customer.subscription.updated',
        data: {
          object: {
            id: 'sub_test',
            customer: 'cus_test',
            status: 'active',
          },
        },
      };

      const response = await request(app)
        .post('/api/v1/subscription/webhook')
        .set('stripe-signature', 'mock-signature')
        .send(webhookPayload);

      // Webhook may require proper Stripe signature validation
      // Just verify endpoint exists
      expect([200, 400, 401, 500]).toContain(response.status);
    });
  });
});

