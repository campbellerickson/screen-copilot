# 🚀 Quick Setup Steps for Your Supabase Project

## Your Project Details
- **Project URL:** `https://jqfyunukinwglaitjkfr.supabase.co`
- **Project Ref:** `jqfyunukinwglaitjkfr`
- **Publishable Key:** `sb_publishable_dSuF2TAFXM8vKN4bHiMpKg_4wUHOnT4`
- **Service Role Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZnl1bnVraW53Z2xhaXRqa2ZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzYyNzY4NSwiZXhwIjoyMDgzMjAzNjg1fQ.Nn1JoNRCNLfSBXWYK8svnXetmmGEWRLnZgXCbtXPzLA`
- **Database Connection (Transaction Pooler):** `postgresql://postgres.jqfyunukinwglaitjkfr:[YOUR-PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres`

---

## ✅ Step 1: iOS App Updated
The iOS app `Constants.swift` has been updated with your Supabase URL.

---

## 📋 Step 2: Get Your Database Connection String

1. Go to Supabase Dashboard → Settings → Database
2. Find **"Connection string"** section
3. Copy the **"Connection pooling"** string (port 6543)
   - It should look like: `postgresql://postgres:[YOUR-PASSWORD]@db.jqfyunukinwglaitjkfr.supabase.co:6543/postgres?pgbouncer=true`
4. **Important:** Use the pooled connection string, not the direct connection

---

## 🗄️ Step 3: Run Database Migrations

```bash
cd backend

# Set your database URL (use the Transaction pooler connection string)
# Replace [YOUR-PASSWORD] with your actual database password
export DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:[YOUR-PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres"

# Run migrations
npx prisma migrate deploy

# Generate Prisma client
npx prisma generate
```

**Note:** 
- Use the **Transaction pooler** connection string (port 6543)
- Replace `[YOUR-PASSWORD]` with your actual database password
- If you don't know your password, reset it in Supabase Dashboard → Settings → Database

---

## 🔑 Step 4: Get Your API Keys

1. Go to Supabase Dashboard → Settings → API
2. Copy these keys:
   - **anon/public key** - This is your publishable key (already have it)
   - **service_role key** - Click "Reveal" to see it (keep this secret!)

---

## ⚙️ Step 5: Set Environment Variables in Supabase

1. Go to Supabase Dashboard → Settings → Edge Functions → Secrets
2. Add these secrets:

   - **Name:** `SUPABASE_URL`
     **Value:** `https://jqfyunukinwglaitjkfr.supabase.co`

   - **Name:** `SUPABASE_ANON_KEY`
     **Value:** `sb_publishable_dSuF2TAFXM8vKN4bHiMpKg_4wUHOnT4`

   - **Name:** `SUPABASE_SERVICE_ROLE_KEY`
     **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZnl1bnVraW53Z2xhaXRqa2ZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzYyNzY4NSwiZXhwIjoyMDgzMjAzNjg1fQ.Nn1JoNRCNLfSBXWYK8svnXetmmGEWRLnZgXCbtXPzLA`

   - **Name:** `APPLE_SHARED_SECRET`
     **Value:** (get from App Store Connect → Your App → App-Specific Shared Secret)
     **Note:** You can add this later when you set up subscriptions

**⚠️ Important:** The service role key is sensitive. Only add it to Supabase secrets, never commit it to git!

---

## 📦 Step 6: Install Supabase CLI

```bash
npm install -g supabase
```

---

## 🔗 Step 7: Link Your Project

```bash
cd /Users/campbellerickson/Desktop/Code/screen-budget
supabase login
supabase link --project-ref jqfyunukinwglaitjkfr
```

---

## 🚀 Step 8: Deploy Edge Functions

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

## ✅ Step 9: Test the Setup

1. **Test Authentication:**
   ```bash
   curl -X POST https://jqfyunukinwglaitjkfr.supabase.co/functions/v1/auth-signup \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"Test1234","name":"Test User"}'
   ```

2. **Test in iOS App:**
   - Build and run the iOS app
   - Try signing up with a test account
   - Verify it connects to Supabase

---

## 📝 Next Steps

1. ✅ Database migrations - Run Step 3
2. ✅ Deploy Edge Functions - Run Step 8
3. ✅ Test authentication - Run Step 9
4. ⏳ Set up Apple Sign In (optional) - Configure in Supabase Dashboard
5. ⏳ Set up App Store subscriptions - Get `APPLE_SHARED_SECRET` when ready

---

## 🐛 Troubleshooting

### "Can't reach database server"
- Make sure you're using the **pooled connection string** (port 6543)
- Not the direct connection string

### "Authentication required" errors
- Make sure you've deployed all Edge Functions
- Check that `SUPABASE_ANON_KEY` is set correctly in Supabase secrets

### Function deployment fails
- Make sure you're logged in: `supabase login`
- Make sure project is linked: `supabase link --project-ref jqfyunukinwglaitjkfr`
- Check that environment variables are set in Supabase Dashboard

---

**Ready to go!** Start with Step 2 (get database connection string) and work through the steps. 🚀

