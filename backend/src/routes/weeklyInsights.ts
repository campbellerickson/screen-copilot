import { Router } from 'express';
import * as weeklyInsightsController from '../controllers/weeklyInsightsController';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * GET /api/v1/weekly-insights
 * Get weekly insights/summary (requires authentication)
 */
router.get('/', authenticate, weeklyInsightsController.getWeeklyInsights);

export default router;

