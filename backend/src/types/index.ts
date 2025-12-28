import { Request } from 'express';

export enum CategoryType {
  SOCIAL_MEDIA = 'social_media',
  ENTERTAINMENT = 'entertainment',
  GAMING = 'gaming',
  PRODUCTIVITY = 'productivity',
  SHOPPING = 'shopping',
  NEWS_READING = 'news_reading',
  HEALTH_FITNESS = 'health_fitness',
  OTHER = 'other'
}

export interface CreateBudgetRequest {
  userId: string;
  monthYear: string; // ISO date string: "2025-01-01"
  categories: CategoryBudgetInput[];
}

export interface CategoryBudgetInput {
  categoryType: CategoryType;
  categoryName: string;
  monthlyHours: number;
  isExcluded: boolean;
}

export interface SyncUsageRequest {
  userId: string;
  usageDate: string; // ISO date string: "2025-01-15"
  apps: AppUsageInput[];
}

export interface AppUsageInput {
  bundleId: string;
  appName: string;
  totalMinutes: number;
}

export interface BudgetStatusResponse {
  date: string;
  totalMinutes: number;
  categories: {
    [key: string]: CategoryStatus;
  };
}

export interface CategoryStatus {
  totalMinutes: number;
  dailyBudget: number;
  monthlyBudget: number;
  monthlyUsed: number;
  status: 'under' | 'over' | 'at_limit';
  apps: AppMinutes[];
}

export interface AppMinutes {
  name: string;
  minutes: number;
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
}

export interface AlertDTO {
  category: string;
  overageMinutes: number;
}

export interface AuthRequest extends Request {
  userId?: string;
}
