# 🚀 Setup Guide

Complete setup instructions for Screen Budget app with Supabase.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Supabase Setup](#supabase-setup)
3. [Database Migration](#database-migration)
4. [Edge Functions Setup](#edge-functions-setup)
5. [Environment Variables](#environment-variables)
6. [iOS App Configuration](#ios-app-configuration)
7. [Testing](#testing)

---

## Prerequisites

- Supabase account ([supabase.com](https://supabase.com))
- Node.js 18+ installed
- Xcode 15+ installed
- Supabase CLI installed: `npm install -g supabase`

---

## Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your project details:
   - Project URL: `https://[project-ref].supabase.co`
   - Project Ref: `[project-ref]`
   - Publishable Key: Found in Settings → API
   - Service Role Key: Found in Settings → API (click "Reveal")

### 2. Get Database Connection String

1. Go to **Supabase Dashboard → Settings → Database**
2. Find **"Connection string"** section
3. Select:
   - **Type:** URI
   - **Source:** Primary Database
   - **Method:** Transaction pooler
4. Copy the connection string (port 6543)
   - Format: `postgresql://postgres.[project-ref]:[PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres`

---

## Database Migration

### Option 1: SQL Editor (Recommended - Fastest)

1. Open **Supabase Dashboard → SQL Editor**
2. Click **"New query"**
3. Open `backend/ALL_MIGRATIONS.sql`
4. Copy the entire file
5. Paste into SQL Editor
6. Click **"Run"** (or Cmd+Enter)
7. Wait a few seconds - you should see "Success. No rows returned"

### Option 2: Prisma Migrate (Alternative)

```bash
cd backend
export DATABASE_URL="postgresql://postgres.[project-ref]:[PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres"
npx prisma migrate deploy
npx prisma generate
```

**Note:** Prisma migrations may hang with pooler connections. Use SQL Editor if this happens.

### Verify Tables

Go to **Supabase Dashboard → Table Editor** and verify these tables exist:
- `users`
- `subscriptions`
- `screen_time_budgets`
- `category_budgets`
- `user_apps`
- `daily_app_usage`
- `budget_alerts`
- `streaks`
- `achievements`
- `weekly_goals`
- `break_reminders`

---

## Edge Functions Setup

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link Your Project

```bash
cd /path/to/screen-budget
supabase link --project-ref [your-project-ref]
```

Replace `[your-project-ref]` with your actual project reference (e.g., `jqfyunukinwglaitjkfr`).

### 4. Deploy Functions

Deploy all functions at once:

```bash
supabase functions deploy
```

Or deploy individually:

```bash
supabase functions deploy auth-signup
supabase functions deploy auth-login
supabase functions deploy auth-me
supabase functions deploy auth-delete-account
supabase functions deploy subscription-status
supabase functions deploy subscription-cancel
supabase functions deploy subscription-validate-receipt
supabase functions deploy budget-create
supabase functions deploy budget-get
supabase functions deploy budget-update-category
supabase functions deploy usage-sync
supabase functions deploy usage-daily
supabase functions deploy weekly-goals-current
supabase functions deploy weekly-goals-set
supabase functions deploy weekly-goals-history
supabase functions deploy break-reminders-get
supabase functions deploy break-reminders-update
supabase functions deploy weekly-insights
```

---

## Environment Variables

### Supabase Edge Functions Secrets

Go to **Supabase Dashboard → Settings → Edge Functions → Secrets**

Add this secret:

| Name | Value |
|------|-------|
| `SERVICE_ROLE_KEY` | Your service role key from Settings → API |

**Important:** 
- Supabase automatically provides `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- You only need to add `SERVICE_ROLE_KEY` (without the `SUPABASE_` prefix)
- Secrets starting with `SUPABASE_` are not allowed

### Optional Secrets

Add these when ready:

| Name | Value | When Needed |
|------|-------|-------------|
| `APPLE_SHARED_SECRET` | From App Store Connect | When setting up subscriptions |

---

## iOS App Configuration

### 1. Update Base URL

Open `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
static let baseURL = "https://[your-project-ref].supabase.co/functions/v1"
```

Replace `[your-project-ref]` with your actual Supabase project reference.

### 2. Build and Run

1. Open `ios/ScreenTimeBudget.xcodeproj` in Xcode
2. Select your development team
3. Build and run on simulator or device

---

## Testing

### 1. Test Authentication

```bash
curl -X POST https://[project-ref].supabase.co/functions/v1/auth-signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234","name":"Test User"}'
```

### 2. Test in iOS App

1. Build and run the iOS app
2. Try signing up with a test account
3. Verify it connects to Supabase
4. Test usage syncing

---

## 🐛 Troubleshooting

### "Can't reach database server"
- Make sure you're using the **Transaction pooler** connection string (port 6543)
- Not the direct connection string

### "Authentication required" errors
- Make sure you've deployed all Edge Functions
- Check that `SERVICE_ROLE_KEY` is set correctly in Supabase secrets

### Function deployment fails
- Make sure you're logged in: `supabase login`
- Make sure project is linked: `supabase link --project-ref [ref]`
- Check that environment variables are set in Supabase Dashboard

### Prisma migrations hang
- Use the SQL Editor method instead (see [Database Migration](#database-migration))
- Run `backend/ALL_MIGRATIONS.sql` directly in Supabase SQL Editor

---

## 📚 Additional Resources

- [Migration Instructions](MIGRATION_INSTRUCTIONS.md) - Detailed migration guide
- [Quick Start](QUICK_START.md) - Fastest setup path
- [Subscription Setup](SUBSCRIPTION_CLARIFICATION.md) - iOS subscription configuration
- [Supabase Migration Guide](SUPABASE_MIGRATION_GUIDE.md) - Complete migration details

---

**Setup complete!** Your app should now be ready to use. 🎉
