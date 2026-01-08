# 📱 Screen Time Budget

A comprehensive iOS app for tracking and managing screen time with intelligent budgeting, weekly goals, and insights.

---

## 🚀 Quick Start

### Deploy in 10 Minutes

1. **Deploy Database & Backend:**
   ```bash
   # See QUICKSTART.md for full guide
   cd backend
   npx prisma migrate deploy  # Deploy to Neon
   # Deploy to Vercel from GitHub
   ```

2. **Build for TestFlight:**
   ```bash
   open ios/ScreenTimeBudget.xcodeproj
   # Product → Archive → Upload
   ```

See **[QUICKSTART.md](QUICKSTART.md)** for the complete 10-minute guide.

---

## 📚 Documentation

### Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** - Get up and running in 10 minutes ⚡
- **[DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md)** - Current deployment status
- **[test-production-api.sh](test-production-api.sh)** - Test your API

### Deployment Guides
- **[TESTFLIGHT_GUIDE.md](TESTFLIGHT_GUIDE.md)** - Complete TestFlight deployment walkthrough
- **[PRODUCTION_SETUP.md](PRODUCTION_SETUP.md)** - Production environment setup
- **[VERCEL_CHECKLIST.md](VERCEL_CHECKLIST.md)** - Vercel configuration reference

### Architecture & Technical
- **[PRODUCTION_ARCHITECTURE.md](PRODUCTION_ARCHITECTURE.md)** - Full system architecture
- **[VERCEL_ARCHITECTURE.md](VERCEL_ARCHITECTURE.md)** - Vercel serverless architecture

---

## 🏗️ Architecture

```
iOS App (SwiftUI)
    ↓ HTTPS
Vercel Edge Network
    ↓
Express.js API (Serverless)
    ↓
Neon PostgreSQL (Serverless)
```

### Project Structure
```
screen-budget/
├── ios/                          # iOS app (SwiftUI)
│   └── ScreenTimeBudget/
│       ├── Models/               # Data models
│       ├── Views/                # SwiftUI views
│       ├── ViewModels/           # Business logic
│       ├── Services/             # API, Screen Time
│       └── Utilities/            # Helpers, constants
│
├── backend/                      # Express API
│   ├── api/                      # Serverless functions
│   │   └── index.ts              # Main API handler
│   ├── src/
│   │   ├── routes/               # API routes
│   │   ├── controllers/          # Business logic
│   │   ├── middleware/           # Auth, errors
│   │   └── config/               # Database config
│   ├── prisma/
│   │   ├── schema.prisma         # Database schema
│   │   └── migrations/           # Migration history
│   └── vercel.json               # Vercel config
│
└── docs/                         # Documentation
    ├── QUICKSTART.md
    ├── TESTFLIGHT_GUIDE.md
    └── ... (more guides)
```

---

## 🛠️ Tech Stack

### iOS (Frontend)
- **Language:** Swift 5.9+
- **Framework:** SwiftUI (iOS 17+)
- **Architecture:** MVVM
- **APIs:** Screen Time API, URLSession, Combine
- **Storage:** Keychain, UserDefaults

### Backend (API)
- **Runtime:** Node.js 24.x
- **Framework:** Express.js 4.18+
- **Language:** TypeScript 5.0+
- **ORM:** Prisma 5.22+
- **Database:** PostgreSQL (via Neon)
- **Deployment:** Vercel Serverless Functions

### Database
- **Provider:** Neon (Serverless PostgreSQL)
- **Schema:** 12 tables
- **Features:** Auto-scaling, connection pooling, backups

---

## 📋 Features

- ✅ Screen time tracking by app category
- ✅ Budget-based controls (daily/monthly)
- ✅ Real-time usage syncing
- ✅ Budget overage notifications
- ✅ Weekly goals and insights
- ✅ Break reminders
- ✅ Streaks and achievements
- ✅ iOS App Store subscriptions

---

## 🚦 Current Status

✅ **Backend:** Deployed and running at https://screen-copilot-ysge.vercel.app

✅ **Database:** Neon PostgreSQL configured with full schema

✅ **iOS App:** Ready for TestFlight archive

⏳ **Environment Variables:** Being added by user

📋 **Next:** Test API → Archive iOS app → Upload to TestFlight

See [DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md) for complete status.

---

## 🧪 Testing

Test the production API:
```bash
chmod +x test-production-api.sh
./test-production-api.sh
```

---

## 💰 Costs

**Monthly (estimated):**
- Vercel Pro: ~$20-35
- Neon: $0-19 (free tier → paid)
- Apple Developer: ~$8.25 ($99/year)

**Total: ~$28-62/month**

---

## 📞 Support

- **Production API:** https://screen-copilot-ysge.vercel.app
- **Health Check:** https://screen-copilot-ysge.vercel.app/health
- **Issues:** https://github.com/campbellerickson/screen-copilot/issues
- **Documentation:** See guides above

---

*Ready to deploy? Start with [QUICKSTART.md](QUICKSTART.md)!*
