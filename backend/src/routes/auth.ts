import { Router } from 'express';
import * as authController from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * POST /api/v1/auth/signup
 * Sign up with email and password
 */
router.post('/signup', authController.signup);

/**
 * POST /api/v1/auth/login
 * Login with email and password
 */
router.post('/login', authController.login);

/**
 * POST /api/v1/auth/apple
 * Sign in with Apple
 */
router.post('/apple', authController.handleAppleSignIn);

/**
 * GET /api/v1/auth/me
 * Get current user profile (requires authentication)
 */
router.get('/me', authenticate, authController.getCurrentUser);

/**
 * DELETE /api/v1/auth/account
 * Delete user account (requires authentication)
 * This will cancel subscription and delete all user data
 */
router.delete('/account', authenticate, authController.deleteAccount);

export default router;
