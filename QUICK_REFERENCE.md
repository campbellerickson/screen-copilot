# ⚡ Quick Reference

## 🏠 Local Testing Branch

You're on the `local-testing` branch - configured for local development.

---

## 🚀 Start Development (One Command)

```bash
./scripts/start-local.sh
```

This starts:
- ✅ PostgreSQL database (Docker)
- ✅ Database migrations
- ✅ Backend server (`localhost:3000`)

---

## 📱 iOS App URLs

**Simulator:**
```
http://localhost:3000/api/v1
```

**Physical Device:**
```
http://192.168.68.67:3000/api/v1
```

Update in: `ios/ScreenTimeBudget/Utilities/Constants.swift`

---

## 🗄️ Database

**Connection:**
```
postgresql://postgres:postgres@localhost:5432/screen_budget
```

**View Data:**
```bash
cd backend
npx prisma studio
```
Opens at `http://localhost:5555`

---

## 🧪 Test Backend

```bash
curl http://localhost:3000/health
```

---

## 📚 Full Documentation

- [Local Development Guide](docs/LOCAL_DEVELOPMENT.md)
- [Documentation Index](docs/README.md)

---

**Ready to code!** 🎉

