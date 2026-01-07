# 🔗 Vercel + Supabase Connection Setup

## ⚠️ The Problem

**Vercel is IPv4-only** and Supabase Free Plan doesn't support IPv4 direct connections. You **MUST use connection pooling**.

---

## ✅ The Solution: Connection Pooling

Use Supabase's **connection pooler** which supports IPv4 and works perfectly with Vercel.

---

## 📋 Step-by-Step: Get Your Pooled Connection String

### 1. Navigate to Connection Pooling Settings

1. Go to: `https://supabase.com/dashboard/project/jqfyunukinwglaitjkfr/settings/database`
2. Scroll down to **"Connection Pooling"** section
3. You should see **"SHARED POOLER"** configuration

### 2. Find the Connection String

Look for one of these:
- **"Connection string"** tab or section
- **"Connection info"** section
- **"Transaction mode"** connection string

### 3. Copy the Transaction Mode String

The connection string should look like:
```
postgresql://postgres.jqfyunukinwglaitjkfr:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

### 4. Replace Password

Replace `[YOUR-PASSWORD]` with: `wHSCHAPS2017!`

### 5. Add Parameters

Add these parameters at the end:
```
?pgbouncer=true&connection_limit=1
```

### 6. Final Connection String

Your final connection string should be:
```env
DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
```

**Replace `[REGION]` with your actual region** (e.g., `us-east-1`, `us-west-1`, `eu-west-1`)

---

## 🔍 How to Find Your Region

1. In Supabase Dashboard → **Settings** → **General**
2. Look for **"Region"** or **"Database Region"**
3. Common regions:
   - `us-east-1` (US East - N. Virginia)
   - `us-west-1` (US West - N. California)
   - `eu-west-1` (EU - Ireland)
   - `ap-southeast-1` (Asia - Singapore)

---

## 📝 Where to Use This Connection String

### 1. Local Development (`backend/.env`)

```env
DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
```

### 2. Vercel Environment Variables

1. Go to Vercel Dashboard → Your Project → **Settings** → **Environment Variables**
2. Add new variable:
   - **Name:** `DATABASE_URL`
   - **Value:** (paste your pooled connection string)
   - **Environment:** Production, Preview, Development (select all)
3. Click **Save**

---

## ✅ Verify It Works

### Test Locally

```bash
cd backend
npm run dev
```

Visit: `http://localhost:3000/health`

Should return:
```json
{
  "status": "ok",
  "timestamp": "...",
  "environment": "development"
}
```

### Test on Vercel

After deploying, visit: `https://your-app.vercel.app/health`

---

## 🔍 Troubleshooting

### "Can't reach database server"

- ✅ Check you're using port **6543** (not 5432)
- ✅ Verify the pooler host URL is correct
- ✅ Make sure `?pgbouncer=true&connection_limit=1` is included
- ✅ Check your region is correct

### "Too many connections"

- ✅ Verify `connection_limit=1` is in the connection string
- ✅ Check you're using the pooled connection (not direct)

### Connection Timeout

- ✅ Verify project is active in Supabase
- ✅ Check the pooler host matches your region
- ✅ Ensure password is correct: `wHSCHAPS2017!`

---

## 📚 Key Differences

| Feature | Direct Connection | Pooled Connection |
|---------|-------------------|-------------------|
| **Port** | 5432 | 6543 |
| **Host** | `db.xxxxx.supabase.co` | `pooler.supabase.com` |
| **Username** | `postgres` | `postgres.xxxxx` |
| **Vercel Compatible** | ❌ No | ✅ Yes |
| **IPv4 Support** | ❌ No (Free Plan) | ✅ Yes |

---

## 🎯 Quick Reference

**Your Project Details:**
- Project Ref: `jqfyunukinwglaitjkfr`
- Password: `wHSCHAPS2017!`
- Pooler Format: `postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1`

**Next Steps:**
1. Get pooled connection string from Supabase
2. Update `backend/.env` with pooled connection
3. Add same connection string to Vercel environment variables
4. Test connection locally
5. Deploy to Vercel and test

---

**You're all set!** 🎉

