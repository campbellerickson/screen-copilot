# 🚀 TestFlight Deployment Checklist

Quick reference for deploying to TestFlight and testing.

---

## ✅ **Pre-Deployment Checklist**

### **Backend Ready?**
- [ ] Vercel deployed: `https://your-app.vercel.app/health` returns 200
- [ ] Neon database: All tables created
- [ ] Environment variables set in Vercel
- [ ] Test endpoint: `curl https://your-app.vercel.app/api/v1/auth/signup` works

### **iOS App Ready?**
- [ ] Production URL configured in Constants.swift
- [ ] Bundle ID: `com.campbell.ScreenTimeCopilot`
- [ ] Version: `1.0` Build: `1`
- [ ] App icon added (1024x1024)
- [ ] Launch screen configured

---

## 📱 **TestFlight Deployment Steps**

### **1. Archive the App**

Open Xcode:

```bash
open ~/Desktop/Code/screen-budget/ios/ScreenTimeBudget.xcodeproj
```

1. Select "Any iOS Device (arm64)" as destination (not Simulator!)
2. Product → Archive
3. Wait 2-3 minutes for build
4. Archives window opens automatically

### **2. Upload to App Store Connect**

In Archives window:
1. Select your archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Click "Upload"
5. Options:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (automatic)
6. Sign with your Apple Developer certificate
7. Click "Upload"
8. Wait ~5 minutes for processing

### **3. Enable TestFlight**

1. Go to https://appstoreconnect.apple.com
2. Select your app
3. Go to "TestFlight" tab
4. Wait for build to finish processing (~10 minutes)
5. Click on the build
6. Add "What to Test" notes:
   ```
   Version 1.0 - Initial TestFlight Build

   Please test:
   - Sign up / Login flow
   - Budget creation
   - Today view dashboard
   - Subscription paywall (don't subscribe yet - sandbox only)

   Known issues:
   - Screen Time data is mock (real integration coming soon)
   ```
7. Click "Save"

### **4. Add Testers**

**Internal Testers** (you and your team):
1. TestFlight → Internal Testing → Click "+"
2. Add group name: "Internal Team"
3. Add testers by email
4. Build automatically distributed

**External Testers** (requires App Review - takes 1-2 days):
1. TestFlight → External Testing → Click "+"
2. Add group name: "Beta Testers"
3. Add build
4. Submit for review
5. Wait for Apple approval

### **5. Install TestFlight**

Testers receive email:
1. Install TestFlight app from App Store
2. Tap "View in TestFlight" from email
3. Tap "Install"
4. Open app

---

## 🧪 **Testing Plan on TestFlight**

### **Test 1: Authentication Flow**

**Goal**: Verify signup/login works with production API

1. Open app (fresh install)
2. Tap "Sign Up"
3. Enter email: `testflight-test@example.com`
4. Enter password: `Test1234!`
5. Tap "Create Account"

**Expected**:
- ✅ Account created
- ✅ Receives 7-day trial
- ✅ Navigates to TodayView

**Check in Neon**:
```sql
SELECT * FROM users WHERE email = 'testflight-test@example.com';
SELECT * FROM subscriptions WHERE user_id = '<user-id-from-above>';
```

Should show:
- User created
- Subscription with `status = 'trial'`
- `trial_end_date` = 7 days from now

---

### **Test 2: Subscription Gate**

**Goal**: Verify paywall shows when trial expires

1. In Neon SQL Editor, manually expire trial:
```sql
UPDATE subscriptions
SET trial_end_date = NOW() - INTERVAL '1 day',
    updated_at = NOW()
WHERE user_id = '<test-user-id>';
```

2. Force quit app (swipe up from app switcher)
3. Reopen app

**Expected**:
- ✅ Shows subscription paywall
- ✅ Cannot access main app without subscription

---

### **Test 3: Today View Dashboard**

**Goal**: Verify UI loads and looks good

1. Ensure you have active trial/subscription
2. Open app → Navigate to Today tab

**Check**:
- ✅ Dashboard loads
- ✅ Mock data displays (we'll replace with real Screen Time data later)
- ✅ Categories show (Social Media, Entertainment, etc.)
- ✅ Streak badge visible
- ✅ Chart renders
- ✅ No crashes or errors

---

### **Test 4: Performance**

**Goal**: Measure response times and identify slow endpoints

**Tools**:
- Xcode Instruments (Time Profiler)
- Network Link Conditioner (simulate slow network)
- Vercel Analytics (check function response times)

**Metrics to capture**:
- App launch time: < 2s
- Login response time: < 1s
- Dashboard load time: < 1.5s
- API cold start: ~500ms-2s (acceptable)
- API warm start: ~50-200ms (target)

---

## 🔧 **Optimization Opportunities**

### **Frontend Optimizations**

#### **1. Reduce Mock Data**
Currently TodayView uses hardcoded mock data. Replace with real API calls.

**File**: `ios/ScreenTimeBudget/Views/TodayView.swift:527`

```swift
// Current (mock):
private func loadMockData() {
    categories = [
        CategoryViewModel(categoryType: "social_media", minutesUsed: 80, dailyBudget: 90, isUnlimited: false),
        // ...
    ]
}

// TODO: Replace with:
private func loadRealData() async {
    let userId = UserManager.shared.userId
    let budgetStatus = try await apiService.getDailyUsage(userId: userId, date: Date())
    // Process and update UI
}
```

#### **2. Add Pull-to-Refresh**
Users expect to refresh data manually.

**File**: `ios/ScreenTimeBudget/Views/TodayView.swift:51`

Already implemented:
```swift
.refreshable {
    await viewModel.refresh()
}
```

Just need to connect to real API.

#### **3. Loading States**
Add loading indicators while fetching data.

```swift
if viewModel.isLoading {
    ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
} else {
    // Existing content
}
```

#### **4. Error Handling**
Show user-friendly error messages.

```swift
@Published var errorMessage: String?

// In view:
if let error = viewModel.errorMessage {
    VStack {
        Image(systemName: "exclamationmark.triangle")
        Text(error)
        Button("Retry") {
            Task { await viewModel.loadData() }
        }
    }
}
```

---

### **Backend Optimizations**

#### **1. Add Connection Pooling**
Current: Each request creates new database connection
Target: Reuse connections across requests

**File**: `backend/src/config/database.ts`

```typescript
import { PrismaClient } from '@prisma/client';

// Current:
const prisma = new PrismaClient();

// Optimized for serverless:
const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
  // Add connection pooling
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

#### **2. Optimize Usage Sync**
Current: Processes 10 apps at a time
Target: Increase batch size for faster syncs

**File**: `backend/src/services/usageService.ts:20`

```typescript
// Current:
const BATCH_SIZE = 10;

// For production (test this):
const BATCH_SIZE = 20; // or 30
```

Monitor Neon connection limits.

#### **3. Cache Budget Status**
Current: Queries database on every request
Target: Cache for 5 minutes

```typescript
import NodeCache from 'node-cache';
const cache = new NodeCache({ stdTTL: 300 }); // 5 min

async getDailyUsage(userId: string, date: Date) {
  const cacheKey = `budget-${userId}-${date.toISOString().split('T')[0]}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const result = await this.fetchFromDatabase(userId, date);
  cache.set(cacheKey, result);
  return result;
}
```

#### **4. Add Rate Limiting**
Prevent abuse and DDoS.

**File**: `backend/src/server.ts`

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per IP
  message: 'Too many requests, please try again later.'
});

app.use('/api/v1', limiter);
```

---

## 📊 **Testing Metrics to Track**

### **API Performance**
Monitor in Vercel dashboard:
- [ ] Average response time: < 500ms
- [ ] P95 response time: < 1s
- [ ] Error rate: < 1%
- [ ] Function invocations per day
- [ ] Cold start percentage

### **Database Performance**
Monitor in Neon dashboard:
- [ ] Query time: < 100ms average
- [ ] Active connections: < 10
- [ ] Database size
- [ ] Query patterns (identify slow queries)

### **iOS Performance**
Monitor in Xcode:
- [ ] Memory usage: < 100 MB
- [ ] CPU usage: < 30%
- [ ] Battery impact: Low
- [ ] Network usage: < 5 MB per day

---

## 🐛 **Known Issues to Test**

### **1. Screen Time API Integration**
**Status**: Not yet implemented
**Priority**: HIGH
**Impact**: App uses mock data

**TODO**:
- Request Screen Time permissions
- Implement `DeviceActivityMonitor`
- Fetch real usage data
- Sync to backend

### **2. Apple Sign In**
**Status**: Backend ready, iOS not implemented
**Priority**: MEDIUM
**Impact**: Only email/password login works

**TODO**:
- Add "Sign in with Apple" button to LoginView
- Implement `ASAuthorizationController`
- Send identity token to backend

### **3. StoreKit Product Loading**
**Status**: Product ID configured, but no products loaded
**Priority**: HIGH (for paid app)
**Impact**: Subscription purchase won't work

**TODO**:
- Create subscription in App Store Connect
- Test product loading in StoreKitManager
- Verify receipt validation

### **4. Background Sync**
**Status**: Identifier configured, not implemented
**Priority**: LOW (nice to have)
**Impact**: User must open app to sync data

**TODO**:
- Implement `BGTaskScheduler`
- Register background task
- Sync usage data in background

---

## ✅ **Post-TestFlight Actions**

After TestFlight testing:

1. **Gather Feedback**
   - Survey testers
   - Check crash reports in App Store Connect
   - Review analytics in Vercel/Neon

2. **Fix Critical Issues**
   - Prioritize by impact/frequency
   - Create GitHub issues
   - Implement fixes

3. **Optimize Based on Data**
   - Review API response times
   - Identify slow endpoints
   - Optimize queries
   - Reduce payload sizes

4. **Prepare for App Store Submission**
   - Add App Store screenshots
   - Write App Store description
   - Create Privacy Policy
   - Add Terms of Service
   - Submit for App Review

---

## 🎯 **Success Criteria**

Before moving to App Store:
- [ ] Zero crashes in TestFlight
- [ ] All auth flows work (signup, login, trial)
- [ ] Subscription gate functions correctly
- [ ] API response times < 1s
- [ ] App launch time < 2s
- [ ] UI looks good on all iPhone sizes
- [ ] 10+ TestFlight testers with positive feedback

---

## 📝 **Quick Commands**

### **Deploy new build to TestFlight**
```bash
# 1. Increment build number in Xcode
# 2. Archive
# 3. Upload

# Or use fastlane (optional):
cd ios
fastlane beta
```

### **Check backend status**
```bash
curl https://your-app.vercel.app/health
```

### **Check database**
```bash
# In Neon SQL Editor:
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM subscriptions WHERE status = 'trial';
SELECT COUNT(*) FROM daily_app_usage;
```

### **Test signup API**
```bash
curl -X POST https://your-app.vercel.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "Test1234!", "name": "Test User"}'
```

---

Ready to deploy! 🚀
