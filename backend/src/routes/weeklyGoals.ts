import { Router } from 'express';
import * as weeklyGoalController from '../controllers/weeklyGoalController';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * GET /api/v1/weekly-goals/current
 * Get current week's goal (requires authentication)
 */
router.get('/current', authenticate, weeklyGoalController.getCurrentWeekGoal);

/**
 * POST /api/v1/weekly-goals
 * Set weekly goal (requires authentication)
 */
router.post('/', authenticate, weeklyGoalController.setWeeklyGoal);

/**
 * GET /api/v1/weekly-goals/history
 * Get weekly goal history (requires authentication)
 */
router.get('/history', authenticate, weeklyGoalController.getGoalHistory);

export default router;

