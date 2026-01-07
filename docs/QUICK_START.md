# ⚡ Quick Start

Fastest path to get Screen Budget running.

## ✅ Prerequisites
- Supabase project created
- Service role key obtained
- Database connection string ready

## 🚀 Setup Steps (In Order)

### 1. Get Your Database Password
If you don't know your database password:
- Go to Supabase Dashboard → Settings → Database
- Click "Reset database password"
- Copy the new password

### 2. Run Database Migrations
```bash
cd backend

# Replace [YOUR-PASSWORD] with your actual database password
export DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:[YOUR-PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres"

# Run migrations
npx prisma migrate deploy

# Generate Prisma client
npx prisma generate
```

### 3. Set Environment Variables in Supabase
Go to: **Supabase Dashboard → Settings → Edge Functions → Secrets**

Add these secrets:

| Name | Value |
|------|-------|
| `SUPABASE_URL` | `https://jqfyunukinwglaitjkfr.supabase.co` |
| `SUPABASE_ANON_KEY` | `sb_publishable_dSuF2TAFXM8vKN4bHiMpKg_4wUHOnT4` |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZnl1bnVraW53Z2xhaXRqa2ZyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzYyNzY4NSwiZXhwIjoyMDgzMjAzNjg1fQ.Nn1JoNRCNLfSBXWYK8svnXetmmGEWRLnZgXCbtXPzLA` |

### 4. Install & Link Supabase CLI
```bash
npm install -g supabase
supabase login
supabase link --project-ref jqfyunukinwglaitjkfr
```

### 5. Deploy All Edge Functions
```bash
supabase functions deploy
```

This will deploy all 18 Edge Functions at once.

### 6. Test It!
```bash
# Test signup
curl -X POST https://jqfyunukinwglaitjkfr.supabase.co/functions/v1/auth-signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234","name":"Test User"}'
```

---

## 🎯 You're Ready!

Once you complete steps 1-5, your backend will be fully deployed and ready to use!

**Need help?** Check `SETUP_STEPS.md` for detailed troubleshooting.

