import { Request, Response } from 'express';
import { BreakReminderService } from '../services/breakReminderService';

const breakReminderService = new BreakReminderService();

/**
 * Get break reminder settings
 * GET /api/v1/break-reminders
 */
export async function getBreakReminder(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;

    const reminder = await breakReminderService.getBreakReminder(userId);

    return res.status(200).json({
      success: true,
      data: reminder,
    });
  } catch (error) {
    console.error('Get break reminder error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to get break reminder settings',
    });
  }
}

/**
 * Update break reminder settings
 * PUT /api/v1/break-reminders
 */
export async function updateBreakReminder(req: Request, res: Response) {
  try {
    const userId = (req as any).userId;
    const { isEnabled, intervalMinutes, breakDurationMinutes, quietHoursStart, quietHoursEnd } = req.body;

    const reminder = await breakReminderService.updateBreakReminder(userId, {
      isEnabled,
      intervalMinutes,
      breakDurationMinutes,
      quietHoursStart,
      quietHoursEnd,
    });

    return res.status(200).json({
      success: true,
      data: reminder,
    });
  } catch (error) {
    console.error('Update break reminder error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to update break reminder settings',
    });
  }
}

