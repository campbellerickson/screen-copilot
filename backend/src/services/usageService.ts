import prisma from '../config/database';
import { AppUsageInput, BudgetStatusResponse, CategoryStatus } from '../types';
import { BudgetService } from './budgetService';

export class UsageService {
  private budgetService = new BudgetService();

  /**
   * Sync usage data from iOS app
   * OPTIMIZED: Parallel processing with Promise.all for better performance
   */
  async syncUsageData(userId: string, usageDate: Date, apps: AppUsageInput[]) {
    const results = {
      synced: 0,
      errors: [] as string[],
    };

    // OPTIMIZATION: Process apps in parallel batches instead of sequentially
    // Batch size of 10 to avoid overwhelming the database
    const BATCH_SIZE = 10;
    
    for (let i = 0; i < apps.length; i += BATCH_SIZE) {
      const batch = apps.slice(i, i + BATCH_SIZE);
      
      const batchResults = await Promise.allSettled(
        batch.map(async (app) => {
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
        })
      );

      // Process batch results
      batchResults.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          results.synced++;
        } else {
          results.errors.push(`Failed to sync ${batch[index].appName}: ${result.reason}`);
        }
      });
    }

    return results;
  }

  /**
   * Get daily usage summary
   * OPTIMIZED: Combined query optimization and better aggregation
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

    // OPTIMIZATION: Calculate date range once
    const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
    const monthEnd = new Date(date.getFullYear(), date.getMonth() + 1, 0);
    const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    // OPTIMIZATION: Fetch both daily and monthly usage in parallel
    const [dailyUsages, monthlyUsages] = await Promise.all([
      prisma.dailyAppUsage.findMany({
        where: {
          userId,
          usageDate: dateOnly,
        },
        include: {
          app: {
            select: {
              categoryType: true,
              appName: true,
            },
          },
        },
      }),
      prisma.dailyAppUsage.findMany({
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
      }),
    ]);

    // OPTIMIZATION: Use Map for O(1) lookups instead of nested loops
    const categoryMap = new Map<
      string,
      {
        totalMinutes: number;
        monthlyUsed: number;
        apps: { name: string; minutes: number }[];
      }
    >();

    // Process daily usage
    for (const usage of dailyUsages) {
      const category = usage.app.categoryType || 'other';

      if (!categoryMap.has(category)) {
        categoryMap.set(category, {
          totalMinutes: 0,
          monthlyUsed: 0,
          apps: [],
        });
      }

      const categoryData = categoryMap.get(category)!;
      categoryData.totalMinutes += usage.totalMinutes;
      categoryData.apps.push({
        name: usage.app.appName,
        minutes: usage.totalMinutes,
      });
    }

    // Process monthly usage
    for (const usage of monthlyUsages) {
      const category = usage.app.categoryType || 'other';
      const categoryData = categoryMap.get(category);
      if (categoryData) {
        categoryData.monthlyUsed += usage.totalMinutes;
      }
    }

    // Build response with budget info
    const categories: { [key: string]: CategoryStatus } = {};
    let totalMinutes = 0;

    for (const categoryBudget of budget.categories) {
      const categoryData = categoryMap.get(categoryBudget.categoryType) || {
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
   * OPTIMIZED: Cached categorization logic (could be further optimized with a lookup table)
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
