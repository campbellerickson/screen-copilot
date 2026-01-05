# Authentication & Subscription Setup Guide

**Last Updated:** January 4, 2026

This guide walks you through setting up the complete authentication and subscription system for Screen Budget.

---

## 🎯 What's Been Built

### Backend (Complete ✅)
- **Authentication System**
  - Email/password signup and login
  - Apple Sign In support
  - JWT token generation and verification
  - Secure password hashing with bcrypt
  - User session management

- **Subscription Management**
  - 7-day free trial for all new users
  - Monthly subscription at $0.99/month
  - iOS App Store integration (StoreKit)
  - Stripe integration for web (future)
  - Subscription status tracking
  - Receipt validation

- **Security**
  - All screen time API routes require authentication
  - All routes require active subscription or trial
  - JWT tokens with 7-day expiration
  - Password validation (min 8 chars, must have number and letter)
  - Email validation

### iOS App (Complete ✅)
- **Login Screen**
  - Email/password login
  - Apple Sign In button
  - Form validation
  - Error handling

- **Signup Screen**
  - Email/password registration
  - Apple Sign In button
  - Password strength validation
  - Trial information display

- **Subscription Paywall**
  - Beautiful pricing display
  - 7-day free trial badge
  - Feature list
  - StoreKit integration
  - Restore purchases functionality

- **App Flow**
  - Login required on first launch
  - Subscription required after login
  - Automatic trial creation on signup
  - Subscription status checks

---

## 📋 Database Setup

### 1. Apply Migrations

The database schema has been updated with `User` and `Subscription` models. You need to apply the migration:

```bash
cd backend
npx prisma migrate dev --name add_auth_and_subscriptions
```

This will:
- Add `password`, `appleId`, `profileImage`, `lastLoginAt` fields to User model
- Create new `Subscription` table with trial and payment tracking

### 2. Verify Schema

```bash
npx prisma studio
```

You should see the new `subscriptions` table in Prisma Studio.

---

## 🔐 Backend Configuration

### 1. Update Environment Variables

Edit `backend/.env` and add:

```bash
# Authentication
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Apple Sign In
APPLE_BUNDLE_ID=com.campbell.ScreenTimeBudget

# Stripe (optional - for web subscriptions)
STRIPE_SECRET_KEY=sk_test_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_secret
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
```

**Important:** Generate a strong JWT secret for production:
```bash
openssl rand -base64 32
```

### 2. Test Backend Locally

Start the backend:
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
    "password": "Test1234",
    "name": "Test User"
  }'
```

You should get back:
- User object
- JWT token
- Subscription with `status: "trial"` and 7-day trial period

Test login:
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234"
  }'
```

---

## 🍎 Apple Sign In Setup

### 1. Enable Sign In with Apple

1. Go to https://developer.apple.com/account
2. Click **Certificates, Identifiers & Profiles**
3. Select your App ID (`com.campbell.ScreenTimeBudget`)
4. Under **Capabilities**, enable **Sign In with Apple**
5. Click **Save**

### 2. Add Capability in Xcode

1. Open your Xcode project
2. Select your target → **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Sign In with Apple**

### 3. Backend Apple Sign In Validation

The backend is configured to validate Apple identity tokens. No additional setup needed - it uses the `apple-signin-auth` package.

---

## 💳 In-App Purchase Setup (iOS)

### 1. Create In-App Purchase Product

**When your Apple Developer account is approved:**

1. Go to https://appstoreconnect.apple.com/
2. Select your app → **In-App Purchases**
3. Click **+** to create new
4. Select **Auto-Renewable Subscription**
5. Fill out:
   - **Reference Name:** Screen Budget Monthly
   - **Product ID:** `com.campbell.screenbudget.monthly`
   - **Subscription Group:** Create new "Screen Budget Pro"
   - **Subscription Duration:** 1 Month
   - **Price:** $0.99 USD

### 2. Configure 7-Day Free Trial

1. In the subscription settings
2. Under **Subscription Prices**
3. Click **Set Intro Offer**
4. Select **Free Trial**
5. Set duration to **7 days**
6. Click **Save**

### 3. Update StoreKit Configuration

The product ID `com.campbell.screenbudget.monthly` is already configured in `StoreKitManager.swift`. If you use a different ID, update line 13:

```swift
private let monthlySubscriptionID = "com.campbell.screenbudget.monthly"
```

### 4. Test with Sandbox Users

1. Go to **App Store Connect** → **Users and Access** → **Sandbox Testers**
2. Create a test account
3. On your iPhone:
   - Settings → App Store → Sandbox Account
   - Sign in with test account
4. Test purchasing the subscription in your app

---

## 🚀 Deployment to Production

### 1. Deploy Backend to Railway

Follow the `DEPLOYMENT_GUIDE.md` for complete Railway setup, then:

1. Add these environment variables in Railway:
```
JWT_SECRET=[your-generated-secret]
APPLE_BUNDLE_ID=com.campbell.ScreenTimeBudget
NODE_ENV=production
```

2. The database migration will run automatically on deploy

### 2. Update iOS Constants

Edit `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
struct Constants {
    #if DEBUG
    static let baseURL = "http://192.168.68.50:3000/api/v1"
    #else
    static let baseURL = "https://YOUR-RAILWAY-URL.up.railway.app/api/v1"
    #endif
}
```

### 3. Submit to App Store

1. Archive your app in Xcode
2. Upload to App Store Connect
3. In App Store Connect:
   - Add screenshots
   - App description
   - Keywords
   - Privacy policy URL
   - Terms of service URL

4. **Important:** In App Review Information, explain:
   - The app uses Screen Time API for tracking
   - Subscription is required to access features
   - 7-day free trial is available

---

## 🧪 Testing Checklist

### Backend Tests
- [ ] Sign up with email/password creates user
- [ ] Sign up creates trial subscription (7 days)
- [ ] Login returns valid JWT token
- [ ] Screen time API requires auth token
- [ ] Screen time API requires active subscription/trial
- [ ] Expired trial blocks API access

### iOS Tests
- [ ] Login screen validates email format
- [ ] Login screen validates password strength
- [ ] Signup creates account and logs in
- [ ] Subscription paywall displays pricing
- [ ] Subscription purchase works (sandbox)
- [ ] Trial expiration shows paywall again
- [ ] Restore purchases works

---

## 🔧 Troubleshooting

### "Invalid token" errors

**Problem:** API returns 401 Unauthorized

**Solution:**
1. Check that JWT_SECRET is set in backend .env
2. Verify token is being sent in Authorization header
3. Check token hasn't expired (7-day expiry)
4. Try logging out and back in

### Subscription paywall shows even with active subscription

**Problem:** User has subscription but paywall appears

**Solution:**
1. Check backend `/subscription/status` endpoint returns `hasAccess: true`
2. Verify trial hasn't expired
3. Check subscription table in database
4. Look for errors in backend logs

### StoreKit product not loading

**Problem:** "Product not found" error

**Solution:**
1. Product ID must match exactly: `com.campbell.screenbudget.monthly`
2. Product must be in "Ready to Submit" status in App Store Connect
3. You must be signed in with Sandbox account on device
4. Try restarting the app

### Apple Sign In not working

**Problem:** Apple Sign In button doesn't work

**Solution:**
1. Verify Sign In with Apple is enabled for your App ID
2. Check capability is added in Xcode
3. Ensure you're testing on a real device (not simulator)
4. Check Apple Developer account is in good standing

---

## 📚 API Endpoints

### Authentication

```
POST /api/v1/auth/signup
Body: { email, password, name? }
Returns: { user, token, subscription }

POST /api/v1/auth/login
Body: { email, password }
Returns: { user, token, subscription }

POST /api/v1/auth/apple
Body: { identityToken, user? }
Returns: { user, token, subscription, isNewUser }

GET /api/v1/auth/me
Headers: Authorization: Bearer <token>
Returns: { user, subscription }
```

### Subscription

```
GET /api/v1/subscription/status
Headers: Authorization: Bearer <token>
Returns: { status, hasAccess, trialEndDate?, renewalDate? }

POST /api/v1/subscription/validate-receipt
Headers: Authorization: Bearer <token>
Body: { receiptData, transactionId }
Returns: { subscription }

POST /api/v1/subscription/cancel
Headers: Authorization: Bearer <token>
Returns: { message }
```

### Screen Time (All require auth + subscription)

```
POST /api/v1/screen-time/budgets
GET /api/v1/screen-time/budgets/:userId/current
POST /api/v1/screen-time/usage/sync
GET /api/v1/screen-time/usage/:userId/daily
GET /api/v1/screen-time/alerts/:userId
```

---

## 🎬 Next Steps

1. ✅ **Right now:** Apply database migrations locally
2. ✅ **Right now:** Test signup and login locally
3. ⏳ **Wait for Apple approval:** Configure in-app purchase products
4. ⏳ **After Railway setup:** Deploy backend with auth env vars
5. ⏳ **After Railway setup:** Update iOS app with production URL
6. ⏳ **Before launch:** Test complete flow end-to-end
7. 🎉 **Launch:** Submit to App Store!

---

## 💡 User Flow Summary

1. User downloads app
2. **Login Screen** appears (email/password or Apple Sign In)
3. User signs up → **7-day free trial starts automatically**
4. User sees main app with all features unlocked
5. After 7 days, trial expires
6. **Subscription Paywall** appears
7. User subscribes for $0.99/month
8. User continues using app

---

## 🛟 Need Help?

- **Authentication issues:** Check backend logs for JWT errors
- **Subscription issues:** Verify trial dates in database
- **StoreKit issues:** Check App Store Connect configuration
- **Deployment issues:** See DEPLOYMENT_GUIDE.md

---

**All code is complete and ready to test!** 🚀

The system is fully functional for local testing. You just need to:
1. Run migrations
2. Test locally
3. Configure App Store Connect when Apple Developer is approved
4. Deploy to Railway
