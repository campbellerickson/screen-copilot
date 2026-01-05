import { Router } from 'express';
import * as budgetController from '../controllers/budgetController';
import * as usageController from '../controllers/usageController';
import {
  validateCreateBudget,
  validateSyncUsage,
  validateUserId,
  validateUpdateCategoryBudget,
} from '../middleware/validation';
import { authenticate, requireSubscription } from '../middleware/auth';

const router = Router();

// All routes require authentication and active subscription
router.use(authenticate);
router.use(requireSubscription);

// Budget routes
router.post('/budgets', validateCreateBudget, budgetController.createBudget);
router.get('/budgets/:userId/current', validateUserId, budgetController.getCurrentBudget);
router.put('/budgets/categories/:categoryId', validateUpdateCategoryBudget, budgetController.updateCategoryBudget);

// Usage routes
router.post('/usage/sync', validateSyncUsage, usageController.syncUsage);
router.get('/usage/:userId/daily', validateUserId, usageController.getDailyUsage);

// Alert routes
router.get('/alerts/:userId', validateUserId, usageController.getUserAlerts);
router.post('/alerts/:alertId/dismiss', usageController.dismissAlert);

export default router;
