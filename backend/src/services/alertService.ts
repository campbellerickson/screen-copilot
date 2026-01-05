import prisma from '../config/database';
import { AlertDTO } from '../types';
import { BudgetService } from './budgetService';

export class AlertService {
  private budgetService = new BudgetService();

  /**
   * Check budget status and trigger alerts if needed
   * OPTIMIZED: Batch query for existing alerts to avoid N+1 problem
   */
  async checkAndTriggerAlerts(
    userId: string,
    date: Date,
    categoryUsage: { [key: string]: number }
  ): Promise<AlertDTO[]> {
    const alerts: AlertDTO[] = [];

    // Get current budget
    const budget = await this.budgetService.getCurrentBudget(userId);
    if (!budget) return alerts;

    // Filter categories that are over budget
    const overBudgetCategories = budget.categories.filter((categoryBudget) => {
      if (categoryBudget.isExcluded) return false;

      const usedToday = categoryUsage[categoryBudget.categoryType] || 0;
      const dailyBudget = this.budgetService.calculateDailyBudget(
        Number(categoryBudget.monthlyHours),
        budget.monthYear
      );

      return usedToday > dailyBudget;
    });

    if (overBudgetCategories.length === 0) return alerts;

    // Batch query for existing alerts (OPTIMIZATION: single query instead of N queries)
    const existingAlerts = await prisma.budgetAlert.findMany({
      where: {
        userId,
        alertDate: date,
        categoryType: {
          in: overBudgetCategories.map((cat) => cat.categoryType),
        },
      },
      select: {
        categoryType: true,
      },
    });

    const existingCategoryTypes = new Set(existingAlerts.map((alert) => alert.categoryType));

    // Prepare bulk insert data
    const alertsToCreate: Array<{
      userId: string;
      categoryType: string;
      alertDate: Date;
      overageMinutes: number;
    }> = [];

    for (const categoryBudget of overBudgetCategories) {
      // Skip if alert already exists for this category
      if (existingCategoryTypes.has(categoryBudget.categoryType)) continue;

      const usedToday = categoryUsage[categoryBudget.categoryType] || 0;
      const dailyBudget = this.budgetService.calculateDailyBudget(
        Number(categoryBudget.monthlyHours),
        budget.monthYear
      );
      const overageMinutes = usedToday - dailyBudget;

      alertsToCreate.push({
        userId,
        categoryType: categoryBudget.categoryType,
        alertDate: date,
        overageMinutes,
      });

      alerts.push({
        category: categoryBudget.categoryName,
        overageMinutes,
      });
    }

    // Bulk create alerts (OPTIMIZATION: single insert instead of multiple)
    if (alertsToCreate.length > 0) {
      await prisma.budgetAlert.createMany({
        data: alertsToCreate,
        skipDuplicates: true,
      });
    }

    return alerts;
  }

  /**
   * Get user's alerts
   */
  async getUserAlerts(userId: string, limit: number = 10) {
    return await prisma.budgetAlert.findMany({
      where: { userId },
      orderBy: { alertSentAt: 'desc' },
      take: limit,
    });
  }

  /**
   * Dismiss an alert
   */
  async dismissAlert(alertId: string) {
    return await prisma.budgetAlert.update({
      where: { id: alertId },
      data: {
        wasDismissed: true,
        dismissedAt: new Date(),
      },
    });
  }
}
