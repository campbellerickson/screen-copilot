# ⚡ Quick Setup Reference

**Your Supabase Project Details:**
- **Project URL:** `https://jqfyunukinwglaitjkfr.supabase.co`
- **Database Host:** `db.jqfyunukinwglaitjkfr.supabase.co`
- **Password:** `wHSCHAPS2017!`

---

## ⚠️ CRITICAL: Use Connection Pooling (Required for Vercel)

**Vercel is IPv4-only** and your Supabase Free Plan doesn't support IPv4 direct connections. You **MUST use the connection pooler** for both local development and Vercel.

---

## 🔗 Get Your Pooled Connection String

### Step 1: Navigate to Connection Pooling

1. Go to your Supabase Dashboard: `https://supabase.com/dashboard/project/jqfyunukinwglaitjkfr`
2. Click **Settings** (gear icon) → **Database**
3. Scroll down to **"Connection Pooling"** section
4. You should see **"SHARED POOLER"** configuration

### Step 2: Get the Connection String

1. In the Connection Pooling section, look for **"Connection string"** or **"Connection info"**
2. You should see options for:
   - **Session mode** (for transactions)
   - **Transaction mode** (for serverless - **USE THIS ONE**)
3. Copy the **Transaction mode** connection string
4. It should look like:
   ```
   postgresql://postgres.jqfyunukinwglaitjkfr:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```
5. Replace `[YOUR-PASSWORD]` with `wHSCHAPS2017!`

### Step 3: Format for Environment Variable

Your final connection string should be:
```env
DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
```

**Key differences from direct connection:**
- Uses `postgres.jqfyunukinwglaitjkfr` (with dot) instead of `postgres`
- Uses `pooler.supabase.com` instead of `db.xxxxx.supabase.co`
- Uses port **6543** instead of 5432
- Includes `?pgbouncer=true&connection_limit=1` parameters

---

## 🚀 Quick Start

### 1. Update Local Environment

```bash
cd backend
```

Edit `backend/.env`:
```env
# Database (USE POOLED CONNECTION - Required for Vercel compatibility)
DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"

# JWT Secret (already generated)
JWT_SECRET="your-generated-secret"

# Server
NODE_ENV="development"
PORT=3000
CORS_ORIGIN="*"
```

**⚠️ Important:** Replace the region (`us-east-1`) and exact pooler URL with what you see in Supabase!

### 2. Install Dependencies & Run Migrations

```bash
cd backend
npm install
npx prisma generate
npx prisma db push
```

### 3. Test Connection

```bash
npm run dev
```

Visit: `http://localhost:3000/health`

### 4. Use Same Connection String for Vercel

When setting up Vercel environment variables, use the **exact same pooled connection string** from Step 3 above.

---

## 📝 Finding the Exact Pooled Connection String

If you can't find it in the UI:

1. **Method 1: Supabase Dashboard**
   - Settings → Database → Connection Pooling
   - Look for "Connection string" section
   - Copy the "Transaction mode" string

2. **Method 2: Connection Info Tab**
   - Settings → Database → Connection string tab
   - Look for "Connection Pooling" section
   - Copy the pooled connection string

3. **Method 3: Construct It**
   - Format: `postgresql://postgres.[project-ref]:[password]@[pooler-host]:6543/postgres`
   - Your project ref: `jqfyunukinwglaitjkfr`
   - Your password: `wHSCHAPS2017!`
   - Pooler host: Usually `aws-0-[region].pooler.supabase.com`
   - Region: Check your project settings (might be `us-east-1`, `us-west-1`, etc.)

---

## 🔍 Troubleshooting

### "Can't reach database server" Error

- ✅ Make sure you're using the **pooled connection** (port 6543)
- ✅ Check the pooler host matches your region
- ✅ Verify password is correct: `wHSCHAPS2017!`
- ✅ Ensure project is active in Supabase

### Connection Timeout

- ✅ Verify you're using port **6543** (pooler), not 5432 (direct)
- ✅ Check the pooler host URL is correct
- ✅ Make sure `?pgbouncer=true&connection_limit=1` is included

---

## 📚 Next Steps

1. ✅ Get pooled connection string from Supabase
2. ✅ Update `backend/.env` with pooled connection
3. ✅ Run migrations: `npx prisma db push`
4. ⏳ Set up Apple Sign In (see `SETUP_GUIDE.md` Part 2)
5. ⏳ Configure Vercel deployment (see `SETUP_GUIDE.md` Part 3)

---

**⚠️ Security Note:** Never commit `.env` files to git! They're already in `.gitignore`.
