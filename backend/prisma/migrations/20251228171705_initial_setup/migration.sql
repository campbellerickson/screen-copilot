-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "screen_time_budgets" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "monthYear" TIMESTAMP(3) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "screen_time_budgets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "category_budgets" (
    "id" TEXT NOT NULL,
    "budgetId" TEXT NOT NULL,
    "categoryName" VARCHAR(100) NOT NULL,
    "categoryType" VARCHAR(50) NOT NULL,
    "monthlyHours" DECIMAL(6,2) NOT NULL,
    "isExcluded" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "category_budgets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_apps" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "bundleId" VARCHAR(255) NOT NULL,
    "appName" VARCHAR(255) NOT NULL,
    "categoryType" VARCHAR(50),
    "isExcluded" BOOLEAN NOT NULL DEFAULT false,
    "lastDetected" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_apps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_app_usage" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "appId" TEXT NOT NULL,
    "usageDate" DATE NOT NULL,
    "totalMinutes" INTEGER NOT NULL,
    "syncedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_app_usage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "budget_alerts" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "categoryType" VARCHAR(50) NOT NULL,
    "alertDate" DATE NOT NULL,
    "overageMinutes" INTEGER NOT NULL,
    "alertSentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "wasDismissed" BOOLEAN NOT NULL DEFAULT false,
    "dismissedAt" TIMESTAMP(3),

    CONSTRAINT "budget_alerts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "screen_time_budgets_userId_monthYear_idx" ON "screen_time_budgets"("userId", "monthYear");

-- CreateIndex
CREATE UNIQUE INDEX "screen_time_budgets_userId_monthYear_key" ON "screen_time_budgets"("userId", "monthYear");

-- CreateIndex
CREATE INDEX "category_budgets_budgetId_idx" ON "category_budgets"("budgetId");

-- CreateIndex
CREATE INDEX "user_apps_userId_idx" ON "user_apps"("userId");

-- CreateIndex
CREATE INDEX "user_apps_userId_categoryType_idx" ON "user_apps"("userId", "categoryType");

-- CreateIndex
CREATE UNIQUE INDEX "user_apps_userId_bundleId_key" ON "user_apps"("userId", "bundleId");

-- CreateIndex
CREATE INDEX "daily_app_usage_userId_usageDate_idx" ON "daily_app_usage"("userId", "usageDate");

-- CreateIndex
CREATE INDEX "daily_app_usage_appId_usageDate_idx" ON "daily_app_usage"("appId", "usageDate");

-- CreateIndex
CREATE UNIQUE INDEX "daily_app_usage_userId_appId_usageDate_key" ON "daily_app_usage"("userId", "appId", "usageDate");

-- CreateIndex
CREATE INDEX "budget_alerts_userId_alertDate_idx" ON "budget_alerts"("userId", "alertDate");

-- AddForeignKey
ALTER TABLE "screen_time_budgets" ADD CONSTRAINT "screen_time_budgets_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "category_budgets" ADD CONSTRAINT "category_budgets_budgetId_fkey" FOREIGN KEY ("budgetId") REFERENCES "screen_time_budgets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_apps" ADD CONSTRAINT "user_apps_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_app_usage" ADD CONSTRAINT "daily_app_usage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_app_usage" ADD CONSTRAINT "daily_app_usage_appId_fkey" FOREIGN KEY ("appId") REFERENCES "user_apps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "budget_alerts" ADD CONSTRAINT "budget_alerts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
