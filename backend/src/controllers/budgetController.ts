import { Request, Response } from 'express';
import { BudgetService } from '../services/budgetService';
import { CreateBudgetRequest } from '../types';

const budgetService = new BudgetService();

export const createBudget = async (req: Request, res: Response) => {
  try {
    const { userId, monthYear, categories }: CreateBudgetRequest = req.body;

    const budget = await budgetService.createBudget(
      userId,
      new Date(monthYear),
      categories
    );

    res.status(201).json({
      success: true,
      data: budget,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

export const getCurrentBudget = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const budget = await budgetService.getCurrentBudget(userId);

    if (!budget) {
      return res.status(404).json({
        success: false,
        error: 'No budget found for current month',
      });
    }

    res.json({
      success: true,
      data: budget,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

export const updateCategoryBudget = async (req: Request, res: Response) => {
  try {
    const { categoryId } = req.params;
    const { monthlyHours, isExcluded } = req.body;

    const category = await budgetService.updateCategoryBudget(
      categoryId,
      monthlyHours,
      isExcluded
    );

    res.json({
      success: true,
      data: category,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};
