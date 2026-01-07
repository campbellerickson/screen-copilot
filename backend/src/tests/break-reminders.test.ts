/**
 * Break Reminders API Tests
 * 
 * Tests for break reminder endpoints:
 * - GET /api/v1/break-reminders
 * - PUT /api/v1/break-reminders
 */

import request from 'supertest';
import app from '../server';
import prisma from '../config/database';
import {
  createTestUser,
  cleanupTestUser,
  generateTestToken,
  authenticatedRequest,
} from './helpers';

describe('Break Reminders API', () => {
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

  describe('GET /api/v1/break-reminders', () => {
    it('should get break reminder settings', async () => {
      const response = await authenticatedRequest(
        'get',
        '/api/v1/break-reminders',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('isEnabled');
    });

    it('should fail without authentication', async () => {
      const response = await request(app).get('/api/v1/break-reminders');

      expect(response.status).toBe(401);
    });
  });

  describe('PUT /api/v1/break-reminders', () => {
    it('should update break reminder settings', async () => {
      const response = await authenticatedRequest(
        'put',
        '/api/v1/break-reminders',
        authToken
      ).send({
        isEnabled: true,
        intervalMinutes: 60,
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('isEnabled', true);
      expect(response.body.data).toHaveProperty('intervalMinutes', 60);
    });

    it('should update with partial data', async () => {
      const response = await authenticatedRequest(
        'put',
        '/api/v1/break-reminders',
        authToken
      ).send({
        isEnabled: false,
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('isEnabled', false);
    });

    it('should fail with invalid interval', async () => {
      const response = await authenticatedRequest(
        'put',
        '/api/v1/break-reminders',
        authToken
      ).send({
        isEnabled: true,
        intervalMinutes: -10,
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .put('/api/v1/break-reminders')
        .send({
          isEnabled: true,
        });

      expect(response.status).toBe(401);
    });
  });
});

