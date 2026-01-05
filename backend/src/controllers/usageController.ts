import { Request, Response } from 'express';
import { UsageService } from '../services/usageService';
import { AlertService } from '../services/alertService';
import { SyncUsageRequest } from '../types';

const usageService = new UsageService();
const alertService = new AlertService();

export const syncUsage = async (req: Request, res: Response) => {
  try {
    const { userId, usageDate, apps }: SyncUsageRequest = req.body;

    // Sync usage data
    const syncResult = await usageService.syncUsageData(
      userId,
      new Date(usageDate),
      apps
    );

    // Get updated budget status (includes monthly usage)
    const budgetStatus = await usageService.getDailyUsage(
      userId,
      new Date(usageDate)
    );

    // Calculate category usage from budget status
    const categoryUsage: { [key: string]: number } = {};
    const monthlyUsage: { [key: string]: number } = {};
    
    for (const [category, data] of Object.entries(budgetStatus.categories)) {
      categoryUsage[category] = data.totalMinutes;
      monthlyUsage[category] = data.monthlyUsed;
    }

    // Check for alerts and notifications (daily and monthly)
    const { alerts, notifications } = await alertService.checkAndTriggerAlerts(
      userId,
      new Date(usageDate),
      categoryUsage,
      monthlyUsage
    );

    res.json({
      success: true,
      data: {
        synced: syncResult.synced,
        budgetStatus: budgetStatus.categories,
        alertsTriggered: alerts,
        notifications, // Include notification data for iOS to schedule
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

export const getDailyUsage = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { date } = req.query;

    const usageDate = date ? new Date(date as string) : new Date();

    const usage = await usageService.getDailyUsage(userId, usageDate);

    res.json({
      success: true,
      data: usage,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

export const getUserAlerts = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;

    const alerts = await alertService.getUserAlerts(userId, limit);

    res.json({
      success: true,
      data: alerts,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

export const dismissAlert = async (req: Request, res: Response) => {
  try {
    const { alertId } = req.params;

    const alert = await alertService.dismissAlert(alertId);

    res.json({
      success: true,
      data: alert,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};
