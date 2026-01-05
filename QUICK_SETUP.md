# ⚡ Quick Setup Reference

**Your Supabase Project Details:**
- **Project URL:** `https://jqfyunukinwglaitjkfr.supabase.co`
- **Database Host:** `db.jqfyunukinwglaitjkfr.supabase.co`
- **Password:** `wHSCHAPS2017!`

---

## 🔗 Connection Strings

### ⚠️ IMPORTANT: Use Connection Pooling (Required for Free Plan)

Since you're on the Free Plan, you **must use the connection pooler** (it supports IPv4). The direct connection won't work.

### Get Pooled Connection String

1. Go to your Supabase project dashboard
2. **Settings** → **Database**
3. Scroll to **"Connection Pooling"** section
4. Click on **"Connection string"** tab
5. Copy the **"Transaction mode"** connection string
6. Replace `[YOUR-PASSWORD]` with `wHSCHAPS2017!`

The pooled connection string should look like:
```env
DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
```

**Use this same pooled connection string for BOTH local development AND Vercel production!**

---

## 🚀 Quick Start

### 1. Set Up Local Environment

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env`:
```env
# Database (Direct connection for local dev)
DATABASE_URL="postgresql://postgres:wHSCHAPS2017!@db.jqfyunukinwglaitjkfr.supabase.co:5432/postgres"

# JWT Secret (generate a new one)
JWT_SECRET="$(openssl rand -base64 32)"

# Server
NODE_ENV="development"
PORT=3000
CORS_ORIGIN="*"
```

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

### 4. Set Up Vercel Environment Variables

When deploying to Vercel, use the **pooled connection string** (port 6543) from Supabase dashboard.

---

## 📝 Next Steps

1. ✅ Database connection configured
2. ⏳ Set up Apple Sign In (see `SETUP_GUIDE.md` Part 2)
3. ⏳ Configure Vercel deployment (see `SETUP_GUIDE.md` Part 3)
4. ⏳ Update iOS app with production URL

---

**⚠️ Security Note:** Never commit `.env` files to git! They're already in `.gitignore`.

