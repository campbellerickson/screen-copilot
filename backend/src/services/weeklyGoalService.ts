import prisma from '../config/database';

export class WeeklyGoalService {
  /**
   * Get or create current week's goal
   */
  async getCurrentWeekGoal(userId: string) {
    const weekStart = this.getWeekStartDate(new Date());

    let goal = await prisma.weeklyGoal.findUnique({
      where: {
        userId_weekStartDate: {
          userId,
          weekStartDate: weekStart,
        },
      },
    });

    // Create default goal if doesn't exist
    if (!goal) {
      // Get user's average daily usage for the past week
      const averageMinutes = await this.getAverageWeeklyUsage(userId);
      // Default goal: reduce by 20% from average
      const targetMinutes = Math.round(averageMinutes * 0.8);

      goal = await prisma.weeklyGoal.create({
        data: {
          userId,
          weekStartDate: weekStart,
          targetMinutes,
          currentMinutes: 0,
          daysCompleted: 0,
          isActive: true,
        },
      });
    }

    return goal;
  }

  /**
   * Create or update weekly goal
   */
  async setWeeklyGoal(
    userId: string,
    targetMinutes: number,
    weekStartDate?: Date
  ) {
    const weekStart = weekStartDate
      ? this.getWeekStartDate(weekStartDate)
      : this.getWeekStartDate(new Date());

    return await prisma.weeklyGoal.upsert({
      where: {
        userId_weekStartDate: {
          userId,
          weekStartDate: weekStart,
        },
      },
      create: {
        userId,
        weekStartDate: weekStart,
        targetMinutes,
        currentMinutes: 0,
        daysCompleted: 0,
        isActive: true,
      },
      update: {
        targetMinutes,
        isActive: true,
      },
    });
  }

  /**
   * Update weekly goal progress
   * Called when daily usage syncs
   */
  async updateProgress(userId: string, date: Date, dailyMinutes: number) {
    const weekStart = this.getWeekStartDate(date);

    const goal = await prisma.weeklyGoal.findUnique({
      where: {
        userId_weekStartDate: {
          userId,
          weekStartDate: weekStart,
        },
      },
    });

    if (!goal || !goal.isActive) return null;

    // Get current week's total usage
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);

    const weekUsage = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: weekStart,
          lte: weekEnd,
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

    // Calculate total minutes for the week
    const totalMinutes = weekUsage.reduce(
      (sum, usage) => sum + usage.totalMinutes,
      0
    );

    // Count days that met the daily goal (under daily target)
    const dailyTarget = Math.ceil(goal.targetMinutes / 7);
    const dailyUsageMap = new Map<string, number>();

    for (const usage of weekUsage) {
      const dateStr = usage.usageDate.toISOString().split('T')[0];
      dailyUsageMap.set(
        dateStr,
        (dailyUsageMap.get(dateStr) || 0) + usage.totalMinutes
      );
    }

    let daysCompleted = 0;
    for (const [_, minutes] of dailyUsageMap) {
      if (minutes <= dailyTarget) {
        daysCompleted++;
      }
    }

    // Update goal
    return await prisma.weeklyGoal.update({
      where: { id: goal.id },
      data: {
        currentMinutes: totalMinutes,
        daysCompleted,
      },
    });
  }

  /**
   * Get weekly goal history
   */
  async getGoalHistory(userId: string, limit: number = 4) {
    return await prisma.weeklyGoal.findMany({
      where: { userId },
      orderBy: { weekStartDate: 'desc' },
      take: limit,
    });
  }

  /**
   * Get average weekly usage for the past week
   */
  private async getAverageWeeklyUsage(userId: string): Promise<number> {
    const now = new Date();
    const weekAgo = new Date(now);
    weekAgo.setDate(weekAgo.getDate() - 7);

    const usage = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: weekAgo,
          lte: now,
        },
      },
    });

    const totalMinutes = usage.reduce(
      (sum, u) => sum + u.totalMinutes,
      0
    );
    return totalMinutes || 1680; // Default: 4 hours/day * 7 days = 1680 minutes
  }

  /**
   * Get Monday of the week for a given date
   */
  private getWeekStartDate(date: Date): Date {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
    const monday = new Date(d.setDate(diff));
    monday.setHours(0, 0, 0, 0);
    return monday;
  }
}

