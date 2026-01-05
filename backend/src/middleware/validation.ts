import { Request, Response, NextFunction } from 'express';

/**
 * Validation middleware for request bodies
 */

export const validateCreateBudget = (req: Request, res: Response, next: NextFunction) => {
  const { userId, monthYear, categories } = req.body;

  // Validate required fields
  if (!userId || typeof userId !== 'string' || userId.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'userId is required and must be a non-empty string',
    });
  }

  if (!monthYear || typeof monthYear !== 'string') {
    return res.status(400).json({
      success: false,
      error: 'monthYear is required and must be an ISO date string',
    });
  }

  // Validate monthYear is a valid date
  const date = new Date(monthYear);
  if (isNaN(date.getTime())) {
    return res.status(400).json({
      success: false,
      error: 'monthYear must be a valid ISO date string',
    });
  }

  // Validate categories
  if (!Array.isArray(categories) || categories.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'categories is required and must be a non-empty array',
    });
  }

  // Validate each category
  for (const category of categories) {
    if (!category.categoryType || typeof category.categoryType !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Each category must have a categoryType string',
      });
    }

    if (!category.categoryName || typeof category.categoryName !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Each category must have a categoryName string',
      });
    }

    if (category.monthlyHours === undefined || typeof category.monthlyHours !== 'number') {
      return res.status(400).json({
        success: false,
        error: 'Each category must have a monthlyHours number',
      });
    }

    if (category.monthlyHours < 0 || category.monthlyHours > 744) { // 31 days * 24 hours
      return res.status(400).json({
        success: false,
        error: 'monthlyHours must be between 0 and 744',
      });
    }

    if (category.isExcluded !== undefined && typeof category.isExcluded !== 'boolean') {
      return res.status(400).json({
        success: false,
        error: 'isExcluded must be a boolean if provided',
      });
    }
  }

  next();
};

export const validateSyncUsage = (req: Request, res: Response, next: NextFunction) => {
  const { userId, usageDate, apps } = req.body;

  // Validate required fields
  if (!userId || typeof userId !== 'string' || userId.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'userId is required and must be a non-empty string',
    });
  }

  if (!usageDate || typeof usageDate !== 'string') {
    return res.status(400).json({
      success: false,
      error: 'usageDate is required and must be an ISO date string',
    });
  }

  // Validate usageDate is a valid date
  const date = new Date(usageDate);
  if (isNaN(date.getTime())) {
    return res.status(400).json({
      success: false,
      error: 'usageDate must be a valid ISO date string',
    });
  }

  // Validate apps
  if (!Array.isArray(apps)) {
    return res.status(400).json({
      success: false,
      error: 'apps must be an array',
    });
  }

  // Validate each app (allow empty array)
  for (const app of apps) {
    if (!app.bundleId || typeof app.bundleId !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Each app must have a bundleId string',
      });
    }

    if (!app.appName || typeof app.appName !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Each app must have an appName string',
      });
    }

    if (app.totalMinutes === undefined || typeof app.totalMinutes !== 'number') {
      return res.status(400).json({
        success: false,
        error: 'Each app must have a totalMinutes number',
      });
    }

    if (app.totalMinutes < 0 || app.totalMinutes > 1440) { // 24 hours * 60 minutes
      return res.status(400).json({
        success: false,
        error: 'totalMinutes must be between 0 and 1440',
      });
    }
  }

  next();
};

export const validateUserId = (req: Request, res: Response, next: NextFunction) => {
  const { userId } = req.params;

  if (!userId || typeof userId !== 'string' || userId.trim().length === 0) {
    return res.status(400).json({
      success: false,
      error: 'userId parameter is required',
    });
  }

  next();
};

export const validateUpdateCategoryBudget = (req: Request, res: Response, next: NextFunction) => {
  const { monthlyHours, isExcluded } = req.body;

  if (monthlyHours !== undefined) {
    if (typeof monthlyHours !== 'number') {
      return res.status(400).json({
        success: false,
        error: 'monthlyHours must be a number',
      });
    }

    if (monthlyHours < 0 || monthlyHours > 744) {
      return res.status(400).json({
        success: false,
        error: 'monthlyHours must be between 0 and 744',
      });
    }
  }

  if (isExcluded !== undefined && typeof isExcluded !== 'boolean') {
    return res.status(400).json({
      success: false,
      error: 'isExcluded must be a boolean',
    });
  }

  // At least one field must be provided
  if (monthlyHours === undefined && isExcluded === undefined) {
    return res.status(400).json({
      success: false,
      error: 'At least one of monthlyHours or isExcluded must be provided',
    });
  }

  next();
};
