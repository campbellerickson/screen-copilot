# Screen Budget - Deployment Guide

**Last Updated:** January 4, 2026

This guide walks you through deploying your Screen Budget app to production.

---

## 📋 **Prerequisites Checklist**

Before deploying, make sure you have:

- ✅ GitHub account (you have this!)
- ✅ Code pushed to GitHub (done!)
- ⏳ Apple Developer Program membership ($99/year - pending approval)
- ⏳ Railway.app account (free - create now)

---

## 🗄️ **Step 1: Set Up Production Database (Railway.app)**

Railway offers free PostgreSQL hosting perfect for this app.

### **1.1: Create Railway Account**

1. Go to https://railway.app/
2. Click **"Login"**
3. Select **"Login with GitHub"**
4. Authorize Railway to access your GitHub

### **1.2: Create New Project**

1. Click **"New Project"**
2. Select **"Provision PostgreSQL"**
3. Railway creates a PostgreSQL database for you

### **1.3: Get Database Connection String**

1. Click on your **PostgreSQL service**
2. Go to **"Variables"** tab
3. Find `DATABASE_URL` - this is your connection string
4. Click the **copy icon** to copy it
5. **Save this somewhere safe!** Format looks like:
   ```
   postgresql://postgres:PASSWORD@monorail.proxy.rlwy.net:12345/railway
   ```

---

## 🚀 **Step 2: Deploy Backend to Railway**

### **2.1: Create Backend Service**

1. In the same Railway project, click **"+ New"**
2. Select **"GitHub Repo"**
3. Find and select your **`screen-budget`** repository
4. Railway will detect it's a Node.js app

### **2.2: Configure Build Settings**

1. Click on the **backend service**
2. Go to **"Settings"** tab
3. Set **Root Directory:** `backend`
4. Set **Build Command:** `npm install && npx prisma generate && npm run build`
5. Set **Start Command:** `npm start`

### **2.3: Set Environment Variables**

1. Go to **"Variables"** tab
2. Click **"+ New Variable"**
3. Add these variables:

```
DATABASE_URL = [paste your PostgreSQL URL from Step 1.3]
NODE_ENV = production
PORT = 3000
CORS_ORIGIN = *
```

### **2.4: Run Database Migrations**

1. Go to **"Deployments"** tab
2. Wait for deployment to succeed
3. Click **"View Logs"**
4. Once running, go to **"Settings"** → **"Deploy"**
5. Add migration command:
   - In Railway dashboard, click backend service
   - Go to Settings → Deploy
   - Under "Custom Start Command" add:
     ```
     npx prisma migrate deploy && npm start
     ```

### **2.5: Get Your Production API URL**

1. Go to **"Settings"** tab
2. Click **"Generate Domain"**
3. Railway generates a public URL like: `https://screen-budget-production.up.railway.app`
4. **Copy this URL** - you'll need it for the iOS app!

### **2.6: Test Your API**

```bash
curl https://YOUR-RAILWAY-URL.up.railway.app/health
```

You should see:
```json
{
  "status": "ok",
  "timestamp": "2026-01-04T...",
  "environment": "production"
}
```

---

## 📱 **Step 3: Update iOS App for Production**

### **3.1: Update Constants.swift**

Edit `/ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
struct Constants {
    // API Configuration
    #if DEBUG
    static let baseURL = "http://192.168.68.50:3000/api/v1"  // Local development
    #else
    static let baseURL = "https://YOUR-RAILWAY-URL.up.railway.app/api/v1"  // PRODUCTION
    #endif

    // ... rest of file
}
```

**Replace** `YOUR-RAILWAY-URL.up.railway.app` with your actual Railway URL from Step 2.5

### **3.2: Commit and Push**

```bash
git add ios/ScreenTimeBudget/Utilities/Constants.swift
git commit -m "Add production API URL"
git push origin main
```

---

## 🍎 **Step 4: TestFlight Setup (When Apple Developer is Approved)**

### **4.1: Wait for Apple Developer Approval**

You'll receive an email when your $99 Apple Developer enrollment is approved (24-48 hours).

### **4.2: Create App in App Store Connect**

1. Go to https://appstoreconnect.apple.com/
2. Click **"My Apps"**
3. Click **"+"** → **"New App"**
4. Fill out:
   - **Platform:** iOS
   - **Name:** Screen Budget
   - **Primary Language:** English
   - **Bundle ID:** `com.campbell.ScreenTimeBudget` (create if needed)
   - **SKU:** `screen-budget-001`
   - **User Access:** Full Access

### **4.3: Re-enable Family Controls**

Once Apple Developer is active:

1. **In Xcode:** Go to Signing & Capabilities
2. **Click "+" → Add "Family Controls"**
3. **Click "+" → Add "Push Notifications"**
4. Xcode will create new provisioning profiles

### **4.4: Archive and Upload**

1. In Xcode, select **"Any iOS Device"** as target (not simulator)
2. **Product → Archive**
3. Wait for archive to complete
4. **Window → Organizer**
5. Select your archive
6. Click **"Distribute App"**
7. Select **"App Store Connect"**
8. Select **"Upload"**
9. Follow the wizard (use defaults)
10. Click **"Upload"**

### **4.5: Configure TestFlight**

1. Go to **App Store Connect**
2. Click your app → **"TestFlight"** tab
3. The build will appear after processing (10-30 minutes)
4. Click on the build
5. Add **"What to Test"** notes
6. Enable for **"Internal Testing"**
7. Add your email as a tester
8. Check your email for TestFlight invite!

---

## 🔐 **Security Checklist**

Before going live:

- [ ] **Never commit `.env` files** (already in .gitignore)
- [ ] **Use environment variables** for all secrets
- [ ] **Enable CORS** only for your domain (not `*`)
- [ ] **Add rate limiting** to API
- [ ] **Set up monitoring** (Railway has built-in logs)
- [ ] **Add authentication** before public launch

---

## 🐛 **Troubleshooting**

### **Backend Won't Deploy**

**Problem:** Build fails on Railway

**Solutions:**
1. Check Railway logs for errors
2. Ensure `package.json` has `"engines": { "node": ">=18.0.0" }`
3. Verify DATABASE_URL is set correctly
4. Make sure `prisma generate` runs in build

### **iOS Can't Connect to API**

**Problem:** App shows network errors

**Solutions:**
1. Verify Railway domain is accessible: `curl https://your-url.up.railway.app/health`
2. Check `Constants.swift` has correct URL
3. Make sure URL uses `https://` not `http://`
4. Check Railway logs for incoming requests

### **Database Migrations Fail**

**Problem:** Prisma migrations don't run

**Solutions:**
1. Run manually: `npx prisma migrate deploy` in Railway console
2. Check DATABASE_URL format is correct
3. Verify PostgreSQL service is running

---

## 📊 **Monitoring & Maintenance**

### **View Logs**

**Railway:**
1. Click on backend service
2. Go to **"Deployments"**
3. Click **"View Logs"**

### **Database Management**

**Access Prisma Studio:**
```bash
cd backend
npx prisma studio
```

Then connect to production DB by temporarily setting:
```bash
DATABASE_URL="your-production-url" npx prisma studio
```

### **Check API Health**

Add to your monitoring:
```bash
# Check every 5 minutes
curl https://your-railway-url.up.railway.app/health
```

---

## 💰 **Costs**

| Service | Free Tier | Paid Tier |
|---------|-----------|-----------|
| **Railway** | $5 credit/month | $5 minimum/month |
| **Apple Developer** | N/A | $99/year (required) |
| **GitHub** | Unlimited public repos | N/A |

**Estimated Monthly Cost:** ~$5-10 (Railway) + $8.25/month (Apple Developer annual)

---

## 🎯 **Production Checklist**

Before announcing your app:

- [ ] Backend deployed and healthy
- [ ] Database migrations run successfully
- [ ] iOS app connects to production API
- [ ] TestFlight build uploaded
- [ ] Tested on TestFlight with real data
- [ ] Privacy policy created
- [ ] Terms of service created
- [ ] App Store listing complete
- [ ] Screenshots prepared (required: 6.7", 6.5", 5.5")
- [ ] App description written
- [ ] Keywords selected
- [ ] App icon finalized

---

## 📚 **Additional Resources**

- **Railway Docs:** https://docs.railway.app/
- **Prisma Docs:** https://www.prisma.io/docs
- **Apple Developer:** https://developer.apple.com/
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## ⏭️ **Next Steps**

1. ✅ **Right now:** Set up Railway database (Steps 1-2)
2. ⏳ **Today:** Update iOS app with production URL (Step 3)
3. ⏳ **After Apple approval:** TestFlight setup (Step 4)
4. 🎉 **Launch:** Submit to App Store!

---

**Need help?** Check Railway logs, GitHub issues, or the troubleshooting section above.

Good luck with your deployment! 🚀
