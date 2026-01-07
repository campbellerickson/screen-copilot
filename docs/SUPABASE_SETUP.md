# 🗄️ Supabase Database Setup Guide

**Last Updated:** January 4, 2026  
Complete guide to setting up Supabase databases for development and production.

---

## 📋 Overview

This guide walks you through:
1. Creating Supabase accounts and projects
2. Setting up development and production databases
3. Configuring connection pooling (required for Vercel serverless)
4. Running database migrations
5. Setting up environment variables

---

## 🚀 Step 1: Create Supabase Account

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"Sign Up"**
3. Sign up with GitHub, Google, or email
4. Verify your email if required

---

## 🏗️ Step 2: Create Development Database

1. **Create New Project**
   - Click **"New Project"** in your dashboard
   - Name: `screen-budget-dev` (or your preferred name)
   - Database Password: Generate a strong password (save it!)
   - Region: Choose closest to you (e.g., `US East (Ohio)`)
   - Pricing Plan: Free tier is fine for development

2. **Wait for Database Setup** (2-3 minutes)
   - Wait for the project to finish provisioning
   - You'll see "Database is ready" when complete

3. **Get Connection String**
   - Go to **Settings** → **Database**
   - Scroll to **Connection string**
   - Copy the **Connection pooling** URI (important!)
   - It should look like:
     ```
     postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true
     ```

4. **Save Connection String**
   - Save this for Step 4 (Environment Variables)

---

## 🏭 Step 3: Create Production Database

1. **Create New Project**
   - Click **"New Project"** again
   - Name: `screen-budget-prod`
   - Database Password: Generate a different strong password
   - Region: Same as dev (for consistency) or choose production region
   - Pricing Plan: Choose based on expected traffic

2. **Wait for Database Setup**

3. **Get Connection String**
   - Same steps as development
   - Save the **Connection pooling** URI

---

## 🔧 Step 4: Configure Connection Pooling

⚠️ **Important:** Vercel serverless functions require connection pooling!

Supabase provides two types of connection strings:

### Direct Connection (❌ Don't use with Vercel)
```
postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres
```
- Direct connection
- Limited to ~100 connections
- Not suitable for serverless

### Connection Pooling (✅ Use with Vercel)
```
postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1
```
- Pooled connection via PgBouncer
- Handles thousands of concurrent connections
- Perfect for serverless functions
- Port: **6543** (pooler) instead of 5432

**Use the pooling connection string for both dev and prod!**

---

## 📦 Step 5: Run Database Migrations

### Option A: Using Prisma Migrate (Recommended)

1. **Set Environment Variable**
   ```bash
   cd backend
   export DATABASE_URL="your-pooling-connection-string-here"
   ```

2. **Run Migrations**
   ```bash
   npx prisma migrate deploy
   ```

   This will create all tables based on `backend/prisma/schema.prisma`

3. **Verify Tables**
   ```bash
   npx prisma studio
   ```
   - Opens Prisma Studio in browser
   - Verify all tables are created

### Option B: Using Supabase SQL Editor

1. **Get Migration SQL**
   - Go to your Supabase project
   - Navigate to **SQL Editor**
   - Open `backend/prisma/migrations/[latest-migration]/migration.sql`
   - Copy the SQL content

2. **Run in SQL Editor**
   - Paste the SQL into Supabase SQL Editor
   - Click **"Run"**
   - Verify tables are created in **Table Editor**

### Repeat for Production

- Run the same migration steps for your production database

---

## 🔐 Step 6: Environment Variables

### Development (.env)

Create `backend/.env`:

```bash
# Database (Development - Supabase Pooling)
DATABASE_URL="postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"

# JWT Secret (generate a secure random string)
JWT_SECRET="your-dev-jwt-secret-here"

# Server
NODE_ENV="development"
PORT=3000
CORS_ORIGIN="http://localhost:3000"

# Apple Developer (we'll set these later)
APPLE_BUNDLE_ID="com.campbell.ScreenTimeBudget"
APPLE_CLIENT_ID="your.apple.service.id"
APPLE_TEAM_ID="YOUR_APPLE_TEAM_ID"
APPLE_KEY_ID="YOUR_APPLE_KEY_ID"
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APPLE_SHARED_SECRET="your-apple-shared-secret"

# Frontend
FRONTEND_URL="http://localhost:3000"
```

### Production (Vercel Environment Variables)

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Add each variable:

   | Key | Value | Environment |
   |-----|-------|-------------|
   | `DATABASE_URL` | Your production pooling connection string | Production |
   | `JWT_SECRET` | Generate secure random string | Production |
   | `NODE_ENV` | `production` | Production |
   | `CORS_ORIGIN` | Your Vercel app URL | Production |
   | `APPLE_BUNDLE_ID` | Your bundle ID | Production |
   | `APPLE_CLIENT_ID` | Your Apple service ID | Production |
   | `APPLE_TEAM_ID` | Your Apple Team ID | Production |
   | `APPLE_KEY_ID` | Your Apple Key ID | Production |
   | `APPLE_PRIVATE_KEY` | Your Apple private key | Production |
   | `APPLE_SHARED_SECRET` | Your App Store Connect shared secret | Production |
   | `FRONTEND_URL` | Your Vercel app URL | Production |

5. **Important:** For `APPLE_PRIVATE_KEY`, replace newlines with `\n`:
   ```
   -----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----
   ```

---

## ✅ Step 7: Verify Setup

### Test Development Database

1. **Test Connection**
   ```bash
   cd backend
   npm run dev
   ```

2. **Check Health Endpoint**
   ```bash
   curl http://localhost:3000/health
   ```

3. **Test Database Query**
   ```bash
   npx prisma studio
   ```
   - Should open and show all tables

### Test Production Database (After Vercel Deploy)

1. **Deploy to Vercel**
   ```bash
   vercel --prod
   ```

2. **Check Health Endpoint**
   ```bash
   curl https://your-app.vercel.app/health
   ```

3. **Check Vercel Logs**
   - Go to Vercel Dashboard → Your Project → Logs
   - Look for any database connection errors

---

## 🔍 Troubleshooting

### "Too many connections" Error

- ✅ Make sure you're using the **pooling connection string** (port 6543)
- ✅ Add `&connection_limit=1` to connection string
- ✅ Verify `pgbouncer=true` is in the connection string

### Connection Timeout

- ✅ Check your Supabase project is active
- ✅ Verify connection string is correct
- ✅ Check network/firewall settings

### Migration Errors

- ✅ Ensure database is fully provisioned
- ✅ Check connection string has correct password
- ✅ Verify Prisma schema is valid: `npx prisma validate`

### Prisma Client Not Generated

- ✅ Run `npx prisma generate` manually
- ✅ Check `backend/node_modules/.prisma` exists
- ✅ Verify `DATABASE_URL` is set correctly

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Connection Pooling Guide](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
- [Prisma + Supabase Guide](https://www.prisma.io/docs/guides/deployment/deployment-guides/deploying-to-vercel)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)

---

## 🎯 Next Steps

1. ✅ Set up Apple Developer account (see `APPLE_SETUP.md`)
2. ✅ Configure Vercel deployment (see `VERCEL_DEPLOYMENT.md`)
3. ✅ Test authentication flow
4. ✅ Test subscription flow
5. ✅ Deploy to production!

---

**Your databases are ready!** 🎉

