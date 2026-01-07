# 🚀 Vercel Architecture & Deployment Guide

## 📊 Architecture Overview

### **Current Setup**
```
┌─────────────────────────────────────────────────────────────┐
│                      iOS APP (SwiftUI)                       │
│  • Screen Time API integration                              │
│  • StoreKit subscriptions                                   │
│  • Local notifications                                      │
│  • Keychain token storage                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ HTTPS REST API
                        │ Authorization: Bearer <jwt-token>
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼

   LOCAL DEV       VERCEL           SUPABASE
   (Express)    (Serverless)      (Edge Functions)
   localhost:3000   Production     Alternative Prod
        │               │                │
        ▼               ▼                ▼

   PostgreSQL      Neon/Vercel      Supabase DB
    (Docker)       PostgreSQL        PostgreSQL
```

---

## 🏗️ **How Vercel Hosting Works**

### **Serverless Architecture**

Unlike traditional servers that run 24/7, Vercel uses **serverless functions**:

```javascript
// Traditional Express (always running)
app.listen(3000, () => {
  console.log('Server running on port 3000');
});

// Vercel Serverless (runs per request)
export default function handler(req, res) {
  // Your Express app runs here
  // Starts when request comes in
  // Shuts down when response sent
}
```

### **What Happens When iOS App Makes a Request**

```
1. iOS: POST https://your-app.vercel.app/api/v1/usage-sync

2. Vercel's Edge Network receives request
   ├─ Finds nearest data center to user
   └─ Routes to your serverless function

3. Serverless Function (Cold Start or Warm)
   ├─ COLD START (~500ms-2s): Function starts from scratch
   │   ├─ Load Node.js runtime
   │   ├─ Load your Express app
   │   ├─ Initialize Prisma client
   │   └─ Connect to database
   │
   └─ WARM START (~50-200ms): Function already running
       └─ Reuses existing connection

4. Your Express App Executes
   ├─ Middleware: authenticate (check JWT)
   ├─ Middleware: requireSubscription (check trial/active)
   ├─ Controller: usageController.syncUsage()
   ├─ Service: usageService.syncUsageData()
   ├─ Database: Prisma queries to PostgreSQL
   └─ Response: JSON sent back to iOS

5. Function Stays Warm for ~5 minutes
   └─ Next request within 5min = fast warm start
   └─ After 5min idle = cold start again

6. iOS Receives Response
   └─ Updates UI, schedules notifications
```

---

## 🗄️ **Database Options with Vercel**

### **Option 1: Vercel Postgres (Recommended)**

```
Pros:
✅ Native integration (1-click setup)
✅ Automatic connection pooling
✅ Same infrastructure as functions (low latency)
✅ Free tier: 256 MB storage, 60 hours compute
✅ Easy environment variable setup

Cons:
❌ Limited free tier storage
❌ Newer service (less mature than others)

Cost:
Free tier → $20/mo (Pro) → $400/mo (Enterprise)
```

### **Option 2: Neon (Popular Choice)**

```
Pros:
✅ Generous free tier (0.5 GB storage)
✅ Serverless PostgreSQL (auto-scale)
✅ Branching (database copies for testing)
✅ Great for serverless functions

Cons:
❌ Separate service to manage
❌ Connection pooling setup required

Cost:
Free tier → $19/mo (Pro)
```

### **Option 3: Supabase (Current Choice)**

```
Pros:
✅ You're already using it!
✅ Auth + Database + Edge Functions all in one
✅ 500 MB free tier
✅ Real-time capabilities if needed
✅ Good dashboard

Cons:
❌ Mixing Vercel serverless + Supabase = two platforms
❌ Slightly higher latency (unless same region)

Cost:
Free tier → $25/mo (Pro)
```

### **Recommended Setup for Your App**

**Use Vercel + Neon:**
```
Vercel Serverless Functions (API)
         ↓
Neon PostgreSQL (Database)
         ↓
Same Prisma schema you already have
```

**Why?**
- Both are serverless (perfect match)
- Neon auto-scales with your functions
- Connection pooling built-in
- Free tier covers MVP launch
- Easy to upgrade later

---

## 📁 **Project Structure for Vercel**

### **Current Backend Structure**
```
backend/
├── src/
│   ├── server.ts              # Express app
│   ├── config/
│   │   └── database.ts        # Prisma client
│   ├── middleware/
│   │   ├── auth.ts            # JWT verification
│   │   ├── validation.ts
│   │   └── errorHandler.ts
│   ├── routes/
│   │   ├── auth.ts            # /api/v1/auth/*
│   │   ├── screenTime.ts      # /api/v1/screen-time/*
│   │   ├── subscription.ts    # /api/v1/subscription/*
│   │   ├── weeklyGoals.ts
│   │   └── ...
│   ├── controllers/           # Request handlers
│   └── services/              # Business logic
├── prisma/
│   └── schema.prisma
├── package.json
├── tsconfig.json
├── vercel.json                # ✅ Already created
└── .env                       # Don't commit! Use Vercel env vars
```

### **How Vercel Deploys This**

```
1. You push to GitHub
   └─ git push origin main

2. Vercel detects push (via webhook)
   └─ Triggers automatic build

3. Build Process
   ├─ npm install (installs dependencies)
   ├─ npx prisma generate (creates Prisma client)
   ├─ npm run build (compiles TypeScript → JavaScript)
   └─ Creates serverless function from src/server.ts

4. Deployment
   ├─ Deploys to Vercel's global edge network
   ├─ Available at: https://your-app.vercel.app
   └─ Old version kept (instant rollback if needed)

5. Environment Variables (from Vercel dashboard)
   ├─ DATABASE_URL (Neon connection string)
   ├─ JWT_SECRET
   ├─ STRIPE_SECRET_KEY
   └─ All injected at runtime (not in code)
```

---

## 🔄 **Complete Request Lifecycle**

### **Example: iOS Syncs Usage Data**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. iOS APP                                                   │
│    User opens app at 9 PM                                   │
└─────────────────────────────────────────────────────────────┘
   │
   │ Screen Time API fetches today's usage
   │ [Instagram: 45 min, YouTube: 30 min, ...]
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. APIService.syncUsage()                                    │
│    POST https://your-app.vercel.app/api/v1/usage-sync       │
│    Headers: { Authorization: "Bearer eyJhbG..." }            │
│    Body: {                                                   │
│      userId: "abc123",                                       │
│      usageDate: "2026-01-07",                                │
│      apps: [...]                                             │
│    }                                                         │
└─────────────────────────────────────────────────────────────┘
   │
   │ HTTPS request over internet
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. VERCEL EDGE NETWORK                                       │
│    Finds closest data center (e.g., San Francisco)          │
│    Routes to your serverless function                       │
└─────────────────────────────────────────────────────────────┘
   │
   │ Invokes function (cold or warm start)
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. YOUR EXPRESS APP (backend/src/server.ts)                 │
│                                                              │
│    Middleware Stack:                                        │
│    ├─ helmet() - Security headers                           │
│    ├─ cors() - Allow iOS app to call API                    │
│    ├─ express.json() - Parse request body                   │
│    ├─ authenticate() - Verify JWT token                     │
│    │   └─ Decode token → Extract userId                     │
│    └─ requireSubscription() - Check trial/active            │
│        └─ Query subscriptions table                         │
│            └─ Trial expired? → 403 error                    │
│            └─ Active? → Continue                            │
│                                                              │
│    Router:                                                  │
│    POST /api/v1/screen-time/usage/sync                      │
│    └─ usageController.syncUsage()                           │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. CONTROLLER (backend/src/controllers/usageController.ts)  │
│                                                              │
│    const { userId, usageDate, apps } = req.body;            │
│                                                              │
│    // Sync usage data                                       │
│    const syncResult = await usageService.syncUsageData(     │
│      userId, new Date(usageDate), apps                      │
│    );                                                        │
│                                                              │
│    // Get updated budget status                             │
│    const budgetStatus = await usageService.getDailyUsage(   │
│      userId, new Date(usageDate)                            │
│    );                                                        │
│                                                              │
│    // Check for alerts                                      │
│    const { alerts, notifications } =                        │
│      await alertService.checkAndTriggerAlerts(...)          │
│                                                              │
│    res.json({ success: true, data: {...} });                │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. SERVICE (backend/src/services/usageService.ts)           │
│                                                              │
│    async syncUsageData(userId, date, apps) {                │
│      // Batch process apps (10 at a time)                   │
│      for (let i = 0; i < apps.length; i += 10) {            │
│        const batch = apps.slice(i, i + 10);                 │
│                                                              │
│        await Promise.allSettled(                            │
│          batch.map(async (app) => {                         │
│            // 1. Find or create user_apps record            │
│            const userApp = await prisma.userApp.upsert({    │
│              where: { userId_bundleId: {...} },             │
│              create: {                                      │
│                userId, bundleId: app.bundleId,              │
│                appName: app.appName,                        │
│                categoryType: this.categorizeApp(...)        │
│                  // Instagram → "social_media"              │
│              },                                             │
│              update: { appName, lastDetected: now }         │
│            });                                              │
│                                                              │
│            // 2. Create/update daily_app_usage              │
│            await prisma.dailyAppUsage.upsert({              │
│              where: { userId_appId_usageDate: {...} },      │
│              create: { userId, appId, date, totalMinutes }, │
│              update: { totalMinutes, syncedAt: now }        │
│            });                                              │
│          })                                                 │
│        );                                                   │
│      }                                                      │
│    }                                                        │
└─────────────────────────────────────────────────────────────┘
   │
   │ Multiple SQL queries to database
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. DATABASE (Neon PostgreSQL)                                │
│                                                              │
│    Tables affected:                                         │
│    ├─ user_apps (upsert Instagram, YouTube records)         │
│    ├─ daily_app_usage (upsert today's usage)                │
│    ├─ screen_time_budgets (read current month's budget)     │
│    ├─ category_budgets (read social_media: 40 min/day)      │
│    └─ budget_alerts (insert if over budget)                 │
│                                                              │
│    Queries executed:                                        │
│    1. UPSERT user_apps (Instagram)                          │
│       └─ Returns app_id: "abc-123"                          │
│                                                              │
│    2. UPSERT daily_app_usage                                │
│       └─ INSERT (user_id, app_id, date, 45 minutes)         │
│                                                              │
│    3. SELECT category_budgets WHERE month = Jan 2026        │
│       └─ social_media: 30 hours/month = 40 min/day          │
│                                                              │
│    4. SELECT SUM(total_minutes) FROM daily_app_usage        │
│       WHERE user_id AND category = social_media AND date    │
│       └─ Result: 45 minutes used today                      │
│                                                              │
│    5. Budget Check: 45 min > 40 min? YES → OVER             │
│       └─ INSERT budget_alerts (overage: 5 min)              │
└─────────────────────────────────────────────────────────────┘
   │
   │ Data returns to service layer
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. ALERT SERVICE (backend/src/services/alertService.ts)     │
│                                                              │
│    const notifications = [                                  │
│      {                                                      │
│        type: "daily_overage",                               │
│        categoryType: "social_media",                        │
│        categoryName: "Social Media",                        │
│        overageMinutes: 5,                                   │
│        usedMinutes: 45,                                     │
│        budgetMinutes: 40,                                   │
│        message: "You've exceeded your daily Social Media    │
│                  budget by 5 minutes"                       │
│      }                                                      │
│    ];                                                       │
└─────────────────────────────────────────────────────────────┘
   │
   │ Response bubbles back up
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. EXPRESS RESPONSE                                          │
│                                                              │
│    res.json({                                               │
│      success: true,                                         │
│      data: {                                                │
│        synced: 2,                                           │
│        budgetStatus: {                                      │
│          social_media: {                                    │
│            totalMinutes: 45,                                │
│            dailyBudget: 40,                                 │
│            monthlyUsed: 180,                                │
│            status: "over"                                   │
│          }                                                  │
│        },                                                   │
│        notifications: [...]                                 │
│      }                                                      │
│    });                                                      │
└─────────────────────────────────────────────────────────────┘
   │
   │ HTTPS response over internet
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. iOS APP RECEIVES RESPONSE                                │
│                                                              │
│     APIService.syncUsage() completes                        │
│     └─ Returns SyncResponse object                          │
│                                                              │
│     NotificationService.scheduleNotifications(...)          │
│     └─ Creates local notification:                          │
│        "🚨 You've exceeded your daily Social Media budget    │
│         by 5 minutes"                                       │
│                                                              │
│     TodayView updates UI                                    │
│     └─ Social Media category shows RED indicator            │
│     └─ Progress bar shows 45/40 min (112%)                  │
│     └─ Chart updates with latest data                       │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ **Environment Variables**

### **Local Development (.env.local)**
```bash
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/screen_budget_dev?schema=public"

# Server
PORT=3000
NODE_ENV=development
CORS_ORIGIN=*

# Auth
JWT_SECRET="your-super-secret-key-change-in-production"

# Apple
APPLE_BUNDLE_ID="com.campbell.ScreenTimeBudget"

# Stripe (test mode)
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
```

### **Vercel Production (Set in Dashboard)**
```bash
# Database (Neon)
DATABASE_URL="postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/screenbudget?sslmode=require"

# Auth
JWT_SECRET="generate-a-strong-random-string-here"

# Apple
APPLE_BUNDLE_ID="com.campbell.ScreenTimeBudget"

# Stripe (production mode)
STRIPE_SECRET_KEY="sk_live_..."
STRIPE_WEBHOOK_SECRET="whsec_..."

# CORS
CORS_ORIGIN="*"  # Mobile apps can use wildcard
```

---

## 🎯 **Cold Start Optimization**

### **Problem: Cold Starts**
When a serverless function hasn't been called recently (~5 min), it takes 500ms-2s to start.

### **Solutions Already in Your Code**

1. **Prisma Connection Pooling**
```typescript
// backend/src/config/database.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// Reuse connection across function invocations
export default prisma;
```

2. **Minimal Dependencies**
Your `package.json` only includes what's needed. Good!

3. **Use Neon's Serverless Driver** (Optional Upgrade)
```bash
npm install @neondatabase/serverless
```

Then update Prisma to use it for faster connections.

### **Additional Optimizations**

1. **Keep Functions Warm** (Paid feature)
Vercel Pro ($20/mo) keeps functions warm 24/7.

2. **Separate API Routes** (Future optimization)
Instead of one big Express app:
```
/api/auth/login.ts       # Separate function
/api/usage/sync.ts       # Separate function
```
Smaller functions = faster cold starts.

---

## 💰 **Cost Breakdown**

### **Vercel Hobby (FREE)**
```
✅ 100 GB bandwidth/month
✅ Unlimited deployments
✅ Automatic HTTPS
✅ Git integration
❌ ~500ms-2s cold starts
❌ No warm functions
```

### **Vercel Pro ($20/month)**
```
✅ 1 TB bandwidth
✅ Always-warm functions
✅ 100ms-500ms response times
✅ Commercial use allowed
```

### **Neon Free Tier**
```
✅ 0.5 GB storage
✅ 3 projects
✅ Unlimited queries
✅ Auto-pause after inactivity
```

### **Total Cost for MVP**
```
Vercel Free + Neon Free = $0/month

For production with warm functions:
Vercel Pro ($20) + Neon Free = $20/month
```

---

## 🔒 **Security Considerations**

### **What's Already Secure**

1. **JWT Authentication**
```typescript
// Every protected route checks the token
authenticate middleware → verifies JWT → extracts userId
```

2. **Password Hashing**
```typescript
import bcrypt from 'bcryptjs';
const hashedPassword = await bcrypt.hash(password, 10);
```

3. **iOS Keychain Storage**
Tokens stored in iOS Keychain (hardware encrypted).

4. **HTTPS Only**
Vercel automatically enforces HTTPS.

5. **SQL Injection Protection**
Prisma ORM parameterizes all queries.

### **Additional Security for Production**

1. **Rate Limiting** (Add to Express)
```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // 100 requests per IP
});

app.use('/api/v1', limiter);
```

2. **Input Validation** (Already have validation middleware)
```typescript
// Already implemented in middleware/validation.ts
validateSyncUsage, validateCreateBudget, etc.
```

3. **Environment Variable Secrets**
Never commit `.env` to git (already in `.gitignore`).

---

## 🚀 **Deployment Steps**

Ready to deploy? Here's the step-by-step guide in the next section.

---

## 📊 **Monitoring & Debugging**

### **Vercel Dashboard Shows:**
- Function invocations (how many API calls)
- Response times (cold vs warm)
- Error logs
- Bandwidth usage

### **Logging in Your Code**
```typescript
// Already in your code
console.log('[${new Date().toISOString()}] ${req.method} ${req.path}');
console.error('Sync usage error:', error);
```

These logs appear in Vercel's real-time log viewer.

---

This is the complete architecture! Want me to create the actual deployment guide next, or do you have questions about any part of this?
