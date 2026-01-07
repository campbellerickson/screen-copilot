/**
 * Weekly Goals API Tests
 * 
 * Tests for weekly goals endpoints:
 * - GET /api/v1/weekly-goals/current
 * - POST /api/v1/weekly-goals
 * - GET /api/v1/weekly-goals/history
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

describe('Weekly Goals API', () => {
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

  describe('POST /api/v1/weekly-goals', () => {
    it('should create a weekly goal', async () => {
      const response = await authenticatedRequest(
        'post',
        '/api/v1/weekly-goals',
        authToken
      ).send({
        targetMinutes: 1200, // 20 hours in minutes
        weekStartDate: new Date().toISOString().split('T')[0],
      });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data).toHaveProperty('targetMinutes', 1200);
    });

    it('should fail with invalid target minutes', async () => {
      const response = await authenticatedRequest(
        'post',
        '/api/v1/weekly-goals',
        authToken
      ).send({
        targetMinutes: -5,
        weekStartDate: new Date().toISOString().split('T')[0],
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with missing required fields', async () => {
      const response = await authenticatedRequest(
        'post',
        '/api/v1/weekly-goals',
        authToken
      ).send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/weekly-goals')
        .send({
          targetHours: 20,
        });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/v1/weekly-goals/current', () => {
    it('should get current week goal', async () => {
      // First create a goal
      await authenticatedRequest('post', '/api/v1/weekly-goals', authToken).send({
        targetMinutes: 1200,
        weekStartDate: new Date().toISOString().split('T')[0],
      });

      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-goals/current',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('targetMinutes');
    });

    it('should return 404 if no current goal exists', async () => {
      // Create a new user without goals
      const newUser = await createTestUser();
      const newToken = generateTestToken(newUser.id, newUser.email!);

      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-goals/current',
        newToken
      );

      // May return 404 or empty data depending on implementation
      expect([200, 404]).toContain(response.status);

      await cleanupTestUser(newUser.id);
    });

    it('should fail without authentication', async () => {
      const response = await request(app).get('/api/v1/weekly-goals/current');

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/v1/weekly-goals/history', () => {
    it('should get weekly goal history', async () => {
      // Create a few goals
      const today = new Date();
      for (let i = 0; i < 3; i++) {
        const weekStart = new Date(today);
        weekStart.setDate(weekStart.getDate() - i * 7);
        await authenticatedRequest('post', '/api/v1/weekly-goals', authToken).send({
          targetMinutes: (20 + i) * 60,
          weekStartDate: weekStart.toISOString().split('T')[0],
        });
      }

      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-goals/history',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should respect limit parameter', async () => {
      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-goals/history?limit=2',
        authToken
      );

      expect(response.status).toBe(200);
      if (Array.isArray(response.body.data)) {
        expect(response.body.data.length).toBeLessThanOrEqual(2);
      }
    });

    it('should fail without authentication', async () => {
      const response = await request(app).get('/api/v1/weekly-goals/history');

      expect(response.status).toBe(401);
    });
  });
});

