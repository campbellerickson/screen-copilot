# Quick Start Guide

Get Screen Time Budget up and running in production in 10 minutes.

---

## Prerequisites

- [x] Apple Developer Account ($99/year)
- [x] Vercel Account (free tier works)
- [x] Neon Database Account (free tier works)
- [x] Xcode 15+ installed
- [x] Git repository cloned

---

## Step 1: Database Setup (2 minutes)

### Create Neon Database

1. Go to https://neon.tech
2. Create new project: `screen-copilot-production`
3. Copy the connection string (starts with `postgresql://`)
4. Run migrations:

```bash
cd backend
# Create .env file with your connection string
echo 'DATABASE_URL="<your-neon-connection-string>"' > .env

# Run migrations
npx prisma migrate deploy
```

✅ **Checkpoint**: Database should have 12 tables created

---

## Step 2: Backend Deployment (3 minutes)

### Deploy to Vercel

1. Go to https://vercel.com
2. Click "Add New" → "Project"
3. Import from GitHub: `campbellerickson/screen-copilot`
4. Configure:
   - **Root Directory**: `backend`
   - **Framework Preset**: Other
   - **Build Command**: (leave blank)
   - **Install Command**: `npm install`

5. Add Environment Variables:
   ```
   DATABASE_URL=<your-neon-connection-string>
   JWT_SECRET=<run: openssl rand -base64 64>
   NODE_ENV=production
   CORS_ORIGIN=*
   APPLE_BUNDLE_ID=com.campbell.ScreenTimeCopilot
   ```

6. Click "Deploy"

7. Wait 2-3 minutes for deployment

✅ **Checkpoint**: Visit `https://your-app.vercel.app/health` - should return `{"status":"ok"}`

---

## Step 3: iOS App Configuration (2 minutes)

### Update Production URL

1. Open `ios/ScreenTimeBudget/Utilities/Constants.swift`
2. Verify production URL is correct:
   ```swift
   static let baseURL = "https://your-app.vercel.app/api/v1"
   ```
3. Open project in Xcode
4. Update version: **General** → **Version** → `1.0`
5. Update build: **General** → **Build** → `1`

✅ **Checkpoint**: Production URL points to your Vercel deployment

---

## Step 4: Test Production API (1 minute)

Run the test script:

```bash
chmod +x test-production-api.sh
./test-production-api.sh
```

You should see:
```
✓ PASS: Health Check
✓ PASS: User Signup
✓ PASS: User Login
✓ PASS: Get Current User (unauthenticated)
...
```

✅ **Checkpoint**: All endpoints responding correctly

---

## Step 5: Build for TestFlight (2 minutes)

### Archive and Upload

1. In Xcode, select **Any iOS Device**
2. Go to **Product** → **Archive**
3. Wait for archive to complete
4. Click **Distribute App**
5. Select **App Store Connect** → **Upload**
6. Click **Upload**

✅ **Checkpoint**: Build uploading to App Store Connect

---

## Verification Checklist

Before releasing to TestFlight, verify:

- [ ] `/health` endpoint returns `{"status":"ok"}`
- [ ] Can create new user via `/api/v1/auth/signup`
- [ ] Can login via `/api/v1/auth/login`
- [ ] iOS app has correct production URL
- [ ] Version is `1.0`, build is `1`
- [ ] Archive uploaded successfully

---

## What's Next?

### Wait for TestFlight Processing (10-30 minutes)

1. Go to App Store Connect → TestFlight
2. Wait for "Processing" to complete
3. Answer export compliance question
4. Add beta testers

### Invite Testers

1. TestFlight → Internal Testing
2. Create group: "Beta Testers"
3. Add emails
4. Testers receive invitation

### Monitor

- **Crash Reports**: App Store Connect → TestFlight → Crashes
- **API Logs**: Vercel Dashboard → Functions → Logs
- **Database**: Neon Dashboard → Monitoring

---

## Troubleshooting

### Health endpoint returns 404
**Fix**: Check Vercel Root Directory is set to `backend`

### Database connection errors
**Fix**: Verify DATABASE_URL in Vercel environment variables

### iOS app can't connect
**Fix**: Verify Constants.swift has correct production URL

### Archive fails
**Fix**: Check signing certificate in Xcode → Signing & Capabilities

---

## Common Commands

```bash
# Test production API
./test-production-api.sh

# Check Vercel deployment
vercel --prod

# Run migrations
cd backend && npx prisma migrate deploy

# Generate Prisma client
cd backend && npx prisma generate

# Open Xcode
open ios/ScreenTimeBudget.xcodeproj
```

---

## Production URLs

- **API**: https://screen-copilot-ysge.vercel.app
- **Health Check**: https://screen-copilot-ysge.vercel.app/health
- **Vercel Dashboard**: https://vercel.com/campbellericksons-projects/screen-copilot-ysge
- **Neon Dashboard**: https://console.neon.tech
- **App Store Connect**: https://appstoreconnect.apple.com

---

## Support

**Documentation:**
- Full deployment guide: `TESTFLIGHT_GUIDE.md`
- Architecture docs: `PRODUCTION_ARCHITECTURE.md`
- Vercel checklist: `VERCEL_CHECKLIST.md`

**Issues:**
- GitHub: https://github.com/campbellerickson/screen-copilot/issues

---

*You should be ready for TestFlight in under 10 minutes!*
