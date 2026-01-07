-- ============================================
-- Complete Database Schema Migration
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. Initial Setup (Users, Budgets, Apps, Usage)
-- ============================================

-- Users table
CREATE TABLE IF NOT EXISTS "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT,
    "name" TEXT,
    "apple_id" TEXT,
    "profile_image" TEXT,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX IF NOT EXISTS "users_apple_id_key" ON "users"("apple_id") WHERE "apple_id" IS NOT NULL;

-- Subscriptions table
CREATE TABLE IF NOT EXISTS "subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL UNIQUE,
    "status" VARCHAR(20) NOT NULL,
    "platform" VARCHAR(20) NOT NULL,
    "trial_start_date" TIMESTAMP(3),
    "trial_end_date" TIMESTAMP(3),
    "subscription_start_date" TIMESTAMP(3),
    "subscription_end_date" TIMESTAMP(3),
    "renewal_date" TIMESTAMP(3),
    "stripe_customer_id" TEXT,
    "stripe_subscription_id" TEXT,
    "price_usd" DECIMAL(10,2),
    "ios_receipt_data" TEXT,
    "ios_transaction_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "subscriptions_stripe_customer_id_key" ON "subscriptions"("stripe_customer_id") WHERE "stripe_customer_id" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "subscriptions_stripe_subscription_id_key" ON "subscriptions"("stripe_subscription_id") WHERE "stripe_subscription_id" IS NOT NULL;

-- Screen time budgets
CREATE TABLE IF NOT EXISTS "screen_time_budgets" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "month_year" DATE NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "screen_time_budgets_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "screen_time_budgets_user_id_month_year_key" ON "screen_time_budgets"("user_id", "month_year");
CREATE INDEX IF NOT EXISTS "screen_time_budgets_user_id_month_year_idx" ON "screen_time_budgets"("user_id", "month_year");

-- Category budgets
CREATE TABLE IF NOT EXISTS "category_budgets" (
    "id" TEXT NOT NULL,
    "budget_id" TEXT NOT NULL,
    "category_type" VARCHAR(50) NOT NULL,
    "category_name" VARCHAR(100) NOT NULL,
    "monthly_hours" DECIMAL(10,2) NOT NULL,
    "is_excluded" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "category_budgets_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "category_budgets_budget_id_idx" ON "category_budgets"("budget_id");

-- User apps
CREATE TABLE IF NOT EXISTS "user_apps" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "bundle_id" VARCHAR(255) NOT NULL,
    "app_name" VARCHAR(255) NOT NULL,
    "category_type" VARCHAR(50),
    "last_detected" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_apps_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "user_apps_user_id_bundle_id_key" ON "user_apps"("user_id", "bundle_id");
CREATE INDEX IF NOT EXISTS "user_apps_user_id_idx" ON "user_apps"("user_id");

-- Daily app usage
CREATE TABLE IF NOT EXISTS "daily_app_usage" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "app_id" TEXT NOT NULL,
    "usage_date" DATE NOT NULL,
    "total_minutes" INTEGER NOT NULL,
    "synced_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_app_usage_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "daily_app_usage_user_id_app_id_usage_date_key" ON "daily_app_usage"("user_id", "app_id", "usage_date");
CREATE INDEX IF NOT EXISTS "daily_app_usage_user_id_usage_date_idx" ON "daily_app_usage"("user_id", "usage_date");

-- Budget alerts
CREATE TABLE IF NOT EXISTS "budget_alerts" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "category_type" VARCHAR(50) NOT NULL,
    "alert_date" DATE NOT NULL,
    "overage_minutes" INTEGER NOT NULL,
    "alert_sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "was_dismissed" BOOLEAN NOT NULL DEFAULT false,
    "dismissed_at" TIMESTAMP(3),

    CONSTRAINT "budget_alerts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "budget_alerts_user_id_alert_date_idx" ON "budget_alerts"("user_id", "alert_date");

-- ============================================
-- 2. Streaks and Achievements
-- ============================================

CREATE TABLE IF NOT EXISTS "streaks" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL UNIQUE,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "longest_streak" INTEGER NOT NULL DEFAULT 0,
    "last_achieved" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "streaks_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "achievements" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "achieved_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "type" VARCHAR(50),
    "value" INTEGER,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "achievements_user_id_name_key" ON "achievements"("user_id", "name");
CREATE INDEX IF NOT EXISTS "achievements_user_id_idx" ON "achievements"("user_id");

-- ============================================
-- 3. Weekly Goals and Break Reminders
-- ============================================

CREATE TABLE IF NOT EXISTS "weekly_goals" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "week_start_date" DATE NOT NULL,
    "target_minutes" INTEGER NOT NULL,
    "current_minutes" INTEGER NOT NULL DEFAULT 0,
    "days_completed" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weekly_goals_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "weekly_goals_user_id_week_start_date_key" ON "weekly_goals"("user_id", "week_start_date");
CREATE INDEX IF NOT EXISTS "weekly_goals_user_id_week_start_date_idx" ON "weekly_goals"("user_id", "week_start_date");

CREATE TABLE IF NOT EXISTS "break_reminders" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL UNIQUE,
    "is_enabled" BOOLEAN NOT NULL DEFAULT true,
    "interval_minutes" INTEGER NOT NULL DEFAULT 60,
    "break_duration_minutes" INTEGER NOT NULL DEFAULT 5,
    "quiet_hours_start" INTEGER,
    "quiet_hours_end" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "break_reminders_pkey" PRIMARY KEY ("id")
);

-- ============================================
-- 4. Foreign Keys
-- ============================================

-- Subscriptions
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'subscriptions_user_id_fkey'
    ) THEN
        ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Screen time budgets
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'screen_time_budgets_user_id_fkey'
    ) THEN
        ALTER TABLE "screen_time_budgets" ADD CONSTRAINT "screen_time_budgets_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Category budgets
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'category_budgets_budget_id_fkey'
    ) THEN
        ALTER TABLE "category_budgets" ADD CONSTRAINT "category_budgets_budget_id_fkey" 
        FOREIGN KEY ("budget_id") REFERENCES "screen_time_budgets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- User apps
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_apps_user_id_fkey'
    ) THEN
        ALTER TABLE "user_apps" ADD CONSTRAINT "user_apps_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Daily app usage
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'daily_app_usage_user_id_fkey'
    ) THEN
        ALTER TABLE "daily_app_usage" ADD CONSTRAINT "daily_app_usage_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'daily_app_usage_app_id_fkey'
    ) THEN
        ALTER TABLE "daily_app_usage" ADD CONSTRAINT "daily_app_usage_app_id_fkey" 
        FOREIGN KEY ("app_id") REFERENCES "user_apps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Budget alerts
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'budget_alerts_user_id_fkey'
    ) THEN
        ALTER TABLE "budget_alerts" ADD CONSTRAINT "budget_alerts_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Streaks
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'streaks_user_id_fkey'
    ) THEN
        ALTER TABLE "streaks" ADD CONSTRAINT "streaks_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Achievements
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'achievements_user_id_fkey'
    ) THEN
        ALTER TABLE "achievements" ADD CONSTRAINT "achievements_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Weekly goals
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'weekly_goals_user_id_fkey'
    ) THEN
        ALTER TABLE "weekly_goals" ADD CONSTRAINT "weekly_goals_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- Break reminders
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'break_reminders_user_id_fkey'
    ) THEN
        ALTER TABLE "break_reminders" ADD CONSTRAINT "break_reminders_user_id_fkey" 
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- ============================================
-- Done! All tables and relationships created.
-- ============================================

