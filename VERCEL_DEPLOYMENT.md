# 🚀 Vercel Deployment Guide

**Last Updated:** January 4, 2026

Complete guide to deploying Screen Budget backend to Vercel.

---

## 📋 Prerequisites

- ✅ GitHub account (campbellerickson)
- ✅ Code pushed to https://github.com/campbellerickson/screen-copilot
- ⏳ Vercel account (free - create at https://vercel.com)
- ⏳ PostgreSQL database (Neon, Supabase, or Railway)

---

## 🗄️ Step 1: Set Up PostgreSQL Database

Since Vercel doesn't provide PostgreSQL, you need a managed database. **Recommended: Neon** (best for serverless)

### Option A: Neon (Recommended for Vercel)

1. Go to https://neon.tech/
2. Sign up with GitHub
3. Create new project: "screen-budget"
4. Copy the connection string:
   ```
   postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb
   ```
5. **Important:** Use the "Pooled connection" string for serverless

### Option B: Railway (Alternative)

1. Go to https://railway.app/
2. Login with GitHub
3. Create new project → Provision PostgreSQL
4. Copy DATABASE_URL from Variables tab

### Option C: Supabase (Alternative)

1. Go to https://supabase.com/
2. Create new project
3. Get connection string from Settings → Database

---

## 🚀 Step 2: Deploy to Vercel

### 2.1: Connect to Vercel

1. Go to https://vercel.com/
2. Sign up/Login with GitHub (use **campbellerickson** account)
3. Click **"Add New Project"**
4. Import your repository: `campbellerickson/screen-copilot`

### 2.2: Configure Project Settings

**Framework Preset:** Other
**Root Directory:** `./` (leave as root)
**Build Command:** `npm run vercel-build`
**Output Directory:** Leave empty
**Install Command:** `npm install`

### 2.3: Environment Variables

Click **"Environment Variables"** and add:

```bash
# Database
DATABASE_URL=postgresql://user:password@your-db-host/database

# Server
NODE_ENV=production
PORT=3000

# Authentication
JWT_SECRET=<generate-strong-secret>

# Apple Sign In
APPLE_BUNDLE_ID=com.campbell.ScreenTimeBudget

# Stripe (optional for now)
STRIPE_SECRET_KEY=sk_test_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_secret

# CORS
CORS_ORIGIN=*
```

**Generate JWT Secret:**
```bash
openssl rand -base64 32
```

### 2.4: Deploy

1. Click **"Deploy"**
2. Wait for deployment (2-3 minutes)
3. You'll get a URL like: `https://screen-copilot.vercel.app`

---

## 🔧 Step 3: Run Database Migrations

After first deployment, run migrations:

1. In Vercel dashboard, go to your project
2. Click **Settings** → **Functions**
3. Install Vercel CLI locally:
   ```bash
   npm install -g vercel
   ```

4. Link to your project:
   ```bash
   cd /Users/campbellerickson/Desktop/Code/screen-budget
   vercel link
   ```

5. Run migrations via Vercel CLI:
   ```bash
   vercel env pull .env.production
   cd backend
   npx prisma migrate deploy
   ```

---

## 📱 Step 4: Update iOS App

Update your iOS app to use the Vercel backend:

**File:** `ios/ScreenTimeBudget/Utilities/Constants.swift`

```swift
struct Constants {
    #if DEBUG
    static let baseURL = "http://192.168.68.50:3000/api/v1"  // Local dev
    #else
    static let baseURL = "https://screen-copilot.vercel.app/api/v1"  // Production
    #endif
}
```

---

## ✅ Step 5: Test Your Deployment

### Test Health Endpoint

```bash
curl https://screen-copilot.vercel.app/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-01-04T...",
  "environment": "production"
}
```

### Test Signup

```bash
curl -X POST https://screen-copilot.vercel.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234",
    "name": "Test User"
  }'
```

---

## 🔄 Continuous Deployment

Vercel automatically deploys when you push to GitHub:

1. Make changes to your code
2. Commit and push:
   ```bash
   git add .
   git commit -m "Update feature"
   git push origin main
   ```
3. Vercel automatically deploys the new version
4. Get instant preview URLs for each deployment

---

## 📊 Monitoring & Logs

### View Logs

1. Go to Vercel dashboard
2. Click your project
3. Click **"Deployments"**
4. Click any deployment
5. Click **"Functions"** tab to see logs

### Real-time Logs

```bash
vercel logs https://screen-copilot.vercel.app --follow
```

---

## 🎯 Custom Domain (Optional)

### Add Your Domain

1. In Vercel dashboard, go to **Settings** → **Domains**
2. Add your domain: `api.screenbudget.com`
3. Update DNS records:
   - Type: `CNAME`
   - Name: `api`
   - Value: `cname.vercel-dns.com`

4. Wait for DNS propagation (5-10 minutes)
5. Update iOS app with new domain

---

## 🔐 Security Best Practices

### Secure Your API

1. **Enable CORS properly:**
   ```bash
   # In Vercel dashboard, update CORS_ORIGIN:
   CORS_ORIGIN=https://your-app-domain.com
   ```

2. **Rotate JWT Secret regularly**
3. **Enable rate limiting** (add to middleware)
4. **Use environment variables** for all secrets
5. **Never commit .env files**

---

## 💰 Pricing

### Vercel Free Tier Includes:
- ✅ Unlimited deployments
- ✅ 100 GB bandwidth/month
- ✅ Serverless functions (100 GB-hours)
- ✅ Custom domains
- ✅ HTTPS automatic

### Database Costs:
- **Neon Free:** 0.5 GB storage, 10 branches
- **Railway:** $5 credit/month, then $0.000463/GB-hour
- **Supabase Free:** 500 MB database, 2 GB bandwidth

**Estimated Monthly Cost:** $0-5 for small scale

---

## 🐛 Troubleshooting

### Build Fails

**Problem:** Vercel build fails

**Solutions:**
1. Check build logs in Vercel dashboard
2. Verify `package.json` has correct scripts:
   ```json
   {
     "scripts": {
       "vercel-build": "cd backend && npm install && npx prisma generate && npm run build"
     }
   }
   ```
3. Make sure TypeScript compiles locally first

### Database Connection Fails

**Problem:** Can't connect to database

**Solutions:**
1. Verify DATABASE_URL is correct in Vercel env vars
2. For Neon: Use **pooled connection string**
3. Check database is accepting connections from Vercel IPs
4. Test connection string locally first

### Prisma Issues

**Problem:** Prisma errors in production

**Solutions:**
1. Run `npx prisma generate` in build step
2. Make sure schema.prisma is included in deployment
3. Run migrations: `npx prisma migrate deploy`

### Function Timeout

**Problem:** Requests timing out

**Solutions:**
1. Increase function timeout in `vercel.json`:
   ```json
   {
     "functions": {
       "api/index.ts": {
         "maxDuration": 30
       }
     }
   }
   ```
2. Note: Free tier max is 10 seconds

---

## 📚 Useful Commands

```bash
# Deploy from CLI
vercel

# Deploy to production
vercel --prod

# View logs
vercel logs

# Pull environment variables
vercel env pull

# Link to project
vercel link

# Remove deployment
vercel remove [deployment-url]
```

---

## 🔄 Migration from Railway

If you set up Railway earlier and want to switch to Vercel:

1. **Export data from Railway database** (if any)
2. **Set up Neon database** (steps above)
3. **Import data to Neon** (using pg_dump/restore)
4. **Deploy to Vercel** (steps above)
5. **Update iOS app** with new Vercel URL
6. **Test everything**
7. **Delete Railway project** (to stop charges)

---

## ✨ Advantages of Vercel

### vs Railway:
- ✅ Better for serverless/edge functions
- ✅ Faster cold starts
- ✅ Automatic HTTPS/CDN
- ✅ Preview deployments for PRs
- ✅ Better developer experience

### vs Heroku:
- ✅ Free tier is better
- ✅ Faster deployments
- ✅ Better scaling
- ✅ Modern developer tools

---

## 🎯 Production Checklist

Before going live:

- [ ] Database deployed (Neon/Railway/Supabase)
- [ ] Migrations run successfully
- [ ] Backend deployed to Vercel
- [ ] Health endpoint returns 200
- [ ] Environment variables configured
- [ ] iOS app updated with production URL
- [ ] Signup/Login tested
- [ ] Subscription endpoints tested
- [ ] Custom domain configured (optional)
- [ ] Monitoring set up
- [ ] Error tracking configured

---

## 🚀 Next Steps

1. ✅ **Right now:** Deploy to Vercel
2. ✅ **Today:** Test all endpoints
3. ⏳ **This week:** Configure custom domain
4. ⏳ **Before launch:** Load testing
5. 🎉 **Launch:** Submit to App Store!

---

**Your backend will be live at:**
`https://screen-copilot.vercel.app`

All API endpoints:
- `https://screen-copilot.vercel.app/health`
- `https://screen-copilot.vercel.app/api/v1/auth/signup`
- `https://screen-copilot.vercel.app/api/v1/auth/login`
- `https://screen-copilot.vercel.app/api/v1/subscription/status`
- etc.

---

**Need help?** Check Vercel docs: https://vercel.com/docs
