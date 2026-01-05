export interface CategoryBudgetInput {
  categoryType: string;
  categoryName: string;
  monthlyHours: number;
  isExcluded?: boolean;
}

export interface CreateBudgetRequest {
  userId: string;
  monthYear: string;
  categories: CategoryBudgetInput[];
}

export interface AppUsageInput {
  bundleId: string;
  appName: string;
  totalMinutes: number;
}

export interface SyncUsageRequest {
  userId: string;
  usageDate: string;
  apps: AppUsageInput[];
}

export interface CategoryStatus {
  totalMinutes: number;
  dailyBudget: number;
  monthlyBudget: number;
  monthlyUsed: number;
  status: 'under' | 'at_limit' | 'over';
  apps: AppMinutes[];
}

export interface BudgetStatusResponse {
  date: string;
  totalMinutes: number;
  categories: { [key: string]: CategoryStatus };
}

export interface AppMinutes {
  name: string;
  minutes: number;
}

export interface NotificationAlert {
  type: 'daily_overage' | 'monthly_overage';
  categoryType: string;
  categoryName: string;
  overageMinutes: number;
  usedMinutes: number;
  budgetMinutes: number;
  message: string;
}

export interface SyncResponse {
  synced: number;
  budgetStatus: {
    [key: string]: {
      usedToday: number;
      dailyBudget: number;
      remaining: number;
      status: 'under' | 'over';
    };
  };
  alertsTriggered: AlertDTO[];
  notifications?: NotificationAlert[]; // Added for notification support
}

export interface AlertDTO {
  category: string;
  overageMinutes: number;
}

export type CategoryType =
  | 'social_media'
  | 'entertainment'
  | 'gaming'
  | 'productivity'
  | 'shopping'
  | 'news_reading'
  | 'health_fitness'
  | 'other';
