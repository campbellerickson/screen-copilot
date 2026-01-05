import { Request, Response } from 'express';
import { WeeklyInsightsService } from '../services/weeklyInsightsService';

const weeklyInsightsService = new WeeklyInsightsService();

/**
 * Get weekly insights
 * GET /api/v1/weekly-insights
 */
export async function getWeeklyInsights(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;
    const weekStartDate = req.query.weekStartDate
      ? new Date(req.query.weekStartDate as string)
      : undefined;

    const insights = await weeklyInsightsService.getWeeklyInsights(
      userId,
      weekStartDate
    );

    return res.status(200).json({
      success: true,
      data: insights,
    });
  } catch (error) {
    console.error('Get weekly insights error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get weekly insights',
    });
  }
}

