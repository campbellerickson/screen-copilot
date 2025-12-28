import { Router } from 'express';
import * as budgetController from '../controllers/budgetController';
import * as usageController from '../controllers/usageController';

const router = Router();

// Budget routes
router.post('/budgets', budgetController.createBudget);
router.get('/budgets/:userId/current', budgetController.getCurrentBudget);
router.put('/budgets/categories/:categoryId', budgetController.updateCategoryBudget);

// Usage routes
router.post('/usage/sync', usageController.syncUsage);
router.get('/usage/:userId/daily', usageController.getDailyUsage);

// Alert routes
router.get('/alerts/:userId', usageController.getUserAlerts);
router.post('/alerts/:alertId/dismiss', usageController.dismissAlert);

export default router;
