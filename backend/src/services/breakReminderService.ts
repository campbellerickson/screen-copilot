import prisma from '../config/database';

export class BreakReminderService {
  /**
   * Get break reminder settings
   */
  async getBreakReminder(userId: string) {
    let reminder = await prisma.breakReminder.findUnique({
      where: { userId },
    });

    // Create default if doesn't exist
    if (!reminder) {
      reminder = await prisma.breakReminder.create({
        data: {
          userId,
          isEnabled: true,
          intervalMinutes: 60,
          breakDurationMinutes: 5,
        },
      });
    }

    return reminder;
  }

  /**
   * Update break reminder settings
   */
  async updateBreakReminder(
    userId: string,
    settings: {
      isEnabled?: boolean;
      intervalMinutes?: number;
      breakDurationMinutes?: number;
      quietHoursStart?: number | null;
      quietHoursEnd?: number | null;
    }
  ) {
    return await prisma.breakReminder.upsert({
      where: { userId },
      create: {
        userId,
        isEnabled: settings.isEnabled ?? true,
        intervalMinutes: settings.intervalMinutes ?? 60,
        breakDurationMinutes: settings.breakDurationMinutes ?? 5,
        quietHoursStart: settings.quietHoursStart ?? null,
        quietHoursEnd: settings.quietHoursEnd ?? null,
      },
      update: {
        ...(settings.isEnabled !== undefined && {
          isEnabled: settings.isEnabled,
        }),
        ...(settings.intervalMinutes !== undefined && {
          intervalMinutes: settings.intervalMinutes,
        }),
        ...(settings.breakDurationMinutes !== undefined && {
          breakDurationMinutes: settings.breakDurationMinutes,
        }),
        ...(settings.quietHoursStart !== undefined && {
          quietHoursStart: settings.quietHoursStart,
        }),
        ...(settings.quietHoursEnd !== undefined && {
          quietHoursEnd: settings.quietHoursEnd,
        }),
      },
    });
  }

  /**
   * Check if break reminder should be sent
   * This would be called by the iOS app based on usage
   */
  shouldSendReminder(userId: string, currentUsageMinutes: number): Promise<boolean> {
    return prisma.breakReminder
      .findUnique({
        where: { userId },
      })
      .then((reminder) => {
        if (!reminder || !reminder.isEnabled) return false;

        // Check quiet hours
        const now = new Date();
        const currentHour = now.getHours();

        if (
          reminder.quietHoursStart !== null &&
          reminder.quietHoursEnd !== null
        ) {
          if (reminder.quietHoursStart <= reminder.quietHoursEnd) {
            // Same day quiet hours (e.g., 22:00 - 08:00)
            if (
              currentHour >= reminder.quietHoursStart &&
              currentHour < reminder.quietHoursEnd
            ) {
              return false;
            }
          } else {
            // Overnight quiet hours (e.g., 22:00 - 08:00)
            if (
              currentHour >= reminder.quietHoursStart ||
              currentHour < reminder.quietHoursEnd
            ) {
              return false;
            }
          }
        }

        // Check if usage exceeds interval
        return currentUsageMinutes >= reminder.intervalMinutes;
      });
  }
}

