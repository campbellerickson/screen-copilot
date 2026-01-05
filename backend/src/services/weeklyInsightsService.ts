import prisma from '../config/database';

export class WeeklyInsightsService {
  /**
   * Get weekly insights/summary
   */
  async getWeeklyInsights(userId: string, weekStartDate?: Date) {
    const weekStart = weekStartDate
      ? this.getWeekStartDate(weekStartDate)
      : this.getWeekStartDate(new Date());

    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);

    // Get usage for the week
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
            appName: true,
          },
        },
      },
    });

    // Calculate totals by category
    const categoryTotals = new Map<string, number>();
    const appTotals = new Map<string, number>();
    const dailyTotals = new Map<string, number>();

    for (const usage of weekUsage) {
      const category = usage.app.categoryType || 'other';
      categoryTotals.set(
        category,
        (categoryTotals.get(category) || 0) + usage.totalMinutes
      );

      const appName = usage.app.appName;
      appTotals.set(appName, (appTotals.get(appName) || 0) + usage.totalMinutes);

      const dateStr = usage.usageDate.toISOString().split('T')[0];
      dailyTotals.set(
        dateStr,
        (dailyTotals.get(dateStr) || 0) + usage.totalMinutes
      );
    }

    // Get previous week for comparison
    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setDate(prevWeekStart.getDate() - 7);
    const prevWeekEnd = new Date(weekStart);
    prevWeekEnd.setDate(prevWeekEnd.getDate() - 1);

    const prevWeekUsage = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: prevWeekStart,
          lte: prevWeekEnd,
        },
      },
    });

    const prevWeekTotal = prevWeekUsage.reduce(
      (sum, u) => sum + u.totalMinutes,
      0
    );
    const currentWeekTotal = Array.from(dailyTotals.values()).reduce(
      (sum, m) => sum + m,
      0
    );

    // Get top categories
    const topCategories = Array.from(categoryTotals.entries())
      .map(([category, minutes]) => ({ category, minutes }))
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 5);

    // Get top apps
    const topApps = Array.from(appTotals.entries())
      .map(([appName, minutes]) => ({ appName, minutes }))
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 5);

    // Calculate daily averages
    const dailyAverages = Array.from(dailyTotals.entries()).map(
      ([date, minutes]) => ({
        date,
        minutes,
      })
    );

    return {
      weekStart: weekStart.toISOString(),
      weekEnd: weekEnd.toISOString(),
      totalMinutes: currentWeekTotal,
      previousWeekTotal: prevWeekTotal,
      change: currentWeekTotal - prevWeekTotal,
      changePercent:
        prevWeekTotal > 0
          ? ((currentWeekTotal - prevWeekTotal) / prevWeekTotal) * 100
          : 0,
      averageDailyMinutes: Math.round(currentWeekTotal / 7),
      topCategories,
      topApps,
      dailyBreakdown: dailyAverages,
    };
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

