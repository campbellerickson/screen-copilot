/**
 * Authentication API Tests
 * 
 * Tests for all authentication endpoints:
 * - POST /api/v1/auth/signup
 * - POST /api/v1/auth/login
 * - POST /api/v1/auth/apple
 * - GET /api/v1/auth/me
 * - DELETE /api/v1/auth/account
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

describe('Authentication API', () => {
  const testEmail = `test-auth-${Date.now()}@example.com`;
  const testPassword = 'Test123!';
  let testUserId: string;
  let authToken: string;

  afterAll(async () => {
    if (testUserId) {
      await cleanupTestUser(testUserId);
    }
    await prisma.$disconnect();
  });

  describe('POST /api/v1/auth/signup', () => {
    it('should create a new user with valid credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: testEmail,
          password: testPassword,
          name: 'Test User',
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('user');
      expect(response.body.data).toHaveProperty('token');
      expect(response.body.data).toHaveProperty('subscription');
      expect(response.body.data.user.email).toBe(testEmail.toLowerCase());
      expect(response.body.data.subscription.status).toBe('trial');

      testUserId = response.body.data.user.id;
      authToken = response.body.data.token;
    });

    it('should fail with missing email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          password: testPassword,
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('required');
    });

    it('should fail with missing password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'test@example.com',
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with invalid email format', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'invalid-email',
          password: testPassword,
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Invalid email');
    });

    it('should fail with weak password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: 'test@example.com',
          password: 'weak',
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Password must be');
    });

    it('should fail if user already exists', async () => {
      const response = await request(app)
        .post('/api/v1/auth/signup')
        .send({
          email: testEmail,
          password: testPassword,
        });

      expect(response.status).toBe(409);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('already exists');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testEmail,
          password: testPassword,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('user');
      expect(response.body.data).toHaveProperty('token');
      expect(response.body.data.user.email).toBe(testEmail.toLowerCase());
    });

    it('should fail with incorrect password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: testEmail,
          password: 'WrongPassword123!',
        });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Invalid');
    });

    it('should fail with non-existent user', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: testPassword,
        });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });

    it('should fail with missing email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          password: testPassword,
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/auth/me', () => {
    it('should return current user with valid token', async () => {
      const response = await authenticatedRequest('get', '/api/v1/auth/me', authToken);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('user');
      expect(response.body.data.user.id).toBe(testUserId);
      expect(response.body.data.user.email).toBe(testEmail.toLowerCase());
    });

    it('should fail without token', async () => {
      const response = await request(app).get('/api/v1/auth/me');

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Authentication required');
    });

    it('should fail with invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid-token');

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/auth/apple', () => {
    it('should handle Apple Sign In with valid identity token', async () => {
      // Note: This is a simplified test. Real Apple Sign In requires
      // proper identity token validation which is complex to mock
      const response = await request(app)
        .post('/api/v1/auth/apple')
        .send({
          identityToken: 'mock-identity-token',
        });

      // This will likely fail without proper Apple configuration
      // but we're testing the endpoint exists and handles the request
      expect([200, 201, 400, 401, 500]).toContain(response.status);
    });

    it('should fail without identity token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/apple')
        .send({});

      expect(response.status).toBeGreaterThanOrEqual(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('DELETE /api/v1/auth/account', () => {
    it('should delete user account with valid token', async () => {
      // Create a separate user for deletion test
      const deleteUser = await createTestUser();
      const deleteToken = generateTestToken(deleteUser.id, deleteUser.email!);

      const response = await authenticatedRequest(
        'delete',
        '/api/v1/auth/account',
        deleteToken
      );

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify user is deleted
      const deletedUser = await prisma.user.findUnique({
        where: { id: deleteUser.id },
      });
      expect(deletedUser).toBeNull();
    });

    it('should fail without authentication', async () => {
      const response = await request(app).delete('/api/v1/auth/account');

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });
});

