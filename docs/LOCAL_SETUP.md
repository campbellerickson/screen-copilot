# 🏠 Local Development Setup - Quick Start

## ✅ Branch Created

You're now on the `local-testing` branch, configured for local development.

---

## 🚀 Quick Start (3 Steps)

### 1. Start Database & Backend

```bash
./scripts/start-local.sh
```

This will:
- Start PostgreSQL in Docker
- Run database migrations
- Start the backend server on `http://localhost:3000`

### 2. Update iOS App URL (if using physical device)

If testing on a **physical iPhone**, update `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
// Replace [YOUR-MAC-IP] with your Mac's IP address
static let baseURL = "http://[YOUR-MAC-IP]:3000/api/v1"
```

To find your Mac's IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**For iOS Simulator**, it's already set to `http://localhost:3000/api/v1` ✅

### 3. Build & Run iOS App

1. Open `ios/ScreenTimeBudget.xcodeproj` in Xcode
2. Build and run
3. App will connect to local backend!

---

## 📋 Manual Setup (Alternative)

If the script doesn't work, do it manually:

```bash
# 1. Start database
cd backend
docker-compose up -d

# 2. Run migrations
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma migrate deploy
npx prisma generate

# 3. Start backend
npm install
npm run dev
```

---

## 🗄️ Database Management

### View Database (Prisma Studio)

```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma studio
```

Opens at `http://localhost:5555`

### Reset Database

```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma migrate reset
```

**Warning:** Deletes all data!

---

## 🧪 Test It Works

### Test Backend

```bash
curl http://localhost:3000/health
```

Should return:
```json
{
  "status": "ok",
  "timestamp": "...",
  "environment": "development"
}
```

### Test Signup

```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234",
    "name": "Test User"
  }'
```

---

## 🔄 Switching Branches

### Use Local (Current Branch)
```bash
git checkout local-testing
```
- Backend: `localhost:3000`
- Database: Local PostgreSQL

### Use Supabase (Production)
```bash
git checkout main
```
- Backend: Supabase Edge Functions
- Database: Supabase PostgreSQL

---

## 🐛 Troubleshooting

### Database won't start
```bash
# Check Docker is running
docker ps

# Restart database
cd backend
docker-compose restart
```

### Can't connect from iPhone
1. Mac and iPhone must be on same WiFi
2. Check Mac's firewall allows Node.js
3. Use Mac's IP address, not localhost
4. Test: Open `http://[MAC-IP]:3000/health` in iPhone browser

### Port 3000 in use
```bash
# Find what's using it
lsof -i :3000

# Kill it or change PORT in backend/.env.local
```

---

## 📝 Notes

- Local database is **separate** from Supabase
- Data is **not synced** between local and production
- Use local for **development**, Supabase for **production**
- `.env.local` is gitignored (safe to commit)

---

**Ready to code!** 🎉

