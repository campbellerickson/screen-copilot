import prisma from '../config/database';
import { AppUsageInput, BudgetStatusResponse, CategoryStatus } from '../types';
import { BudgetService } from './budgetService';

export class UsageService {
  private budgetService = new BudgetService();

  /**
   * Sync usage data from iOS app
   */
  async syncUsageData(userId: string, usageDate: Date, apps: AppUsageInput[]) {
    const results = {
      synced: 0,
      errors: [] as string[],
    };

    for (const app of apps) {
      try {
        // Find or create user app
        const userApp = await prisma.userApp.upsert({
          where: {
            userId_bundleId: {
              userId,
              bundleId: app.bundleId,
            },
          },
          create: {
            userId,
            bundleId: app.bundleId,
            appName: app.appName,
            categoryType: this.categorizeApp(app.bundleId, app.appName),
          },
          update: {
            appName: app.appName,
            lastDetected: new Date(),
          },
        });

        // Create or update daily usage
        await prisma.dailyAppUsage.upsert({
          where: {
            userId_appId_usageDate: {
              userId,
              appId: userApp.id,
              usageDate,
            },
          },
          create: {
            userId,
            appId: userApp.id,
            usageDate,
            totalMinutes: app.totalMinutes,
          },
          update: {
            totalMinutes: app.totalMinutes,
            syncedAt: new Date(),
          },
        });

        results.synced++;
      } catch (error) {
        results.errors.push(`Failed to sync ${app.appName}: ${error}`);
      }
    }

    return results;
  }

  /**
   * Get daily usage summary
   */
  async getDailyUsage(
    userId: string,
    date: Date
  ): Promise<BudgetStatusResponse> {
    // Get current budget
    const budget = await this.budgetService.getCurrentBudget(userId);

    if (!budget) {
      throw new Error('No budget found for current month');
    }

    // Get usage for the date
    const usages = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: date,
      },
      include: {
        app: true,
      },
    });

    // Get monthly usage for context
    const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
    const monthEnd = new Date(date.getFullYear(), date.getMonth() + 1, 0);

    const monthlyUsages = await prisma.dailyAppUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: monthStart,
          lte: monthEnd,
        },
      },
      include: {
        app: true,
      },
    });

    // Aggregate by category
    const categoryMap: {
      [key: string]: {
        totalMinutes: number;
        monthlyUsed: number;
        apps: { name: string; minutes: number }[];
      };
    } = {};

    // Process daily usage
    for (const usage of usages) {
      const category = usage.app.categoryType || 'other';

      if (!categoryMap[category]) {
        categoryMap[category] = {
          totalMinutes: 0,
          monthlyUsed: 0,
          apps: [],
        };
      }

      categoryMap[category].totalMinutes += usage.totalMinutes;
      categoryMap[category].apps.push({
        name: usage.app.appName,
        minutes: usage.totalMinutes,
      });
    }

    // Process monthly usage
    for (const usage of monthlyUsages) {
      const category = usage.app.categoryType || 'other';
      if (categoryMap[category]) {
        categoryMap[category].monthlyUsed += usage.totalMinutes;
      }
    }

    // Build response with budget info
    const categories: { [key: string]: CategoryStatus } = {};
    let totalMinutes = 0;

    for (const categoryBudget of budget.categories) {
      const categoryData = categoryMap[categoryBudget.categoryType] || {
        totalMinutes: 0,
        monthlyUsed: 0,
        apps: [],
      };

      const dailyBudget = this.budgetService.calculateDailyBudget(
        Number(categoryBudget.monthlyHours),
        budget.monthYear
      );

      const monthlyBudgetMinutes = Number(categoryBudget.monthlyHours) * 60;

      categories[categoryBudget.categoryType] = {
        totalMinutes: categoryData.totalMinutes,
        dailyBudget,
        monthlyBudget: monthlyBudgetMinutes,
        monthlyUsed: categoryData.monthlyUsed,
        status:
          categoryData.totalMinutes > dailyBudget
            ? 'over'
            : categoryData.totalMinutes === dailyBudget
            ? 'at_limit'
            : 'under',
        apps: categoryData.apps,
      };

      totalMinutes += categoryData.totalMinutes;
    }

    return {
      date: date.toISOString(),
      totalMinutes,
      categories,
    };
  }

  /**
   * Auto-categorize app based on bundle ID and name
   */
  private categorizeApp(bundleId: string, appName: string): string {
    const lowerName = appName.toLowerCase();
    const lowerId = bundleId.toLowerCase();

    // Social Media
    if (
      lowerId.includes('instagram') ||
      lowerId.includes('tiktok') ||
      lowerId.includes('twitter') ||
      lowerId.includes('facebook') ||
      lowerId.includes('snapchat') ||
      lowerId.includes('reddit') ||
      lowerId.includes('discord') ||
      lowerName.includes('social')
    ) {
      return 'social_media';
    }

    // Entertainment
    if (
      lowerId.includes('netflix') ||
      lowerId.includes('youtube') ||
      lowerId.includes('spotify') ||
      lowerId.includes('hulu') ||
      lowerId.includes('disney') ||
      lowerId.includes('twitch') ||
      lowerName.includes('video') ||
      lowerName.includes('music')
    ) {
      return 'entertainment';
    }

    // Gaming
    if (lowerName.includes('game') || lowerId.includes('game')) {
      return 'gaming';
    }

    // Productivity
    if (
      lowerId.includes('notion') ||
      lowerId.includes('slack') ||
      lowerId.includes('zoom') ||
      lowerId.includes('teams') ||
      lowerId.includes('office') ||
      lowerId.includes('google') ||
      lowerName.includes('work')
    ) {
      return 'productivity';
    }

    // Shopping
    if (
      lowerId.includes('amazon') ||
      lowerId.includes('shop') ||
      lowerId.includes('ebay') ||
      lowerName.includes('shop')
    ) {
      return 'shopping';
    }

    // News & Reading
    if (
      lowerName.includes('news') ||
      lowerName.includes('read') ||
      lowerId.includes('news')
    ) {
      return 'news_reading';
    }

    // Health & Fitness
    if (
      lowerName.includes('health') ||
      lowerName.includes('fitness') ||
      lowerName.includes('workout')
    ) {
      return 'health_fitness';
    }

    return 'other';
  }
}
