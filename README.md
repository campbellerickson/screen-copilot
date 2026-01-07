# 📱 Screen Budget - iOS App

A modern iOS app for tracking and managing screen time with budget-based controls, built with SwiftUI and Supabase.

---

## 🚀 Quick Start

### For Local Development (Current Branch: `local-testing`)

1. **Start local database and backend:**
   ```bash
   ./scripts/start-local.sh
   ```

2. **Open iOS app in Xcode:**
   ```bash
   open ios/ScreenTimeBudget.xcodeproj
   ```

3. **Build and run!**

See [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) for detailed local setup.

### For Production (Branch: `main`)

1. **Set up Supabase database:**
   - Run `backend/ALL_MIGRATIONS.sql` in Supabase SQL Editor
   - See [docs/SETUP.md](docs/SETUP.md) for details

2. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy
   ```

3. **Update iOS app URL:**
   - Edit `ios/ScreenTimeBudget/Utilities/Constants.swift`
   - Set to your Supabase project URL

---

## 📚 Documentation

All documentation is in the `docs/` folder:

- **[Documentation Index](docs/README.md)** - Complete documentation index
- **[Local Development](docs/LOCAL_DEVELOPMENT.md)** - Local setup guide
- **[Setup Guide](docs/SETUP.md)** - Production setup with Supabase
- **[Architecture](docs/ARCHITECTURE.md)** - System architecture
- **[API Documentation](docs/API.md)** - API endpoints reference
- **[TestFlight Guide](docs/TESTFLIGHT_GUIDE.md)** - iOS TestFlight setup

---

## 🏗️ Project Structure

```
screen-budget/
├── ios/                    # iOS app (SwiftUI)
│   └── ScreenTimeBudget/
├── backend/                # Express backend (for local testing)
│   ├── src/
│   └── prisma/
├── supabase/               # Supabase Edge Functions (production)
│   ├── functions/
│   └── config.toml
└── docs/                   # All documentation
```

---

## 🛠️ Tech Stack

- **iOS:** SwiftUI, StoreKit 2, Screen Time API
- **Backend (Local):** Express.js, Node.js
- **Backend (Production):** Supabase Edge Functions (Deno)
- **Database:** PostgreSQL
- **Authentication:** Supabase Auth (production) / Custom JWT (local)
- **Subscriptions:** Apple App Store (StoreKit)

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

## 🔧 Development

### Branches

- **`local-testing`** - Local development with local database
- **`main`** - Production with Supabase

### Local Development

```bash
# Start everything
./scripts/start-local.sh

# Or manually:
cd backend
docker-compose up -d
npm run dev
```

### Production Deployment

See [docs/SETUP.md](docs/SETUP.md) for Supabase setup and deployment.

---

## 📝 License

MIT License

---

## 🤝 Contributing

[Contributing Guidelines]

---

**Built with ❤️ for better screen time management**
