import prisma from '../config/database';
import { AlertDTO } from '../types';
import { BudgetService } from './budgetService';

export class AlertService {
  private budgetService = new BudgetService();

  /**
   * Check budget status and trigger alerts if needed
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

    for (const categoryBudget of budget.categories) {
      if (categoryBudget.isExcluded) continue;

      const usedToday = categoryUsage[categoryBudget.categoryType] || 0;
      const dailyBudget = this.budgetService.calculateDailyBudget(
        Number(categoryBudget.monthlyHours),
        budget.monthYear
      );

      // Check if over budget
      if (usedToday > dailyBudget) {
        const overageMinutes = usedToday - dailyBudget;

        // Check if we've already sent an alert today
        const existingAlert = await prisma.budgetAlert.findFirst({
          where: {
            userId,
            categoryType: categoryBudget.categoryType,
            alertDate: date,
          },
        });

        if (!existingAlert) {
          // Create alert record
          await prisma.budgetAlert.create({
            data: {
              userId,
              categoryType: categoryBudget.categoryType,
              alertDate: date,
              overageMinutes,
            },
          });

          // Add to alerts to return
          alerts.push({
            category: categoryBudget.categoryName,
            overageMinutes,
          });
        }
      }
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
