# ✅ Vercel Configuration Checklist

Quick reference for Vercel deployment settings.

---

## 🎯 **Correct Vercel Settings**

### **General Settings** (Settings → General)

```
Root Directory: backend
Framework Preset: Other
Node.js Version: 20.x
```

### **Build & Development Settings**

```
Build Command: npm run build
Output Directory: (leave blank)
Install Command: npm install
Development Command: npm run dev
```

### **Environment Variables** (Settings → Environment Variables)

Required for all environments (Production, Preview, Development):

```bash
DATABASE_URL="postgresql://..."
JWT_SECRET="<64-char-random-string>"
NODE_ENV="production"
CORS_ORIGIN="*"
APPLE_BUNDLE_ID="com.campbell.ScreenTimeCopilot"
```

---

## 📁 **Required File Structure**

```
screen-copilot/
└── backend/               ← Root Directory in Vercel
    ├── api/
    │   ├── index.ts      ← Main serverless function
    │   └── test.ts       ← Test endpoint
    ├── src/
    │   └── server.ts     ← Express app
    ├── package.json
    ├── tsconfig.json
    └── vercel.json       ← Routing configuration
```

---

## 🔍 **How to Verify Deployment**

### **1. Check Functions Tab**

Go to: Project → Functions

You should see:
- `api/index` (or `api/index.ts`)
- `api/test` (or `api/test.ts`)

If you see NO functions listed, the build failed or files aren't being detected.

### **2. Check Build Logs**

Latest Deployment → "Building" → View logs

Look for:
```
✓ Prisma generate
✓ TypeScript compilation
✓ Creating Serverless Functions
  - api/index.ts
  - api/test.ts
```

If you see errors:
```
✗ Module not found: @prisma/client
✗ Cannot find module '../src/server'
✗ Build failed
```

→ Fix and redeploy

### **3. Test Endpoints**

Once deployed:

```bash
# Test simple function
curl https://your-app.vercel.app/api/test

# Expected:
{
  "message": "Vercel serverless function is working!",
  "timestamp": "2026-01-07T..."
}

# Test main app
curl https://your-app.vercel.app/health

# Expected:
{
  "status": "ok",
  "timestamp": "2026-01-07T...",
  "environment": "production"
}
```

---

## 🚨 **Common Issues & Fixes**

### **Issue: 404 on all endpoints**

**Cause**: Functions not detected

**Fix**:
1. Verify Root Directory = `backend`
2. Check `/api` folder exists with `.ts` files
3. Redeploy

### **Issue: "Module not found: @prisma/client"**

**Cause**: Prisma not generated during build

**Fix**: Ensure `package.json` has:
```json
{
  "scripts": {
    "build": "prisma generate && tsc",
    "postinstall": "prisma generate"
  }
}
```

### **Issue: "Cannot find module '../src/server'"**

**Cause**: TypeScript paths not resolving

**Fix**: In `api/index.ts`, use:
```typescript
import app from '../src/server';  // Not './src/server' or '../dist/server'
```

### **Issue: Build succeeds but still 404**

**Cause**: Functions created but routing broken

**Fix**: Check `vercel.json`:
```json
{
  "version": 2,
  "rewrites": [
    { "source": "/(.*)", "destination": "/api" }
  ]
}
```

---

## 🎯 **Quick Debug Commands**

### **Check what Vercel sees:**

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Link to project
cd ~/Desktop/Code/screen-budget/backend
vercel link

# Check configuration
vercel inspect
```

### **Test locally with Vercel dev server:**

```bash
cd backend
vercel dev

# Should start local server on http://localhost:3000
# Test: curl http://localhost:3000/health
```

If `vercel dev` works but production doesn't, it's a deployment setting issue.

---

##  **Alternative: Vercel CLI Deployment**

If dashboard deployment keeps failing:

```bash
cd ~/Desktop/Code/screen-budget/backend

# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Set environment variables
vercel env add DATABASE_URL production
vercel env add JWT_SECRET production
```

---

## ✅ **Success Criteria**

Before moving to TestFlight:

- [ ] `/api/test` returns JSON
- [ ] `/health` returns `{"status": "ok"}`
- [ ] `/api/v1/auth/signup` works (creates user)
- [ ] Functions tab shows detected functions
- [ ] Build logs show no errors
- [ ] Environment variables are set

---

Need help? Check build logs first, then compare settings to this checklist.
