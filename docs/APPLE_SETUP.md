# 🍎 Apple Developer Setup Guide

**Last Updated:** January 4, 2026  
Complete guide to setting up Apple Sign In and App Store Connect for subscriptions.

---

## 📋 Overview

This guide covers:
1. Apple Developer Account setup
2. Sign In with Apple configuration
3. App Store Connect setup
4. In-App Purchase configuration
5. Receipt validation setup
6. Testing with sandbox accounts

---

## 🚀 Step 1: Apple Developer Account

### Create/Verify Account

1. Go to [https://developer.apple.com](https://developer.apple.com)
2. Click **"Account"** in the top navigation
3. Sign in with your Apple ID (or create one)
4. Enroll in Apple Developer Program ($99/year)
   - Required for:
     - App Store distribution
     - Sign In with Apple
     - In-App Purchases
     - TestFlight
5. Verify enrollment status (usually instant, can take up to 24 hours)

---

## 🔐 Step 2: Sign In with Apple Setup

### 2.1 Create App Identifier

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Click **"+"** to add a new identifier
3. Select **"App IDs"**
4. Click **"Continue"**
5. Select **"App"**
6. Fill in:
   - **Description:** Screen Time Copilot
   - **Bundle ID:** `com.campbell.ScreenTimeCopilot` (use reverse domain notation)
7. Click **"Continue"** then **"Register"**

### 2.2 Enable Sign In with Apple Capability

1. Select your App ID from the list
2. Click **"Edit"**
3. Scroll to **"Sign In with Apple"**
4. Check the box to enable it
5. Click **"Save"**
6. Click **"Continue"** to confirm

### 2.3 Create Services ID (for Web/Backend)

1. Go to **Identifiers** → Click **"+"**
2. Select **"Services IDs"**
3. Click **"Continue"**
4. Fill in:
   - **Description:** Screen Time Copilot Backend
   - **Identifier:** `com.campbell.ScreenTimeCopilot.backend` (or your preferred ID)
5. Click **"Continue"** then **"Register"**
6. **Edit** the Services ID
7. Check **"Sign In with Apple"**
8. Click **"Configure"**
9. **Primary App ID:** Select your App ID (`com.campbell.ScreenTimeCopilot`)
10. **Website URLs:**
    - **Domains and Subdomains:** `your-app.vercel.app` (your Vercel domain)
    - **Return URLs:** `https://your-app.vercel.app/api/v1/auth/apple/callback`
11. Click **"Save"** → **"Continue"** → **"Save"**

### 2.4 Create Private Key for Sign In with Apple

1. Go to **Keys** section in Apple Developer Portal
2. Click **"+"** to create a new key
3. **Key Name:** Screen Time Copilot Apple Sign In
4. Check **"Sign In with Apple"**
5. Click **"Configure"**
   - **Primary App ID:** Select your App ID
6. Click **"Save"** → **"Continue"** → **"Register"**
7. **⚠️ IMPORTANT:** Download the `.p8` key file
   - You can only download this once!
   - Save it securely (use password manager)
   - Note the **Key ID** shown (you'll need it)
8. Click **"Done"**

### 2.5 Get Your Team ID

1. Go to **Membership** section
2. Find your **Team ID** (looks like: `ABCD1234EF`)
3. Save this for environment variables

---

## 💰 Step 3: App Store Connect Setup

### 3.1 Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Click **"+"** → **"New App"**
4. Fill in:
   - **Platform:** iOS
   - **Name:** Screen Time Copilot
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your App ID (`com.campbell.ScreenTimeCopilot`)
   - **SKU:** `screen-time-budget-001` (unique identifier)
   - **User Access:** Full Access
5. Click **"Create"**

### 3.2 Set Up App Information

1. In your app's page, fill in:
   - **Privacy Policy URL:** (required for subscriptions)
   - **Category:** Health & Fitness
   - **Description:** Your app description
   - **Screenshots:** (required for review)
   - **App Icon:** (required)

### 3.3 Create In-App Purchase Subscription

1. Go to **Features** tab in App Store Connect
2. Click **"In-App Purchases"**
3. Click **"+"** to create
4. Select **"Auto-Renewable Subscription"**
5. Click **"Create"**
6. Fill in subscription details:

   **Subscription Information:**
   - **Reference Name:** Monthly Premium
   - **Product ID:** `com.campbell.ScreenTimeCopilot.premium.monthly`
   - **Subscription Group:** Create new group (e.g., "Premium")

   **Subscription Details:**
   - **Subscription Duration:** 1 Month
   - **Price:** $0.99 USD (or your price)
   - **Free Trial:** 7 Days (important for your app!)

   **Localization:**
   - **Display Name:** Premium Monthly
   - **Description:** Unlock all premium features with monthly subscription

7. Click **"Save"**
8. **Add Subscription Group:**
   - Name: Premium
   - Click **"Create"**
   - Add your subscription to the group

### 3.4 Configure Subscription Settings

1. Go to **Subscriptions** tab
2. Click on your subscription group
3. **Subscription Levels:**
   - Ensure your subscription is the only one (for now)
   - This is the level users will subscribe to

4. **Review Information:**
   - Subscription Terms: Link to your terms of service
   - Privacy Policy: Link to your privacy policy (required!)
   - Review Notes: Any notes for reviewers

---

## 🔑 Step 4: Shared Secret for Receipt Validation

### Get App-Specific Shared Secret

1. Go to **Users and Access** in App Store Connect
2. Click **"Keys"** tab
3. Click **"Generate"** under **App-Specific Shared Secret**
4. **Name:** Screen Time Copilot Receipt Validation
5. Click **"Generate"**
6. **⚠️ IMPORTANT:** Copy the shared secret immediately
   - You can only see it once!
   - Save it securely (use password manager)
   - This is used for receipt validation

---

## 📝 Step 5: Environment Variables

### Gather All Apple Credentials

You'll need:
- ✅ **Bundle ID:** `com.campbell.ScreenTimeCopilot`
- ✅ **Services ID:** `com.campbell.ScreenTimeCopilot.backend`
- ✅ **Team ID:** `ABCD1234EF` (from Membership)
- ✅ **Key ID:** `XYZ987ABC` (from the key you created)
- ✅ **Private Key:** Contents of the `.p8` file (see below)
- ✅ **Shared Secret:** From App Store Connect

### Format Private Key for Environment Variable

The `.p8` file looks like:
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
... (more base64 content) ...
-----END PRIVATE KEY-----
```

For environment variables, replace newlines with `\n`:
```
-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----
```

### Local Development (.env)

Add to `backend/.env`:
```bash
# Apple Developer Configuration
APPLE_BUNDLE_ID="com.campbell.ScreenTimeCopilot"
APPLE_CLIENT_ID="com.campbell.ScreenTimeCopilot.backend"
APPLE_TEAM_ID="ABCD1234EF"
APPLE_KEY_ID="XYZ987ABC"
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----"
APPLE_SHARED_SECRET="your-app-specific-shared-secret-from-app-store-connect"
```

### Production (Vercel)

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Add each variable (Production environment):

   | Key | Value | Environment |
   |-----|-------|-------------|
   | `APPLE_BUNDLE_ID` | `com.campbell.ScreenTimeCopilot` | Production |
   | `APPLE_CLIENT_ID` | `com.campbell.ScreenTimeCopilot.backend` | Production |
   | `APPLE_TEAM_ID` | `ABCD1234EF` | Production |
   | `APPLE_KEY_ID` | `XYZ987ABC` | Production |
   | `APPLE_PRIVATE_KEY` | (private key with `\n`) | Production |
   | `APPLE_SHARED_SECRET` | (shared secret) | Production |

5. **Important:** For `APPLE_PRIVATE_KEY`, replace actual newlines with `\n`

---

## 📱 Step 6: iOS App Configuration

### Update Xcode Project

1. Open `ScreenTimeBudget.xcodeproj` in Xcode
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. **Bundle Identifier:** Must match your App ID exactly
   - `com.campbell.ScreenTimeCopilot`
5. **Team:** Select your development team
6. **Signing Certificate:** Automatic (Xcode will handle)
7. **Capabilities:**
   - Click **"+ Capability"**
   - Add **"Sign In with Apple"**

### Update Info.plist

Add your Services ID (for backend authentication):

1. Open `Info.plist`
2. Add key: `SignInWithAppleClientID`
3. Value: `com.campbell.ScreenTimeCopilot.backend`

Or add to your entitlements file if using one.

### Update StoreKit Configuration (Testing)

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. **Run** → **Options** tab
3. **StoreKit Configuration:** Create new file
   - **Product ID:** `com.campbell.ScreenTimeCopilot.premium.monthly`
   - **Type:** Auto-Renewable Subscription
   - **Duration:** 1 Month
   - **Price:** $0.99
   - **Free Trial:** 7 Days

---

## 🧪 Step 7: Testing with Sandbox

### Create Sandbox Test Account

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Users and Access** → **Sandbox** tab
3. Click **"+"** to create test user
4. Fill in:
   - **Email:** Use a test email (e.g., `test1@example.com`)
   - **Password:** Create a strong password
   - **First Name:** Test
   - **Last Name:** User
   - **Country:** United States
5. Click **"Invite"** (no email is sent, account is ready immediately)

### Test Sign In with Apple

1. On your iOS device:
   - Go to **Settings** → **App Store**
   - Sign out of your regular Apple ID
   - (You'll sign in with sandbox account when prompted)
2. Run your app in Xcode
3. Tap **"Sign In with Apple"**
4. Use sandbox account credentials when prompted

### Test In-App Purchase

1. Sign in to sandbox account on device:
   - **Settings** → **App Store** → Sign out
   - Try to purchase in your app
   - Sign in with sandbox account when prompted
2. Test purchase flow:
   - App should show subscription options
   - Select subscription
   - Complete purchase with sandbox account
   - Verify receipt validation works
   - Check subscription status in app

---

## ✅ Step 8: Verify Setup

### Checklist

- [ ] Apple Developer account enrolled ($99/year)
- [ ] App ID created with Sign In with Apple enabled
- [ ] Services ID created and configured
- [ ] Private key created and downloaded (`.p8` file)
- [ ] Team ID noted
- [ ] App Store Connect app created
- [ ] In-App Purchase subscription created with 7-day free trial
- [ ] Shared secret generated
- [ ] Environment variables set (local and Vercel)
- [ ] Xcode project configured with correct Bundle ID
- [ ] Sign In with Apple capability added
- [ ] Sandbox test account created
- [ ] Tested Sign In with Apple flow
- [ ] Tested subscription purchase flow

---

## 🔍 Troubleshooting

### "Invalid Client" Error

- ✅ Verify `APPLE_CLIENT_ID` matches your Services ID exactly
- ✅ Check Services ID is configured with correct return URLs
- ✅ Ensure domain is added to Services ID configuration

### "Invalid Token" Error

- ✅ Verify `APPLE_PRIVATE_KEY` format (newlines as `\n`)
- ✅ Check `APPLE_KEY_ID` matches the key you created
- ✅ Ensure `APPLE_TEAM_ID` is correct
- ✅ Verify key has "Sign In with Apple" capability enabled

### Receipt Validation Fails

- ✅ Check `APPLE_SHARED_SECRET` is correct (App-Specific Shared Secret)
- ✅ Verify Product ID matches exactly: `com.campbell.ScreenTimeCopilot.premium.monthly`
- ✅ Ensure using correct environment (sandbox vs production)
- ✅ Check receipt format is correct

### Subscription Not Found

- ✅ Verify Product ID matches exactly
- ✅ Check subscription is in "Ready to Submit" status
- ✅ Ensure subscription group is configured
- ✅ Verify free trial is set up correctly

### Sign In with Apple Not Working

- ✅ Verify Bundle ID matches App ID exactly
- ✅ Check Sign In with Apple capability is enabled in Xcode
- ✅ Ensure Services ID is configured correctly
- ✅ Test with sandbox account first

---

## 📚 Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation)
- [Sign In with Apple Guide](https://developer.apple.com/sign-in-with-apple/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [Receipt Validation Guide](https://developer.apple.com/documentation/appstorereceipts)

---

## 🎯 Next Steps

1. ✅ Complete App Store Connect listing
2. ✅ Test with sandbox accounts
3. ✅ Submit for TestFlight beta testing
4. ✅ Submit for App Store review
5. ✅ Monitor subscription analytics in App Store Connect

---

**Your Apple Developer setup is complete!** 🎉

