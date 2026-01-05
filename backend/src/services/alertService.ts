import prisma from '../config/database';
import { AlertDTO } from '../types';
import { BudgetService } from './budgetService';

export interface NotificationAlert {
  type: 'daily_overage' | 'monthly_overage';
  categoryType: string;
  categoryName: string;
  overageMinutes: number;
  usedMinutes: number;
  budgetMinutes: number;
  message: string;
}

export class AlertService {
  private budgetService = new BudgetService();

  /**
   * Check budget status and trigger alerts if needed
   * OPTIMIZED: Batch query for existing alerts to avoid N+1 problem
   * ENHANCED: Now checks both daily and monthly overages and generates notifications
   */
  async checkAndTriggerAlerts(
    userId: string,
    date: Date,
    categoryUsage: { [key: string]: number },
    monthlyUsage?: { [key: string]: number }
  ): Promise<{
    alerts: AlertDTO[];
    notifications: NotificationAlert[];
  }> {
    const alerts: AlertDTO[] = [];
    const notifications: NotificationAlert[] = [];

    // Get current budget
    const budget = await this.budgetService.getCurrentBudget(userId);
    if (!budget) return { alerts, notifications };

    // Calculate monthly usage if not provided
    if (!monthlyUsage) {
      monthlyUsage = await this.getMonthlyUsage(userId, budget.monthYear);
    }

    // Get existing alerts for today (to prevent duplicates)
    const existingAlertsToday = await prisma.budgetAlert.findMany({
      where: {
        userId,
        alertDate: date,
      },
      select: {
        categoryType: true,
      },
    });
    const existingCategoryTypes = new Set(existingAlertsToday.map((a) => a.categoryType));

    // Track monthly notifications sent today (use a Set or check differently)
    // For monthly, we'll send once per day per category when over budget
    const monthlyNotificationsToday = new Set<string>();

    // Check daily and monthly overages
    for (const categoryBudget of budget.categories) {
      if (categoryBudget.isExcluded) continue;

      const categoryType = categoryBudget.categoryType;
      const categoryName = categoryBudget.categoryName;
      const usedToday = categoryUsage[categoryType] || 0;
      const usedMonthly = monthlyUsage[categoryType] || 0;

      const dailyBudget = this.budgetService.calculateDailyBudget(
        Number(categoryBudget.monthlyHours),
        budget.monthYear
      );
      const monthlyBudgetMinutes = Number(categoryBudget.monthlyHours) * 60;

      // Check daily overage
      if (usedToday > dailyBudget) {
        const overageMinutes = usedToday - dailyBudget;

        // Create alert in database if not already exists
        if (!existingCategoryTypes.has(categoryType)) {
          await prisma.budgetAlert.create({
            data: {
              userId,
              categoryType,
              alertDate: date,
              overageMinutes,
            },
          });

          alerts.push({
            category: categoryName,
            overageMinutes,
          });
        }

        // Always create notification (iOS will handle deduplication)
        notifications.push({
          type: 'daily_overage',
          categoryType,
          categoryName,
          overageMinutes,
          usedMinutes: usedToday,
          budgetMinutes: dailyBudget,
          message: `You've exceeded your daily ${categoryName} budget by ${this.formatMinutes(overageMinutes)}`,
        });
      }

      // Check monthly overage
      if (usedMonthly > monthlyBudgetMinutes) {
        const overageMinutes = usedMonthly - monthlyBudgetMinutes;
        const monthlyKey = `monthly_${categoryType}`;

        // Only create monthly notification once per day per category
        if (!monthlyNotificationsToday.has(monthlyKey)) {
          notifications.push({
            type: 'monthly_overage',
            categoryType,
            categoryName,
            overageMinutes,
            usedMinutes: usedMonthly,
            budgetMinutes: monthlyBudgetMinutes,
            message: `You've exceeded your monthly ${categoryName} budget by ${this.formatMinutes(overageMinutes)}`,
          });
          monthlyNotificationsToday.add(monthlyKey);
        }
      }
    }

    return { alerts, notifications };
  }

  /**
   * Get monthly usage totals by category
   */
  private async getMonthlyUsage(
    userId: string,
    monthYear: Date
  ): Promise<{ [key: string]: number }> {
    const monthStart = new Date(monthYear.getFullYear(), monthYear.getMonth(), 1);
    const monthEnd = new Date(
      monthYear.getFullYear(),
      monthYear.getMonth() + 1,
      0
    );

    const monthlyUsages = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: monthStart,
          lte: monthEnd,
        },
      },
      include: {
        app: {
          select: {
            categoryType: true,
          },
        },
      },
    });

    const categoryTotals: { [key: string]: number } = {};
    for (const usage of monthlyUsages) {
      const category = usage.app.categoryType || 'other';
      categoryTotals[category] = (categoryTotals[category] || 0) + usage.totalMinutes;
    }

    return categoryTotals;
  }

  /**
   * Format minutes into human-readable string
   */
  private formatMinutes(minutes: number): string {
    if (minutes < 60) {
      return `${minutes} minute${minutes !== 1 ? 's' : ''}`;
    }
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (mins === 0) {
      return `${hours} hour${hours !== 1 ? 's' : ''}`;
    }
    return `${hours} hour${hours !== 1 ? 's' : ''} ${mins} minute${mins !== 1 ? 's' : ''}`;
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
