import prisma from '../config/database';
import { CategoryBudgetInput, CategoryType } from '../types';
import { Decimal } from '@prisma/client/runtime/library';

export class BudgetService {
  /**
   * Create a new screen time budget
   */
  async createBudget(
    userId: string,
    monthYear: Date,
    categories: CategoryBudgetInput[]
  ) {
    // Delete existing budget for this month if it exists
    await prisma.screenTimeBudget.deleteMany({
      where: {
        userId,
        monthYear,
      },
    });

    // Create new budget with categories
    const budget = await prisma.screenTimeBudget.create({
      data: {
        userId,
        monthYear,
        categories: {
          create: categories.map((cat) => ({
            categoryType: cat.categoryType,
            categoryName: cat.categoryName,
            monthlyHours: new Decimal(cat.monthlyHours),
            isExcluded: cat.isExcluded,
          })),
        },
      },
      include: {
        categories: true,
      },
    });

    return budget;
  }

  /**
   * Get current month's budget for a user
   */
  async getCurrentBudget(userId: string) {
    const now = new Date();
    const monthYear = new Date(now.getFullYear(), now.getMonth(), 1);

    const budget = await prisma.screenTimeBudget.findUnique({
      where: {
        userId_monthYear: {
          userId,
          monthYear,
        },
      },
      include: {
        categories: true,
      },
    });

    return budget;
  }

  /**
   * Update a category budget
   */
  async updateCategoryBudget(
    categoryId: string,
    monthlyHours: number,
    isExcluded?: boolean
  ) {
    const updateData: any = {
      monthlyHours: new Decimal(monthlyHours),
    };

    if (isExcluded !== undefined) {
      updateData.isExcluded = isExcluded;
    }

    return await prisma.categoryBudget.update({
      where: { id: categoryId },
      data: updateData,
    });
  }

  /**
   * Calculate daily budget from monthly budget
   */
  calculateDailyBudget(monthlyHours: number, monthYear: Date): number {
    const daysInMonth = new Date(
      monthYear.getFullYear(),
      monthYear.getMonth() + 1,
      0
    ).getDate();

    return Math.round((monthlyHours * 60) / daysInMonth); // Return minutes
  }
}
