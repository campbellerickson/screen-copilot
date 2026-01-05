import { Router } from 'express';
import * as breakReminderController from '../controllers/breakReminderController';
import { authenticate } from '../middleware/auth';

const router = Router();

/**
 * GET /api/v1/break-reminders
 * Get break reminder settings (requires authentication)
 */
router.get('/', authenticate, breakReminderController.getBreakReminder);

/**
 * PUT /api/v1/break-reminders
 * Update break reminder settings (requires authentication)
 */
router.put('/', authenticate, breakReminderController.updateBreakReminder);

export default router;

