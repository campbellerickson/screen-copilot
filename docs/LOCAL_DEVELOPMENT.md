# 🏠 Local Development Guide

Complete guide for local development with local database.

---

## 🎯 Overview

The `local-testing` branch is configured for local development:
- **Backend:** Express.js running on `localhost:3000`
- **Database:** Local PostgreSQL (Docker)
- **iOS App:** Connects to local backend

---

## 🚀 Quick Start

### Option 1: Automated Script (Recommended)

```bash
./scripts/start-local.sh
```

This script:
1. Starts PostgreSQL in Docker
2. Runs database migrations
3. Generates Prisma client
4. Starts the backend server

### Option 2: Manual Setup

```bash
# 1. Start database
cd backend
docker-compose up -d

# 2. Setup database
./scripts/setup-local-db.sh

# 3. Start backend
npm run dev
```

---

## 📱 iOS App Configuration

### For iOS Simulator

Already configured! The app uses:
```swift
static let baseURL = "http://localhost:3000/api/v1"
```

### For Physical iPhone

Update `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
// Uncomment for physical device:
static let baseURL = "http://192.168.68.67:3000/api/v1"
```

**Important:**
- Mac and iPhone must be on same WiFi
- Use your Mac's IP address (not localhost)
- Your Mac's IP: `192.168.68.67`

---

## 🗄️ Database Management

### View Database (Prisma Studio)

```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma studio
```

Opens at `http://localhost:5555` - visual database browser

### Reset Database

```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma migrate reset
```

**Warning:** This deletes all data and recreates the database!

### Create New Migration

```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma migrate dev --name your_migration_name
```

---

## 🧪 Testing

### Test Backend Health

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-05T...",
  "environment": "development"
}
```

### Test Signup Endpoint

```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234",
    "name": "Test User"
  }'
```

### Test in iOS App

1. Build and run app in Xcode
2. Try signing up with a test account
3. Verify data appears in Prisma Studio

---

## 🔧 Configuration

### Backend Port

Default: `3000`

Change in `backend/.env.local`:
```
PORT=3000
```

### Database Credentials

Default (in `docker-compose.yml`):
- **Host:** `localhost`
- **Port:** `5432`
- **Database:** `screen_budget`
- **Username:** `postgres`
- **Password:** `postgres`

To change, edit `backend/docker-compose.yml` and update `DATABASE_URL` in `.env.local`.

### Environment Variables

The backend automatically loads `backend/.env.local` if it exists, otherwise falls back to `.env`.

---

## 🐛 Troubleshooting

### Database Won't Start

```bash
# Check if Docker is running
docker ps

# Check database logs
cd backend
docker-compose logs postgres

# Restart database
docker-compose restart
```

### Can't Connect from iPhone

1. **Check Mac's Firewall:**
   - System Settings → Network → Firewall
   - Allow incoming connections for Node.js

2. **Verify Same WiFi:**
   - Mac and iPhone must be on the same network
   - Check WiFi network names match

3. **Test Connection:**
   ```bash
   # From Mac, test backend
   curl http://localhost:3000/health
   
   # From iPhone browser, try:
   # http://192.168.68.67:3000/health
   ```

4. **Check IP Address:**
   ```bash
   # Get Mac's IP
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

### Port 3000 Already in Use

```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process
kill -9 [PID]

# Or change PORT in backend/.env.local
```

### Prisma Migrations Fail

```bash
# Make sure database is running
docker ps | grep postgres

# Check connection
psql postgresql://postgres:postgres@localhost:5432/screen_budget -c "SELECT 1;"

# Try resetting
npx prisma migrate reset
```

### Backend Won't Start

```bash
# Check if dependencies are installed
cd backend
npm install

# Check environment variables
cat .env.local

# Check for errors
npm run dev
```

---

## 🔄 Switching Between Local and Supabase

### Use Local Database (Current Branch)

```bash
git checkout local-testing
```

- Backend: `localhost:3000` (Express.js)
- Database: Local PostgreSQL
- iOS app: Points to local backend

### Use Supabase (Production)

```bash
git checkout main
```

- Backend: Supabase Edge Functions
- Database: Supabase PostgreSQL
- iOS app: Points to Supabase

---

## 📝 Development Workflow

1. **Start Local Environment:**
   ```bash
   ./scripts/start-local.sh
   ```

2. **Open Xcode:**
   ```bash
   open ios/ScreenTimeBudget.xcodeproj
   ```

3. **Make Changes:**
   - Edit Swift files in Xcode
   - Edit backend files in your editor
   - Backend auto-reloads with nodemon

4. **Test Changes:**
   - Build and run in Xcode
   - Test functionality
   - Check Prisma Studio for data

5. **Commit Changes:**
   ```bash
   git add .
   git commit -m "Your changes"
   ```

---

## 🎯 Tips

- **Use Prisma Studio** to view/edit data visually
- **Keep backend running** while developing iOS app
- **Use iOS Simulator** for faster iteration (no IP needed)
- **Check backend logs** in terminal for debugging
- **Reset database** if schema changes break things

---

## 📚 Related Documentation

- [Setup Guide](SETUP.md) - Supabase production setup
- [Architecture](ARCHITECTURE.md) - System architecture
- [API Documentation](API.md) - API endpoints

---

**Happy coding!** 🚀
