import { Request, Response } from 'express';
import { WeeklyGoalService } from '../services/weeklyGoalService';

const weeklyGoalService = new WeeklyGoalService();

/**
 * Get current week's goal
 * GET /api/v1/weekly-goals/current
 */
export async function getCurrentWeekGoal(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;

    const goal = await weeklyGoalService.getCurrentWeekGoal(userId);

    return res.status(200).json({
      success: true,
      data: goal,
    });
  } catch (error) {
    console.error('Get current week goal error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get weekly goal',
    });
  }
}

/**
 * Set weekly goal
 * POST /api/v1/weekly-goals
 */
export async function setWeeklyGoal(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;
    const { targetMinutes, weekStartDate } = req.body;

    if (!targetMinutes || targetMinutes <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Target minutes must be greater than 0',
      });
    }

    const goal = await weeklyGoalService.setWeeklyGoal(
      userId,
      targetMinutes,
      weekStartDate ? new Date(weekStartDate) : undefined
    );

    return res.status(200).json({
      success: true,
      data: goal,
    });
  } catch (error) {
    console.error('Set weekly goal error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to set weekly goal',
    });
  }
}

/**
 * Get weekly goal history
 * GET /api/v1/weekly-goals/history
 */
export async function getGoalHistory(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;
    const limit = parseInt(req.query.limit as string) || 4;

    const goals = await weeklyGoalService.getGoalHistory(userId, limit);

    return res.status(200).json({
      success: true,
      data: goals,
    });
  } catch (error) {
    console.error('Get goal history error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get goal history',
    });
  }
}

