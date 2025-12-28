# Screen Budget - Launch Instructions

## Required Setup: Database Connections & API Keys

This document lists **all required database connections and API keys** needed to launch both development and production environments.

---

## Development Environment Setup

### Required: PostgreSQL Database

#### Option 1: Docker (Recommended)

**No API keys needed** - Just Docker installed

```bash
cd backend

# Start PostgreSQL container (credentials in docker-compose.yml)
docker-compose up -d

# Credentials are:
# User: postgres
# Password: postgres
# Database: copilot_screentime
# Port: 5432
```

**Connection String:**
```
postgresql://postgres:postgres@localhost:5432/copilot_screentime?schema=public
```

#### Option 2: Native PostgreSQL Installation

**Prerequisites:**
- PostgreSQL 15+ installed on your system

**Setup:**
```bash
# Create database
createdb copilot_screentime

# Create user (if needed)
createuser -P postgres  # Set password when prompted
```

**Connection String:**
```
postgresql://postgres:YOUR_PASSWORD@localhost:5432/copilot_screentime?schema=public
```

### Required: Environment Variables

Create `backend/.env` file with these values:

```env
# Database Connection (use connection string from above)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/copilot_screentime?schema=public"

# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Secret (any random string for dev)
JWT_SECRET=dev-secret-key-change-in-production-123456

# CORS (allow all in dev)
CORS_ORIGIN=*
```

**No external API keys required for MVP!**

### Initialize Database

```bash
cd backend

# Install dependencies
npm install

# Generate Prisma client
npm run prisma:generate

# Run migrations (creates all tables)
npm run prisma:migrate

# Start server
npm run dev
```

Verify: `curl http://localhost:3000/health`

Expected: `{"status":"ok","timestamp":"..."}`

---

## Production Environment Setup

### Required: Production PostgreSQL Database

You'll need ONE of these:

#### Option 1: Railway.app (Easiest)

**Required:**
- Railway account (sign up at railway.app)
- GitHub account

**API Keys Needed:** None (OAuth via GitHub)

**Setup:**
1. Create Railway account
2. Create new project
3. Add PostgreSQL database
4. Railway auto-generates `DATABASE_URL`
5. Copy the connection string

**Connection String Format:**
```
postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/railway
```

**Cost:** ~$5/month

#### Option 2: Heroku Postgres

**Required:**
- Heroku account
- Heroku CLI installed

**API Keys Needed:** Heroku API token (auto-generated on login)

**Setup:**
```bash
heroku login  # Generates API token automatically
heroku addons:create heroku-postgresql:mini
heroku config:get DATABASE_URL  # Copy this value
```

**Cost:** ~$9/month

#### Option 3: AWS RDS

**Required:**
- AWS account
- AWS Access Key ID
- AWS Secret Access Key

**API Keys Needed:**
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

**Setup:**
1. Go to AWS RDS console
2. Create PostgreSQL database (db.t3.micro)
3. Configure security groups (allow inbound 5432)
4. Note connection details

**Connection String:**
```
postgresql://[USERNAME]:[PASSWORD]@[ENDPOINT]:5432/copilot_screentime
```

**Cost:** ~$15/month

#### Option 4: DigitalOcean Managed Database

**Required:**
- DigitalOcean account
- DigitalOcean API token

**API Keys Needed:**
- DO_API_TOKEN (create in dashboard)

**Setup:**
1. Create managed PostgreSQL database ($15/month basic)
2. Add trusted sources (your server IP)
3. Copy connection string

**Cost:** $15/month

### Required: Production Environment Variables

Create production `.env` or configure in hosting dashboard:

```env
# Database Connection (from above)
DATABASE_URL="postgresql://[user]:[pass]@[host]:[port]/[database]"

# Server Configuration
PORT=3000
NODE_ENV=production

# JWT Secret (MUST BE SECURE!)
JWT_SECRET=<GENERATE_SECURE_RANDOM_STRING>

# CORS (your frontend domain)
CORS_ORIGIN=https://your-domain.com
```

**Generate Secure JWT_SECRET:**
```bash
# On Mac/Linux:
openssl rand -base64 32

# Or use online generator:
# https://randomkeygen.com/ (use "CodeIgniter Encryption Keys")
```

### Required: Hosting Service (for backend)

Choose ONE:

#### Option 1: Railway.app

**Required:**
- Railway account
- GitHub repository

**API Keys:** None

**Setup:**
1. Push code to GitHub
2. Connect Railway to repository
3. Set environment variables in dashboard
4. Deploy

**Cost:** $5/month (includes database)

#### Option 2: Heroku

**Required:**
- Heroku account
- Heroku API token (auto-generated)

**Setup:**
```bash
heroku create screen-budget-api
heroku config:set DATABASE_URL="..."
heroku config:set JWT_SECRET="..."
heroku config:set NODE_ENV=production
git push heroku main
```

**Cost:** $7/month dyno + $9/month database = $16/month

#### Option 3: DigitalOcean App Platform

**Required:**
- DigitalOcean account
- DO API token

**Setup:**
1. Create app from GitHub
2. Set environment variables
3. Deploy

**Cost:** $5/month basic

---

## iOS Development Setup

### Required: Apple Developer Account

**For Development (Testing on Device):**
- **Not required** - Can use free Apple ID for local testing
- Limited to 7 days code signing
- Can't distribute via TestFlight

**For Production (App Store):**
- **Required** - Apple Developer Program
- **Cost:** $99/year
- **Sign up:** developer.apple.com/programs

### Required: Xcode

**Free download** from Mac App Store
- Version 15.0 or higher
- Includes all required iOS frameworks

**No API keys needed!**

### Required: App Groups

**Setup in Xcode:**
1. Select project → Target → Signing & Capabilities
2. Add "App Groups" capability
3. Create group: `group.com.copilot.screentime`

**For production:**
- Must create in Apple Developer Portal
- No API key needed, just Developer Account

### Optional: Analytics Service

**Not required for MVP**, but recommended for production:

#### Mixpanel (Recommended)

**Required:**
- Mixpanel account (free tier available)
- Mixpanel Project Token

**Setup:**
1. Create Mixpanel account
2. Create project
3. Copy project token
4. Add to `Analytics.swift`:

```swift
static func initialize() {
    Mixpanel.initialize(token: "YOUR_MIXPANEL_TOKEN")
}
```

**Cost:** Free up to 100k events/month

#### Amplitude (Alternative)

**Required:**
- Amplitude account
- Amplitude API Key

**Cost:** Free up to 10M events/month

### Optional: Push Notifications

**Not required for MVP** (using local notifications only)

For remote notifications in future:
- Apple Push Notification service (APNs)
- Push certificate from Apple Developer Portal
- No API key needed (uses certificates)

---

## Required Third-Party Services Summary

### Minimum Required (Free/Low Cost)

| Service | Purpose | Required? | Cost | API Key Needed? |
|---------|---------|-----------|------|-----------------|
| **PostgreSQL** | Database | ✅ Yes | Docker: Free<br>Railway: $5/mo | No |
| **Node.js hosting** | Backend API | ✅ Yes | Railway: $5/mo | No |
| **Xcode** | iOS development | ✅ Yes | Free | No |
| **Apple Developer** | App Store | Only for production | $99/year | No (uses certificates) |

**Total minimum cost for production:** ~$160/year ($5/mo hosting + $99/yr Apple)

### Optional Services (Not Required for MVP)

| Service | Purpose | Required? | Cost | API Key Needed? |
|---------|---------|-----------|------|-----------------|
| Analytics (Mixpanel/Amplitude) | User analytics | ❌ No | Free tier | Yes (token) |
| Error tracking (Sentry) | Error monitoring | ❌ No | Free tier | Yes (DSN) |
| Email service (SendGrid) | Email notifications | ❌ No | Free tier | Yes (API key) |

---

## Complete Setup Checklist

### Development Environment

- [ ] **Install Node.js 18+**
  - Download: nodejs.org
  - No API key needed

- [ ] **Install Docker** (if using Docker for PostgreSQL)
  - Download: docker.com
  - No API key needed

- [ ] **Start PostgreSQL**
  ```bash
  cd backend
  docker-compose up -d
  ```

- [ ] **Create .env file**
  ```bash
  cp .env.example .env
  # Edit with PostgreSQL connection string
  ```

- [ ] **Install dependencies & migrate**
  ```bash
  npm install
  npm run prisma:migrate
  ```

- [ ] **Start backend server**
  ```bash
  npm run dev
  ```

- [ ] **Verify backend**
  ```bash
  curl http://localhost:3000/health
  ```

- [ ] **Install Xcode 15+**
  - Mac App Store (free)

- [ ] **Create Xcode project**
  - Follow ios/README.md
  - Enable capabilities (Family Controls, App Groups)

- [ ] **Update iOS API URL**
  - Edit `Constants.swift`
  - Set to `http://localhost:3000/api/v1` (simulator)
  - Or `http://YOUR-MAC-IP:3000/api/v1` (device)

- [ ] **Test on physical iPhone**
  - iOS 16.0+ required
  - Grant Screen Time permission

### Production Environment

- [ ] **Choose database provider**
  - Railway / Heroku / AWS RDS / DigitalOcean
  - Set up database
  - Copy connection string

- [ ] **Choose hosting provider**
  - Railway / Heroku / DigitalOcean
  - Connect GitHub repository
  - Set environment variables

- [ ] **Generate secure JWT_SECRET**
  ```bash
  openssl rand -base64 32
  ```

- [ ] **Configure production .env**
  - DATABASE_URL (from database provider)
  - JWT_SECRET (generated above)
  - NODE_ENV=production
  - CORS_ORIGIN (your domain)

- [ ] **Deploy backend**
  - Push to GitHub
  - Hosting service auto-deploys
  - Run migrations

- [ ] **Verify production API**
  ```bash
  curl https://your-api-domain.com/health
  ```

- [ ] **Enroll in Apple Developer Program**
  - $99/year
  - developer.apple.com/programs

- [ ] **Update iOS production API URL**
  - Edit `Constants.swift`
  - Set production URL

- [ ] **Create App Groups in Apple Developer Portal**
  - Identifier: `group.com.copilot.screentime`

- [ ] **Archive and submit to App Store**
  - Product → Archive in Xcode
  - Upload to App Store Connect
  - Complete App Store listing
  - Submit for review

---

## API Keys Needed - Complete List

### Development (Minimal)
1. **None!** - PostgreSQL runs locally via Docker

### Production (Minimal)
1. **None!** - If using Railway (provides everything)
2. **JWT_SECRET** - Generate with: `openssl rand -base64 32`

### Production (Optional)
3. **Mixpanel Token** - If using analytics
4. **Sentry DSN** - If using error tracking
5. **SendGrid API Key** - If adding email features

### iOS (All Environments)
1. **None!** - Screen Time APIs don't require API keys
2. **Apple Developer Account** - Only for App Store distribution ($99/year)

---

## Database Connection Strings - Quick Reference

### Development (Docker)
```
postgresql://postgres:postgres@localhost:5432/copilot_screentime?schema=public
```

### Railway (Production)
```
postgresql://postgres:[AUTO_GENERATED]@[HOST].railway.app:[PORT]/railway
```
*Auto-populated when you add PostgreSQL database*

### Heroku (Production)
```
postgresql://[USER]:[PASS]@[HOST].compute.amazonaws.com:5432/[DB]
```
*Get via: `heroku config:get DATABASE_URL`*

### AWS RDS (Production)
```
postgresql://[USERNAME]:[PASSWORD]@[ENDPOINT].rds.amazonaws.com:5432/copilot_screentime
```

### DigitalOcean (Production)
```
postgresql://[USER]:[PASS]@[HOST]:25060/[DB]?sslmode=require
```

---

## Help & Support

**Can't connect to database?**
- Verify PostgreSQL is running: `docker ps | grep postgres`
- Check connection string in `.env`
- Try: `psql "postgresql://postgres:postgres@localhost:5432/copilot_screentime"`

**Backend won't start?**
- Check Node.js version: `node --version` (need 18+)
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check Prisma: `npm run prisma:generate`

**iOS app can't connect to backend?**
- Verify backend running: `curl http://localhost:3000/health`
- Check `Constants.swift` has correct URL
- Physical device needs Mac's IP (not localhost)
- Ensure same WiFi network

**Need help?**
- See detailed docs: `docs/SETUP.md`
- See API reference: `docs/API.md`
- See troubleshooting: `docs/DEPLOYMENT.md`

---

## Next Steps

1. ✅ Set up development database (Docker)
2. ✅ Configure environment variables (.env)
3. ✅ Run backend and test endpoints
4. ✅ Create Xcode project and copy Swift files
5. ✅ Test on physical iPhone
6. 📦 Deploy to production when ready
7. 🚀 Submit to App Store

**You're all set! Everything is configured to run without external API keys in development.**

For production, you only need:
- Database hosting ($5-15/month)
- Backend hosting ($5-7/month)
- Apple Developer account ($99/year for App Store)

Total: **~$160-280/year** for production
