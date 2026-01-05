/**
 * API Integration Tests
 *
 * Tests all endpoints with real database operations
 */

import request from 'supertest';
import app from '../server';
import prisma from '../config/database';

// Test data
const testUserId = 'test-user-' + Date.now();
let testBudgetId: string;
let testCategoryId: string;

describe('Screen Time Budget API', () => {
  // Clean up before and after tests
  beforeAll(async () => {
    // Ensure test database is clean
    await prisma.budgetAlert.deleteMany({ where: { userId: testUserId } });
    await prisma.dailyAppUsage.deleteMany({ where: { userId: testUserId } });
    await prisma.userApp.deleteMany({ where: { userId: testUserId } });
    await prisma.screenTimeBudget.deleteMany({ where: { userId: testUserId } });
  });

  afterAll(async () => {
    // Clean up test data
    await prisma.budgetAlert.deleteMany({ where: { userId: testUserId } });
    await prisma.dailyAppUsage.deleteMany({ where: { userId: testUserId } });
    await prisma.userApp.deleteMany({ where: { userId: testUserId } });
    await prisma.screenTimeBudget.deleteMany({ where: { userId: testUserId } });
    await prisma.$disconnect();
  });

  // Health Check
  describe('GET /health', () => {
    it('should return 200 and status ok', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  // Budget Creation
  describe('POST /api/v1/screen-time/budgets', () => {
    it('should create a new budget', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/budgets')
        .send({
          userId: testUserId,
          monthYear: '2026-01-01',
          categories: [
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
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.userId).toBe(testUserId);
      expect(response.body.data.categories).toHaveLength(2);

      testBudgetId = response.body.data.id;
      testCategoryId = response.body.data.categories[0].id;
    });

    it('should fail with invalid data', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/budgets')
        .send({
          userId: '', // Invalid: empty userId
          monthYear: '2026-01-01',
          categories: [],
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body).toHaveProperty('error');
    });

    it('should fail with invalid date', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/budgets')
        .send({
          userId: testUserId,
          monthYear: 'invalid-date',
          categories: [
            {
              categoryType: 'social_media',
              categoryName: 'Social Media',
              monthlyHours: 30,
              isExcluded: false,
            },
          ],
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with hours out of range', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/budgets')
        .send({
          userId: testUserId,
          monthYear: '2026-01-01',
          categories: [
            {
              categoryType: 'social_media',
              categoryName: 'Social Media',
              monthlyHours: 1000, // Invalid: > 744 hours
              isExcluded: false,
            },
          ],
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  // Get Current Budget
  describe('GET /api/v1/screen-time/budgets/:userId/current', () => {
    it('should retrieve current month budget', async () => {
      const response = await request(app).get(
        `/api/v1/screen-time/budgets/${testUserId}/current`
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.userId).toBe(testUserId);
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app).get(
        '/api/v1/screen-time/budgets/nonexistent-user/current'
      );

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should fail with empty userId', async () => {
      const response = await request(app).get(
        '/api/v1/screen-time/budgets/ /current'
      );

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  // Update Category Budget
  describe('PUT /api/v1/screen-time/budgets/categories/:categoryId', () => {
    it('should update category budget', async () => {
      const response = await request(app)
        .put(`/api/v1/screen-time/budgets/categories/${testCategoryId}`)
        .send({
          monthlyHours: 25,
          isExcluded: false,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.monthlyHours).toBe('25');
    });

    it('should fail with invalid hours', async () => {
      const response = await request(app)
        .put(`/api/v1/screen-time/budgets/categories/${testCategoryId}`)
        .send({
          monthlyHours: -5, // Invalid: negative
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with no fields provided', async () => {
      const response = await request(app)
        .put(`/api/v1/screen-time/budgets/categories/${testCategoryId}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  // Sync Usage
  describe('POST /api/v1/screen-time/usage/sync', () => {
    it('should sync usage data', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/usage/sync')
        .send({
          userId: testUserId,
          usageDate: '2026-01-04',
          apps: [
            {
              bundleId: 'com.instagram.app',
              appName: 'Instagram',
              totalMinutes: 60,
            },
            {
              bundleId: 'com.netflix.app',
              appName: 'Netflix',
              totalMinutes: 90,
            },
          ],
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.synced).toBe(2);
      expect(response.body.data).toHaveProperty('budgetStatus');
    });

    it('should handle empty apps array', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/usage/sync')
        .send({
          userId: testUserId,
          usageDate: '2026-01-04',
          apps: [],
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.synced).toBe(0);
    });

    it('should fail with invalid date', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/usage/sync')
        .send({
          userId: testUserId,
          usageDate: 'invalid-date',
          apps: [],
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with minutes out of range', async () => {
      const response = await request(app)
        .post('/api/v1/screen-time/usage/sync')
        .send({
          userId: testUserId,
          usageDate: '2026-01-04',
          apps: [
            {
              bundleId: 'com.test.app',
              appName: 'Test',
              totalMinutes: 2000, // Invalid: > 1440 (24 hours)
            },
          ],
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  // Get Daily Usage
  describe('GET /api/v1/screen-time/usage/:userId/daily', () => {
    it('should get daily usage with date parameter', async () => {
      const response = await request(app).get(
        `/api/v1/screen-time/usage/${testUserId}/daily?date=2026-01-04`
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('date');
      expect(response.body.data).toHaveProperty('totalMinutes');
      expect(response.body.data).toHaveProperty('categories');
    });

    it('should get daily usage for today if no date provided', async () => {
      const response = await request(app).get(
        `/api/v1/screen-time/usage/${testUserId}/daily`
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  // Alerts
  describe('GET /api/v1/screen-time/alerts/:userId', () => {
    it('should get user alerts', async () => {
      const response = await request(app).get(
        `/api/v1/screen-time/alerts/${testUserId}`
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should respect limit parameter', async () => {
      const response = await request(app).get(
        `/api/v1/screen-time/alerts/${testUserId}?limit=5`
      );

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBeLessThanOrEqual(5);
    });
  });

  // 404 Handler
  describe('Non-existent routes', () => {
    it('should return 404 for undefined routes', async () => {
      const response = await request(app).get('/api/v1/nonexistent');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('not found');
    });
  });
});
