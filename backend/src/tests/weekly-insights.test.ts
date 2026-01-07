/**
 * Weekly Insights API Tests
 * 
 * Tests for weekly insights endpoint:
 * - GET /api/v1/weekly-insights
 */

import request from 'supertest';
import app from '../server';
import prisma from '../config/database';
import {
  createTestUser,
  createTestBudget,
  cleanupTestUser,
  generateTestToken,
  authenticatedRequest,
  generateTestUsageData,
} from './helpers';

describe('Weekly Insights API', () => {
  let testUserId: string;
  let authToken: string;

  beforeAll(async () => {
    const user = await createTestUser();
    testUserId = user.id;
    authToken = generateTestToken(user.id, user.email!);
    
    // Create a budget and some usage data for more realistic tests
    await createTestBudget(testUserId);
  });

  afterAll(async () => {
    if (testUserId) {
      await cleanupTestUser(testUserId);
    }
    await prisma.$disconnect();
  });

  describe('GET /api/v1/weekly-insights', () => {
    it('should get weekly insights', async () => {
      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-insights',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('weekStartDate');
      expect(response.body.data).toHaveProperty('weekEndDate');
    });

    it('should include usage statistics', async () => {
      // Sync some usage data first
      const usageData = generateTestUsageData(testUserId);
      await request(app)
        .post('/api/v1/screen-time/usage/sync')
        .send(usageData);

      const response = await authenticatedRequest(
        'get',
        '/api/v1/weekly-insights',
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      // Insights may include totalMinutes, categories, etc.
      expect(response.body.data).toBeDefined();
    });

    it('should accept weekStartDate query parameter', async () => {
      const weekStart = new Date();
      weekStart.setDate(weekStart.getDate() - 7);
      const weekStartStr = weekStart.toISOString().split('T')[0];

      const response = await authenticatedRequest(
        'get',
        `/api/v1/weekly-insights?weekStartDate=${weekStartStr}`,
        authToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should fail without authentication', async () => {
      const response = await request(app).get('/api/v1/weekly-insights');

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });
});

