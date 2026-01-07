# 🔧 Vercel Deployment Troubleshooting

## Current Issue: 404 Not Found

Your Vercel deployment is live but returning 404 for all API routes.

**URL**: `https://screen-copilot-ysge.vercel.app`
**Status**: Deployed but not routing correctly

---

## 🎯 **Quick Fix (Do This Now)**

### **Option 1: Check Vercel Dashboard Settings**

1. Go to https://vercel.com/campbellerickson/screen-copilot-ysge
2. Click "Settings" → "General"
3. Verify:
   - **Root Directory**: `backend` ✅
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`

4. Check "Functions" tab
   - Should show `api/index.ts` as a function
   - If missing, the build failed

### **Option 2: Check Build Logs**

1. Go to "Deployments" tab
2. Click latest deployment
3. Click "Build Logs"
4. Look for errors like:
   - `Module not found`
   - `TypeScript compilation failed`
   - `Prisma generation failed`

Common issues:
```bash
# Missing dependencies
Error: Cannot find module '@prisma/client'
→ Fix: Add postinstall script

# TypeScript errors
Error: Property 'x' does not exist
→ Fix: Fix TypeScript errors before deploying

# Prisma not generated
Error: @prisma/client did not initialize yet
→ Fix: Run prisma generate in build
```

---

## 🛠️ **Solution: Update package.json**

The issue is likely that Prisma isn't being generated before the build.

### **Update `backend/package.json`:**

```json
{
  "scripts": {
    "dev": "nodemon src/server.ts",
    "build": "prisma generate && tsc",
    "start": "node dist/server.js",
    "postinstall": "prisma generate",
    ...
  }
}
```

The `postinstall` script ensures Prisma generates before Vercel builds.

---

## 📋 **Detailed Debugging Steps**

### **Step 1: Verify Environment Variables**

In Vercel dashboard → Settings → Environment Variables:

Required:
```bash
DATABASE_URL="postgresql://..."  # ✅ You have this
JWT_SECRET="..."                 # ✅ Should be set
NODE_ENV="production"            # ✅ Should be set
CORS_ORIGIN="*"                  # ✅ Should be set
```

### **Step 2: Test Locally with Production DB**

Update `backend/.env.local`:
```bash
DATABASE_URL="<your-neon-connection-string>"
JWT_SECRET="<same-as-vercel>"
NODE_ENV=production
```

Run:
```bash
cd backend
npm install
npm run build
npm start
```

Test:
```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "Test1234!"}'
```

If this works locally with production DB, the issue is Vercel configuration, not your code.

### **Step 3: Simplify Vercel Configuration**

Current `backend/vercel.json`:
```json
{
  "version": 2,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/api/index"
    }
  ]
}
```

This tells Vercel: "Route everything to `/api/index.ts`"

Verify `backend/api/index.ts` exists and contains:
```typescript
import app from '../src/server';
export default app;
```

### **Step 4: Alternative - Use Vercel Build Output API**

If the above doesn't work, we can configure Vercel to use the Build Output API (v3):

Create `backend/.vercel/output/config.json`:
```json
{
  "version": 3,
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/api/index"
    }
  ]
}
```

---

## 🚨 **Nuclear Option: Start Fresh**

If nothing works, delete the Vercel project and recreate:

### **1. Delete Current Deployment**

In Vercel dashboard:
- Settings → scroll to bottom → "Delete Project"

### **2. Create New Deployment**

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy from command line
cd ~/Desktop/Code/screen-budget/backend
vercel

# Follow prompts:
# - Link to existing project? No
# - Project name? screen-copilot
# - Directory? ./
# - Override settings? No
```

This will create a fresh deployment with proper configuration.

### **3. Add Environment Variables via CLI**

```bash
vercel env add DATABASE_URL
# Paste your Neon connection string

vercel env add JWT_SECRET
# Paste your JWT secret

vercel env add NODE_ENV
# Type: production

vercel env add CORS_ORIGIN
# Type: *
```

### **4. Deploy**

```bash
vercel --prod
```

---

## ✅ **Verification Checklist**

Once deployed, verify:

### **Health Endpoint**
```bash
curl https://your-app.vercel.app/health

# Expected:
{
  "status": "ok",
  "timestamp": "2026-01-07T...",
  "environment": "production"
}
```

### **Signup Endpoint**
```bash
curl -X POST https://your-app.vercel.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "vercel-test@example.com",
    "password": "Test1234!",
    "name": "Vercel Test"
  }'

# Expected:
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "vercel-test@example.com" },
    "token": "eyJhbGci...",
    "subscription": { "status": "trial", "hasAccess": true }
  }
}
```

### **Database Connection**
```bash
# In Neon SQL Editor:
SELECT COUNT(*) FROM users;
SELECT * FROM users WHERE email = 'vercel-test@example.com';
```

Should show the user was created.

---

## 💡 **Most Likely Issue**

Based on the 404 error, the most likely issues are (in order):

1. **Prisma not generated during build** (80% chance)
   - Fix: Add `postinstall` script to package.json

2. **TypeScript compilation failed** (15% chance)
   - Fix: Check build logs for errors

3. **Vercel routing misconfigured** (5% chance)
   - Fix: Verify vercel.json and api/index.ts

---

## 🔍 **What to Do Right Now**

### **Immediate Actions:**

1. **Check Build Logs in Vercel**
   - Go to latest deployment → "Build Logs" tab
   - Screenshot any errors
   - Share with me so I can diagnose

2. **Update package.json**
   - Add `postinstall: "prisma generate"`
   - Commit and push
   - Vercel will auto-redeploy

3. **Test Locally with Production DB**
   - Verify your code works with Neon database
   - If it works locally, it's just Vercel config

---

## 📞 **Need Help?**

Share:
1. Screenshot of Vercel build logs
2. Screenshot of Functions tab in Vercel
3. Result of running `npm run build` locally

I'll diagnose the exact issue and provide a fix.

---

## 🎯 **Temporary Workaround**

While we debug Vercel, you can deploy to **Railway** (simpler for Express apps):

### **Quick Railway Deployment:**

1. Go to https://railway.app
2. Sign in with GitHub
3. "New Project" → "Deploy from GitHub repo"
4. Select `screen-copilot`
5. Add environment variables
6. Deploy

Railway automatically detects Express apps and configures correctly.

Deployment time: ~5 minutes
URL: `https://screen-copilot-production.up.railway.app`

Then update iOS Constants.swift with Railway URL.

---

Let me know what you find in the build logs and I'll help fix it! 🚀
