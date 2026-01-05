# ✅ Deployment Checklist

**Last Updated:** January 4, 2026  
Complete checklist for deploying Screen Budget to production.

---

## 📋 Pre-Deployment

### GitHub Repository
- [ ] Repository created: `https://github.com/campbellerickson/screen-copilot`
- [ ] Code pushed to `main` branch
- [ ] All changes committed
- [ ] README.md updated

### Supabase Databases

#### Development Database
- [ ] Supabase account created
- [ ] Development project created
- [ ] Connection pooling URL obtained (port 6543)
- [ ] Migration run successfully
- [ ] Tables verified in Prisma Studio
- [ ] `.env` file created with dev DATABASE_URL

#### Production Database
- [ ] Production project created
- [ ] Connection pooling URL obtained (port 6543)
- [ ] Migration run successfully
- [ ] Tables verified
- [ ] Production DATABASE_URL saved (for Vercel)

### Apple Developer Setup
- [ ] Apple Developer account enrolled ($99/year)
- [ ] App ID created: `com.campbell.ScreenTimeBudget`
- [ ] Sign In with Apple enabled on App ID
- [ ] Services ID created: `com.campbell.ScreenTimeBudget.backend`
- [ ] Services ID configured with return URLs
- [ ] Private key created and downloaded (`.p8`)
- [ ] Key ID noted
- [ ] Team ID noted
- [ ] App Store Connect app created
- [ ] In-App Purchase subscription created:
  - Product ID: `com.campbell.ScreenTimeBudget.premium.monthly`
  - Price: $0.99/month
  - Free Trial: 7 days
- [ ] App-Specific Shared Secret generated
- [ ] All Apple credentials documented securely

### Environment Variables

#### Local Development
- [ ] `backend/.env` created
- [ ] `DATABASE_URL` set (dev Supabase pooling URL)
- [ ] `JWT_SECRET` set (secure random string)
- [ ] `NODE_ENV=development`
- [ ] `CORS_ORIGIN=http://localhost:3000`
- [ ] Apple variables set:
  - `APPLE_BUNDLE_ID`
  - `APPLE_CLIENT_ID`
  - `APPLE_TEAM_ID`
  - `APPLE_KEY_ID`
  - `APPLE_PRIVATE_KEY` (with `\n` newlines)
  - `APPLE_SHARED_SECRET`

#### Production (Vercel)
- [ ] Vercel account connected
- [ ] Project created in Vercel
- [ ] GitHub repository connected
- [ ] All environment variables added to Vercel:
  - `DATABASE_URL` (prod Supabase pooling URL)
  - `JWT_SECRET` (different from dev!)
  - `NODE_ENV=production`
  - `CORS_ORIGIN` (your Vercel URL)
  - `APPLE_BUNDLE_ID`
  - `APPLE_CLIENT_ID`
  - `APPLE_TEAM_ID`
  - `APPLE_KEY_ID`
  - `APPLE_PRIVATE_KEY` (with `\n` newlines)
  - `APPLE_SHARED_SECRET`
  - `FRONTEND_URL` (your Vercel URL)

---

## 🚀 Deployment Steps

### Step 1: Database Migration (Production)
- [ ] Run migrations against production database:
  ```bash
  export DATABASE_URL="your-production-database-url"
  cd backend
  npx prisma migrate deploy
  ```
- [ ] Verify migration status: `npx prisma migrate status`
- [ ] Verify tables exist in Supabase dashboard

### Step 2: Deploy to Vercel
- [ ] Install Vercel CLI: `npm i -g vercel`
- [ ] Login: `vercel login`
- [ ] Link project: `vercel link`
- [ ] Deploy to production: `vercel --prod`
- [ ] Note deployment URL

### Step 3: Update Environment Variables
- [ ] Update `CORS_ORIGIN` in Vercel to deployment URL
- [ ] Update `FRONTEND_URL` in Vercel to deployment URL
- [ ] Redeploy if needed: `vercel --prod`

---

## ✅ Post-Deployment Verification

### API Health Check
- [ ] Health endpoint works:
  ```bash
  curl https://your-app.vercel.app/health
  ```
- [ ] Response includes: `{ "status": "ok" }`

### Database Connection
- [ ] Check Vercel logs for database connection errors
- [ ] Verify no "connection timeout" errors
- [ ] Verify using connection pooling (port 6543)

### Authentication Endpoints
- [ ] Test signup endpoint:
  ```bash
  curl -X POST https://your-app.vercel.app/api/v1/auth/signup \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"Test123!"}'
  ```
- [ ] Test login endpoint
- [ ] Test Apple Sign In endpoint (if configured)

### Subscription Endpoints
- [ ] Test subscription status endpoint (requires auth token)
- [ ] Test receipt validation endpoint (requires auth token)

---

## 📱 iOS App Configuration

### Update API URL
- [ ] Update `APIService.swift` with production URL:
  ```swift
  static let baseURL = "https://your-app.vercel.app/api/v1"
  ```
- [ ] Verify API calls work in iOS app
- [ ] Test authentication flow
- [ ] Test subscription flow

### Xcode Configuration
- [ ] Bundle ID matches: `com.campbell.ScreenTimeBudget`
- [ ] Sign In with Apple capability enabled
- [ ] Team selected correctly
- [ ] Code signing configured

### StoreKit Configuration
- [ ] StoreKit config file created (for testing)
- [ ] Product ID matches: `com.campbell.ScreenTimeBudget.premium.monthly`
- [ ] Subscription configured with 7-day trial

---

## 🧪 Testing

### Local Testing
- [ ] Backend runs locally: `npm run dev`
- [ ] Database connection works
- [ ] All API endpoints respond
- [ ] Authentication flow works
- [ ] Subscription flow works (test mode)

### Sandbox Testing
- [ ] Sandbox test account created in App Store Connect
- [ ] Sign In with Apple tested with sandbox account
- [ ] Subscription purchase tested with sandbox account
- [ ] Receipt validation works in sandbox

### Production Testing (After Deploy)
- [ ] Health endpoint accessible
- [ ] API endpoints accessible
- [ ] No CORS errors
- [ ] Authentication works
- [ ] Database queries work
- [ ] Error handling works
- [ ] Logs are readable in Vercel dashboard

---

## 🔐 Security Checklist

- [ ] `JWT_SECRET` is secure random string (different for prod!)
- [ ] Database passwords are strong
- [ ] Apple private key stored securely (not in code!)
- [ ] Environment variables not committed to git
- [ ] `.env` files in `.gitignore`
- [ ] API rate limiting considered (future enhancement)
- [ ] HTTPS enabled (automatic with Vercel)
- [ ] CORS configured correctly
- [ ] Helmet security headers enabled (already in code)

---

## 📊 Monitoring Setup

- [ ] Vercel dashboard accessible
- [ ] Error logs monitored
- [ ] Performance metrics checked
- [ ] Database usage monitored in Supabase
- [ ] Consider setting up:
  - Sentry for error tracking (optional)
  - Analytics (optional)
  - Uptime monitoring (optional)

---

## 📚 Documentation

- [ ] `README.md` updated with setup instructions
- [ ] `SUPABASE_SETUP.md` created
- [ ] `APPLE_SETUP.md` created
- [ ] `VERCEL_DEPLOYMENT.md` created (or exists)
- [ ] `VERCEL_MIGRATION.md` created
- [ ] Environment variables documented
- [ ] API endpoints documented (if needed)

---

## 🎯 Final Steps

### Before Launch
- [ ] All checklist items completed
- [ ] All tests passing
- [ ] Production database backed up
- [ ] Rollback plan prepared (optional)
- [ ] Team notified of deployment

### Launch Day
- [ ] Deploy to production: `vercel --prod`
- [ ] Verify deployment success
- [ ] Test critical paths:
  - User signup
  - User login
  - Apple Sign In
  - Subscription purchase
  - Receipt validation
- [ ] Monitor error logs
- [ ] Monitor performance
- [ ] Announce launch! 🎉

---

## 🔄 Post-Launch

- [ ] Monitor error rates
- [ ] Monitor subscription conversions
- [ ] Monitor user signups
- [ ] Review Vercel analytics
- [ ] Review Supabase usage
- [ ] Plan for scaling (if needed)
- [ ] Gather user feedback
- [ ] Plan next features

---

**Everything is ready for deployment!** 🚀

