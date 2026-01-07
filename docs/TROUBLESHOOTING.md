# 🐛 Troubleshooting Guide

Common issues and solutions for local development.

---

## Docker Issues

### Docker Desktop Not Running

**Symptom:** `docker: command not found` or connection errors

**Solution:**
1. Open Docker Desktop application
2. Wait for it to fully start (whale icon in menu bar)
3. Try again: `./scripts/start-local.sh`

### Database Won't Start

**Symptom:** `docker-compose up` fails or database container exits

**Solution:**
```bash
cd backend

# Check Docker is running
docker ps

# Check logs
docker-compose logs postgres

# Restart
docker-compose down
docker-compose up -d

# Check if port 5432 is in use
lsof -i :5432
```

---

## Backend Issues

### Port 3000 Already in Use

**Symptom:** `Error: listen EADDRINUSE: address already in use :::3000`

**Solution:**
```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process
kill -9 [PID]

# Or change port in backend/.env.local
PORT=3001
```

### Backend Won't Start

**Symptom:** Server crashes or won't start

**Solution:**
```bash
cd backend

# Check dependencies
npm install

# Check environment variables
cat .env.local

# Check for errors
npm run dev
```

### Database Connection Errors

**Symptom:** `Can't reach database server` or Prisma errors

**Solution:**
```bash
# Make sure database is running
cd backend
docker-compose ps

# Test connection
psql postgresql://postgres:postgres@localhost:5432/screen_budget -c "SELECT 1;"

# If connection fails, restart database
docker-compose restart
```

---

## iOS App Issues

### Can't Connect from Simulator

**Symptom:** Network errors in iOS app

**Solution:**
1. Check backend is running: `curl http://localhost:3000/health`
2. Verify `Constants.swift` has: `http://localhost:3000/api/v1`
3. Check Xcode console for errors

### Can't Connect from Physical Device

**Symptom:** Network errors on iPhone

**Solution:**
1. **Check Mac's IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. **Update Constants.swift:**
   ```swift
   static let baseURL = "http://[YOUR-MAC-IP]:3000/api/v1"
   ```

3. **Check Mac's Firewall:**
   - System Settings → Network → Firewall
   - Allow incoming connections for Node.js

4. **Verify same WiFi:**
   - Mac and iPhone must be on same network

5. **Test from iPhone browser:**
   - Open Safari on iPhone
   - Go to: `http://[MAC-IP]:3000/health`
   - Should see JSON response

---

## Database Issues

### Migrations Fail

**Symptom:** `Prisma migrate deploy` errors

**Solution:**
```bash
cd backend

# Make sure database is running
docker-compose ps

# Reset and retry
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma migrate reset
npx prisma migrate deploy
```

### Can't Access Prisma Studio

**Symptom:** `npx prisma studio` won't open

**Solution:**
```bash
cd backend
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"
npx prisma studio
```

If it still fails, check database is running and connection string is correct.

---

## General Issues

### Scripts Won't Run

**Symptom:** `Permission denied` when running scripts

**Solution:**
```bash
chmod +x scripts/*.sh
```

### Environment Variables Not Loading

**Symptom:** Backend uses wrong database URL

**Solution:**
1. Check `backend/.env.local` exists
2. Verify `DATABASE_URL` is set correctly
3. Restart backend server

### Xcode Won't Build

**Symptom:** Build errors in Xcode

**Solution:**
1. Clean build folder: Cmd+Shift+K
2. Restart Xcode
3. Check for missing dependencies
4. Verify API URL in `Constants.swift`

---

## Quick Diagnostics

### Check Everything is Running

```bash
# Check Docker
docker ps

# Check backend
curl http://localhost:3000/health

# Check database
psql postgresql://postgres:postgres@localhost:5432/screen_budget -c "SELECT 1;"
```

### Reset Everything

```bash
# Stop everything
cd backend
docker-compose down

# Remove database volume (deletes all data)
docker volume rm backend_postgres_data

# Start fresh
./scripts/start-local.sh
```

---

## Still Having Issues?

1. Check terminal logs for error messages
2. Check Xcode console for iOS errors
3. Verify all prerequisites are installed
4. Review [Local Development Guide](LOCAL_DEVELOPMENT.md)

---

**Need more help?** Check the full documentation in `docs/` folder.

