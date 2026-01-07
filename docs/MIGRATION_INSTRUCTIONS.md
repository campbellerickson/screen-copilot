# 🚀 Quick Migration Instructions

## The Problem
Prisma migrations are hanging when connecting through the pooler. This is a common issue.

## The Solution
Run the SQL directly in Supabase's SQL Editor - it's faster and more reliable!

---

## Steps:

### 1. Open Supabase SQL Editor
- Go to: **Supabase Dashboard → SQL Editor**
- Click **"New query"**

### 2. Copy and Paste the Migration
- Open `backend/ALL_MIGRATIONS.sql`
- Copy the entire file
- Paste it into the SQL Editor

### 3. Run It!
- Click **"Run"** (or press Cmd+Enter)
- Wait a few seconds
- You should see: "Success. No rows returned"

### 4. Verify Tables Were Created
- Go to **Supabase Dashboard → Table Editor**
- You should see all these tables:
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

## After Migration:

1. **Set Environment Variables in Supabase:**
   - Go to **Settings → Edge Functions → Secrets**
   - Add only this secret (Supabase provides the others automatically):
     - **Name:** `SERVICE_ROLE_KEY`
     - **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZnl1bnVraW53Z2xhaXRqa2ZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzYyNzY4NSwiZXhwIjoyMDgzMjAzNjg1fQ.Nn1JoNRCNLfSBXWYK8svnXetmmGEWRLnZgXCbtXPzLA`

2. **Update Edge Functions Code:**
   - I'll update the code to use `SERVICE_ROLE_KEY` instead of `SUPABASE_SERVICE_ROLE_KEY`

3. **Deploy Functions:**
   ```bash
   supabase functions deploy
   ```

---

**This is much faster than Prisma!** The SQL Editor connects directly and runs instantly. 🚀

