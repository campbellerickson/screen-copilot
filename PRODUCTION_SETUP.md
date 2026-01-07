# 🚀 Production Setup Guide: Database + Auth + App Store

Complete guide to set up production infrastructure for App Store submission.

---

## 🎯 **What We're Building**

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS APP (App Store)                       │
│  • Screen Time tracking                                     │
│  • Apple Sign In (primary auth method)                      │
│  • Email/Password (fallback)                                │
│  • StoreKit subscriptions                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ HTTPS/REST API
                        │ Bearer JWT token
                        │
                        ▼
        ┌───────────────────────────────┐
        │      VERCEL SERVERLESS        │
        │   (your-app.vercel.app)       │
        │                               │
        │  • JWT authentication         │
        │  • Apple Sign In validation   │
        │  • Receipt validation         │
        │  • Usage tracking API         │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │      NEON POSTGRESQL          │
        │   (Serverless Database)       │
        │                               │
        │  • Users table                │
        │  • Subscriptions              │
        │  • Screen time data           │
        └───────────────────────────────┘
```

---

## 📋 **Prerequisites**

Before starting, you need:
- ✅ GitHub account (you have this)
- ✅ Apple Developer Account ($99/year) - **REQUIRED for App Store**
- ⬜ Vercel account (free)
- ⬜ Neon account (free)

---

## 🗄️ **STEP 1: Set Up Production Database (Neon)**

### **1.1 Create Neon Account**

1. Go to https://neon.tech
2. Click "Sign Up"
3. Choose "Sign up with GitHub" (easiest)
4. Authorize Neon to access your GitHub

### **1.2 Create Project**

```
1. Click "Create Project"
2. Project name: "screen-copilot-prod"
3. Database name: "screenbudget"
4. Region: Choose closest to your users
   - US: us-east-2 (Ohio) or us-west-2 (Oregon)
   - Europe: eu-central-1 (Frankfurt)
5. Click "Create Project"
```

### **1.3 Get Connection String**

After creation, you'll see a connection string like:

```
postgresql://neondb_owner:AbCd1234XyZ@ep-cool-meadow-123456.us-east-2.aws.neon.tech/screenbudget?sslmode=require
```

**IMPORTANT**: Copy this immediately! It contains your password.

Save it somewhere secure (password manager, encrypted notes).

### **1.4 Run Database Migrations**

1. In Neon dashboard, click "SQL Editor"
2. Click "New Query"
3. Copy contents of your `backend/ALL_MIGRATIONS.sql` file
4. Paste into SQL Editor
5. Click "Run"

You should see:
```
✅ 12 tables created
✅ Indexes created
✅ Foreign keys added
```

### **1.5 Verify Tables**

In SQL Editor, run:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';
```

You should see:
```
users
subscriptions
screen_time_budgets
category_budgets
user_apps
daily_app_usage
budget_alerts
streaks
achievements
weekly_goals
break_reminders
```

✅ **Database is ready!**

---

## 🚀 **STEP 2: Deploy Backend to Vercel**

### **2.1 Create Vercel Account**

1. Go to https://vercel.com
2. Click "Sign Up"
3. Choose "Continue with GitHub"
4. Authorize Vercel

### **2.2 Import GitHub Repository**

```
1. Click "Add New..." → "Project"
2. Find "screen-copilot" repository
3. Click "Import"
```

### **2.3 Configure Project**

```
Root Directory: backend
Framework Preset: Other
Build Command: npm run build
Output Directory: dist
Install Command: npm install
```

### **2.4 Add Environment Variables**

**CRITICAL**: Click "Environment Variables" and add these:

```bash
# Database (from Neon)
DATABASE_URL="postgresql://neondb_owner:YOUR_PASSWORD@ep-xxx.us-east-2.aws.neon.tech/screenbudget?sslmode=require"

# Auth - Generate a strong secret
JWT_SECRET="<GENERATE_THIS>"

# Node
NODE_ENV="production"

# CORS - Allow all origins for mobile apps
CORS_ORIGIN="*"

# Apple Sign In
APPLE_BUNDLE_ID="com.campbell.ScreenTimeCopilot"
```

### **2.5 Generate JWT Secret**

Run this in your terminal:
```bash
openssl rand -base64 64
```

Copy the output and use it as `JWT_SECRET`.

Example output:
```
xK8n2pQ7vM4jR9wL3eT6fY1hS5dG0bN8aU4cV7iZ2oX1qW3rE5tY7uI9oP0aS2dF4gH6jK8lZ0xC3vB5nM7qW9eR1tY3uI5oP7aS9dF1gH3jK5l==
```

### **2.6 Deploy**

1. Click "Deploy"
2. Wait 1-2 minutes for build
3. You'll get a URL like: `https://screen-copilot-xxx.vercel.app`

### **2.7 Test Deployment**

```bash
# Health check
curl https://your-app.vercel.app/health

# Expected response:
{
  "status": "ok",
  "timestamp": "2026-01-07T...",
  "environment": "production"
}
```

✅ **Backend is live!**

---

## 🍎 **STEP 3: Configure Apple Sign In**

### **3.1 Create App ID**

1. Go to https://developer.apple.com/account
2. Navigate to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" → "+" button

```
Platform: iOS
Description: Screen Time Copilot
Bundle ID: com.campbell.ScreenTimeCopilot (Explicit)

Capabilities:
✅ Sign In with Apple
✅ Push Notifications
✅ App Groups
✅ Family Sharing

App Groups:
- group.com.campbell.ScreenTimeCopilot
```

4. Click "Continue" → "Register"

### **3.2 Create Services ID (for Web Auth)**

This allows your backend to validate Apple tokens.

1. In Identifiers, click "+" again
2. Select "Services IDs"

```
Description: Screen Time Copilot Auth
Identifier: com.campbell.ScreenTimeCopilot.auth

✅ Sign In with Apple
Click "Configure"

Primary App ID: com.campbell.ScreenTimeCopilot

Domains and Subdomains:
your-app.vercel.app

Return URLs:
https://your-app.vercel.app/api/v1/auth/apple/callback
```

3. Save and Continue

### **3.3 Create Key for Server-Side Validation**

1. Go to "Keys" → "+" button

```
Key Name: Screen Time Copilot Auth Key

✅ Sign In with Apple
Click "Configure"
Select Primary App ID: com.campbell.ScreenTimeCopilot
```

2. Click "Continue" → "Register"
3. **Download the .p8 file** (you can only download ONCE!)
4. Note the **Key ID** (looks like: ABC123DEF4)

### **3.4 Get Team ID**

1. In Apple Developer Account, top right corner
2. You'll see your name → click it
3. Note your **Team ID** (looks like: 5XYZ12ABC3)

### **3.5 Add Apple Credentials to Vercel**

Go back to Vercel dashboard → Your project → Settings → Environment Variables

Add these:

```bash
# Apple Sign In Configuration
APPLE_KEY_ID="ABC123DEF4"
APPLE_TEAM_ID="5XYZ12ABC3"
APPLE_BUNDLE_ID="com.campbell.ScreenTimeCopilot"
APPLE_SERVICES_ID="com.campbell.ScreenTimeCopilot.auth"

# Apple Private Key (from .p8 file)
# Open the .p8 file in a text editor and copy EVERYTHING
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
[copy the entire key including BEGIN and END lines]
-----END PRIVATE KEY-----"
```

**IMPORTANT**: For `APPLE_PRIVATE_KEY`, copy the entire contents of the .p8 file including the BEGIN and END lines. In Vercel, it will preserve newlines.

### **3.6 Redeploy Backend**

In Vercel dashboard:
1. Go to "Deployments"
2. Click the three dots on latest deployment
3. Click "Redeploy"

This picks up the new Apple environment variables.

---

## 💳 **STEP 4: Configure App Store Subscriptions**

### **4.1 Create App Store Connect App**

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"

```
Platform: iOS
Name: Screen Time Copilot
Primary Language: English (U.S.)
Bundle ID: com.campbell.ScreenTimeCopilot (from dropdown)
SKU: screentimecopilot (unique identifier)
```

3. Click "Create"

### **4.2 Set Up In-App Purchases**

1. In your app, go to "Monetization" → "Subscriptions"
2. Click "Create Subscription Group"

```
Reference Name: Screen Time Copilot Premium
```

3. Click "Create"

### **4.3 Create Monthly Subscription**

1. In the subscription group, click "+" to add subscription
2. Configure:

```
Reference Name: Monthly Premium
Product ID: com.campbell.screentimecopilot.monthly

Subscription Duration: 1 Month
Subscription Prices:
- USA: $4.99/month
- (Add other countries as needed)

Introductory Offer:
Type: Free Trial
Duration: 1 Week
```

3. Add localized descriptions:

```
Display Name: Premium
Description: Unlock unlimited screen time tracking and insights.

Features:
• Unlimited app tracking
• Daily and monthly budgets
• Smart notifications
• Weekly insights
• Break reminders
```

4. Save

### **4.4 Configure Server Notifications (Optional but Recommended)**

This lets Apple notify your backend when subscriptions renew/cancel.

1. Go to app → "General" → "App Information"
2. Scroll to "Server Notifications"
3. Add URL:

```
https://your-app.vercel.app/api/v1/subscription/apple-webhook
```

4. Version: Version 2 Notifications

**Note**: You'll need to implement this endpoint in your backend (currently webhook is for Stripe only). For now, you can skip this and validate receipts on each app launch instead.

### **4.5 Add Sandbox Test Users**

For testing before App Store approval:

1. Go to https://appstoreconnect.apple.com
2. "Users and Access" → "Sandbox" → "Testers"
3. Click "+" to add tester

```
Email: test1@yourdomain.com (can be fake)
Password: Test1234!
Country: United States
```

You can create multiple test accounts.

---

## 📱 **STEP 5: Configure iOS App**

### **5.1 Update API URL**

Open `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
struct Constants {
    // API Configuration
    #if DEBUG
    // Local development
    static let baseURL = "http://localhost:3000/api/v1"
    #else
    // Production - YOUR VERCEL URL
    static let baseURL = "https://your-app.vercel.app/api/v1"
    #endif

    // ... rest stays the same
}
```

**Replace** `your-app.vercel.app` with your actual Vercel URL.

### **5.2 Update Bundle ID in Xcode**

1. Open `ios/ScreenTimeBudget.xcodeproj` in Xcode
2. Select project in left sidebar
3. Select "ScreenTimeBudget" target
4. General tab:
   - Bundle Identifier: `com.campbell.ScreenTimeCopilot`
   - Version: `1.0`
   - Build: `1`

### **5.3 Configure Signing & Capabilities**

1. Still in General tab
2. "Signing & Capabilities" section
3. Team: Select your Apple Developer team
4. Automatically manage signing: ✅ Checked

Xcode will automatically create provisioning profiles.

### **5.4 Enable Required Capabilities**

Click "+ Capability" and add:

```
✅ Sign in with Apple
✅ Push Notifications (for budget alerts)
✅ App Groups
   - group.com.campbell.ScreenTimeCopilot
✅ Family Sharing (optional, for family subscriptions)
```

### **5.5 Update StoreKit Product ID**

Open `ios/ScreenTimeBudget/Services/StoreKitManager.swift`:

```swift
class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()

    // Product ID - MUST match App Store Connect
    private let monthlySubscriptionID = "com.campbell.screentimecopilot.monthly"

    // ... rest stays the same
}
```

### **5.6 Add App Store Connect API Key (Optional)**

For StoreKit 2 and TestFlight:

1. In Xcode, select your project
2. Editor → Add Package Dependencies
3. Search for: `https://github.com/apple/app-store-server-library-swift`
4. Add to project

This enables receipt validation without sending receipts to your backend.

---

## 🧪 **STEP 6: Test Everything**

### **6.1 Test Local Backend → Production DB**

Update `backend/.env.local`:

```bash
# Point local backend to production database
DATABASE_URL="postgresql://neondb_owner:...@ep-xxx.us-east-2.aws.neon.tech/screenbudget?sslmode=require"
JWT_SECRET="your-production-secret"
NODE_ENV=development
CORS_ORIGIN=*
```

Start local backend:
```bash
cd backend
npm run dev
```

Test signup:
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!",
    "name": "Test User"
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "test@example.com", "name": "Test User" },
    "token": "eyJhbGciOi...",
    "subscription": { "status": "trial", "hasAccess": true, "daysRemaining": 7 }
  }
}
```

✅ If you see this, your backend → database connection works!

### **6.2 Test Production Backend**

Same test, but against Vercel:

```bash
curl -X POST https://your-app.vercel.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@example.com",
    "password": "Test1234!",
    "name": "Test User 2"
  }'
```

✅ Should get the same response format.

### **6.3 Test iOS App (Local Backend)**

1. Open Xcode
2. Change scheme to "Debug"
3. Constants.swift will use `localhost:3000`
4. Run on iOS Simulator
5. Try signup → should create account in production DB
6. Try login → should work
7. Check TodayView → should load (with mock data for now)

### **6.4 Test iOS App (Production Backend)**

1. Change scheme to "Release" (or edit Debug to use production URL)
2. Run on Simulator
3. Same tests as above
4. All API calls now go to Vercel

### **6.5 Test Apple Sign In (iOS Device Required)**

Apple Sign In doesn't work in Simulator. You need a real device:

1. Connect iPhone via USB
2. In Xcode, select your iPhone as destination
3. Run app
4. Tap "Sign in with Apple"
5. Should show Apple authentication flow
6. Complete sign in
7. App should create account via backend

---

## 🔒 **STEP 7: Security Checklist**

### **Environment Variables - NEVER COMMIT THESE**

Verify `.gitignore` includes:
```
.env
.env.local
.env.production
*.p8
*.pem
```

### **Database Security**

Neon automatically provides:
- ✅ SSL/TLS encryption
- ✅ Connection pooling
- ✅ Automatic backups
- ✅ IP allowlisting (optional)

### **API Security**

Your backend already has:
- ✅ JWT authentication
- ✅ Password hashing (bcrypt)
- ✅ HTTPS only (Vercel enforces)
- ✅ Helmet.js security headers
- ✅ CORS configured
- ✅ Input validation

**Add rate limiting** (recommended):

```bash
cd backend
npm install express-rate-limit
```

Update `backend/src/server.ts`:

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per IP
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/v1', limiter);
```

Commit and redeploy.

### **iOS Security**

Already implemented:
- ✅ Keychain storage for tokens
- ✅ HTTPS only API calls
- ✅ Receipt validation
- ✅ No sensitive data in UserDefaults

---

## 📊 **STEP 8: Monitoring & Logging**

### **Vercel Dashboard**

Monitor:
- Function invocations (API call count)
- Response times
- Error rates
- Real-time logs

Access at: https://vercel.com/your-project/logs

### **Neon Dashboard**

Monitor:
- Database size
- Query performance
- Active connections

Access at: https://console.neon.tech

### **Add Logging to Backend**

Your backend already logs:
```typescript
console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
console.error('Error:', error);
```

These appear in Vercel logs.

**Optional: Add error tracking** (Sentry, LogRocket, etc.)

---

## 🚀 **STEP 9: Test Subscription Flow**

### **9.1 Test Trial Creation**

When a user signs up, they should automatically get a trial:

```bash
# Signup
curl -X POST https://your-app.vercel.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "trial@test.com", "password": "Test1234!"}'

# Response should show:
"subscription": {
  "status": "trial",
  "hasAccess": true,
  "trialEndDate": "2026-01-14T...",
  "daysRemaining": 7
}
```

### **9.2 Verify in Database**

In Neon SQL Editor:

```sql
SELECT * FROM subscriptions WHERE user_id = 'the-user-id-from-signup';
```

Should show:
```
status: trial
trial_start_date: 2026-01-07
trial_end_date: 2026-01-14 (7 days later)
```

### **9.3 Test Trial Expiration**

Manually expire a trial:

```sql
UPDATE subscriptions
SET trial_end_date = NOW() - INTERVAL '1 day'
WHERE user_id = 'test-user-id';
```

Now try to call a protected endpoint:

```bash
curl https://your-app.vercel.app/api/v1/screen-time/budgets/test-user-id/current \
  -H "Authorization: Bearer <token>"

# Should return 403:
{
  "success": false,
  "error": "Trial expired. Please subscribe to continue.",
  "requiresSubscription": true,
  "trialExpired": true
}
```

✅ Subscription gating works!

### **9.4 Test iOS Purchase (Sandbox)**

1. On iOS device, sign out of App Store
2. Go to Settings → App Store → Sandbox Account
3. Sign in with your Sandbox Test User
4. Run your app
5. Trigger subscription flow (trial expired → paywall)
6. Tap "Subscribe"
7. Use Sandbox credentials to "purchase"
8. App should validate receipt with backend
9. Backend updates subscription status to "active"

---

## ✅ **Deployment Checklist**

Before submitting to App Store:

### **Backend**
- [ ] Vercel deployed and responding
- [ ] Database migrations run successfully
- [ ] Environment variables set correctly
- [ ] JWT_SECRET is strong and unique
- [ ] Apple Sign In credentials configured
- [ ] Health endpoint returns 200 OK
- [ ] Test user can signup, login, sync data

### **Database**
- [ ] Neon project created
- [ ] All 12 tables exist
- [ ] Foreign keys configured
- [ ] Indexes created
- [ ] Connection string secured

### **Apple Developer**
- [ ] App ID registered
- [ ] Services ID configured
- [ ] Auth Key downloaded (.p8)
- [ ] Subscription product created
- [ ] Sandbox test accounts created

### **iOS App**
- [ ] Bundle ID matches Apple Developer
- [ ] Production API URL configured
- [ ] Capabilities enabled (Sign in with Apple, etc.)
- [ ] Product ID matches App Store Connect
- [ ] App icon added (1024x1024)
- [ ] Launch screen configured
- [ ] Privacy Policy added (required for App Store)
- [ ] Terms of Service added

### **Testing**
- [ ] Signup/Login works
- [ ] Trial created automatically
- [ ] Trial expiration handled
- [ ] Subscription flow tested (sandbox)
- [ ] Apple Sign In tested (real device)
- [ ] Usage sync tested
- [ ] Budget alerts tested
- [ ] App works on multiple iOS versions

---

## 🎯 **Architecture Summary**

```
USER SIGNS UP
  ↓
iOS: SignupView
  ↓ POST /auth/signup { email, password }
Vercel: authController.signup()
  ↓ Hash password (bcrypt)
  ↓ INSERT users table
  ↓ INSERT subscriptions (status=trial, 7 days)
  ↓ Generate JWT token
  ↓ Return { user, token, subscription }
iOS: Save token to Keychain
  ↓
RootView checks subscription
  ↓ hasAccess=true → Show main app
  ↓ hasAccess=false → Show paywall


USER OPENS APP
  ↓
iOS: Load token from Keychain
  ↓ GET /subscription/status
Vercel: Check subscriptions table
  ↓ trial_end_date < now? → Expired
  ↓ subscription_end_date < now? → Expired
  ↓ Return { status, hasAccess, daysRemaining }
iOS:
  ↓ hasAccess=false → SubscriptionPaywallView
  ↓ hasAccess=true → MainTabView/TodayView


USER SUBSCRIBES (iOS)
  ↓
iOS: StoreKit purchase flow
  ↓ User completes purchase
  ↓ Get receipt data
  ↓ POST /subscription/validate-receipt { receiptData, transactionId }
Vercel: Validate with Apple servers
  ↓ UPDATE subscriptions (status=active, renewal_date, ios_receipt_data)
  ↓ Return { success: true }
iOS: Refresh UI, show main app


USER SYNCS SCREEN TIME
  ↓
iOS: Fetch Screen Time data from device
  ↓ [Instagram: 45m, YouTube: 30m, ...]
  ↓ POST /usage/sync { userId, date, apps: [...] }
Vercel: usageController.syncUsage()
  ↓ UPSERT user_apps (auto-categorize)
  ↓ UPSERT daily_app_usage
  ↓ Calculate daily/monthly totals per category
  ↓ Compare to budgets
  ↓ Over budget? → INSERT budget_alerts
  ↓ Return { budgetStatus, notifications }
iOS: Schedule local notifications
  ↓ Update TodayView UI
```

---

## 🆘 **Troubleshooting**

### **Issue: Can't connect to Neon database**

```
Error: connect ETIMEDOUT
```

**Solution**:
1. Check `DATABASE_URL` in Vercel environment variables
2. Ensure `?sslmode=require` is at the end
3. Check Neon dashboard → Database is not paused
4. Redeploy Vercel to pick up new env vars

### **Issue: Apple Sign In not working**

```
Error: invalid_client
```

**Solution**:
1. Verify `APPLE_SERVICES_ID` matches Services ID in Apple Developer
2. Check Return URLs include your Vercel domain
3. Ensure .p8 key is correctly formatted in `APPLE_PRIVATE_KEY`
4. Verify `APPLE_KEY_ID` and `APPLE_TEAM_ID` are correct

### **Issue: Subscription not validating**

```
Error: Receipt validation failed
```

**Solution**:
1. In App Store Connect, check subscription product is "Ready to Submit"
2. Use Sandbox account for testing (not production)
3. Verify `APPLE_BUNDLE_ID` matches exactly
4. Check receipt data is being sent correctly from iOS

### **Issue: Cold start taking too long**

```
Request timeout after 10s
```

**Solution**:
1. Upgrade to Vercel Pro ($20/mo) for warm functions
2. Use Neon's connection pooling (automatically enabled)
3. Optimize Prisma queries (already optimized in your code)

---

## 🎉 **You're Ready!**

Your production infrastructure is now:

✅ **Secure** - SSL, JWT, Keychain, password hashing
✅ **Scalable** - Serverless functions + serverless database
✅ **Cost-effective** - Free tier for MVP, $20/mo for production
✅ **App Store Ready** - Apple Sign In + subscriptions configured

Next step: Submit to TestFlight, then App Store!

Need help with TestFlight submission? I can guide you through that too.

---

**Total Setup Time**: ~2-3 hours
**Total Cost**: $0/month (free tiers) or $20/month (Vercel Pro for warm functions)
