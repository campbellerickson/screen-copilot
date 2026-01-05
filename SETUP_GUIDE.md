# 🚀 Complete Setup Guide - Supabase & Apple Authentication

**Last Updated:** January 4, 2026  
**App:** Screen Budget

This guide will walk you through setting up Supabase (PostgreSQL database) and Apple Sign In authentication.

---

## 📋 Prerequisites

- GitHub account
- Apple Developer account ($99/year)
- Supabase account (free tier available)
- Node.js 18+ installed locally
- Xcode installed (for iOS development)

---

## Part 1: Supabase Setup

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in project details:
   - **Name:** `screen-budget` (or your preferred name)
   - **Database Password:** Generate a strong password (save this!)
   - **Region:** Choose closest to your users
   - **Pricing Plan:** Free tier is fine for development

5. Click **"Create new project"**
6. Wait 2-3 minutes for project to be created

### Step 2: Get Database Connection String

1. In your Supabase project dashboard, go to **Settings** → **Database**
2. Scroll down to **"Connection string"** section
3. Select **"URI"** tab
4. Copy the connection string (it looks like):
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
   ```
5. Replace `[YOUR-PASSWORD]` with the database password you set
6. **Save this connection string** - you'll need it for environment variables

**Your Project Details:**
- **Project URL:** `https://jqfyunukinwglaitjkfr.supabase.co`
- **Direct Connection:** `postgresql://postgres:wHSCHAPS2017!@db.jqfyunukinwglaitjkfr.supabase.co:5432/postgres`
- **⚠️ For Vercel:** You MUST use the pooled connection string (see Step 4)

### Step 3: Run Database Migrations

Your database schema is defined in `backend/prisma/schema.prisma`. You need to:

1. **Set up local environment:**
   ```bash
   cd backend
   cp .env.example .env
   ```

2. **Edit `.env` file:**
   ```env
   # Database - USE POOLED CONNECTION (Required for Vercel)
   # Get the exact connection string from Supabase Dashboard → Settings → Database → Connection Pooling
   DATABASE_URL="postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
   NODE_ENV=development
   JWT_SECRET="your-random-jwt-secret-key-here"
   CORS_ORIGIN="*"
   ```

   **⚠️ CRITICAL Notes:**
   - **MUST use pooled connection** (port 6543) - Direct connection (5432) won't work with Vercel
   - Get the exact connection string from Supabase Dashboard → Connection Pooling → Transaction mode
   - Replace `[region]` with your actual region (e.g., `us-east-1`, `us-west-1`)
   - Replace `[YOUR-PASSWORD]` with `wHSCHAPS2017!`
   - Use the **SAME pooled connection string for both local dev AND Vercel**
   - Generate a secure JWT_SECRET (you can use: `openssl rand -base64 32`)

3. **Install dependencies and generate Prisma client:**
   ```bash
   npm install
   npx prisma generate
   ```

4. **Run migrations:**
   ```bash
   # Push schema to database (creates all tables)
   npx prisma db push
   
   # OR if you prefer using migrations:
   npx prisma migrate dev --name init
   ```

5. **Verify tables were created:**
   ```bash
   npx prisma studio
   ```
   This opens Prisma Studio in your browser where you can view your database tables.

### Step 4: Set Up Supabase Connection Pooling (⚠️ REQUIRED)

**CRITICAL:** Vercel is IPv4-only and your Free Plan doesn't support IPv4 direct connections. You **MUST use connection pooling** for both local development AND Vercel.

1. In Supabase dashboard, go to **Settings** → **Database**
2. Scroll to **"Connection Pooling"** section (you should see "SHARED POOLER")
3. Look for **"Connection string"** or connection info
4. Copy the **"Transaction mode"** connection string (this is for serverless/Vercel)
5. The format should be:
   ```
   postgresql://postgres.[project-ref]:[password]@[pooler-host]:6543/postgres
   ```
6. Replace `[password]` with `wHSCHAPS2017!`
7. Add parameters: `?pgbouncer=true&connection_limit=1`

**Your pooled connection string should look like:**
```
postgresql://postgres.jqfyunukinwglaitjkfr:wHSCHAPS2017!@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1
```

**⚠️ Important Notes:**
- **Use this SAME pooled connection for BOTH local dev AND Vercel**
- Port is **6543** (pooler), not 5432 (direct)
- Host is `pooler.supabase.com`, not `db.xxxxx.supabase.co`
- Replace `[region]` with your actual region (check Supabase project settings)
- The project reference is: `jqfyunukinwglaitjkfr`
- Direct connection (port 5432) will **NOT work** with Vercel due to IPv4 compatibility

---

## Part 2: Apple Sign In Setup

### Step 1: Create App ID in Apple Developer

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (top left)
4. Select **App IDs** → **Continue**
5. Select **App** → **Continue**
6. Fill in:
   - **Description:** Screen Budget
   - **Bundle ID:** `com.campbell.screenbudget` (or your bundle ID)
   - **Capabilities:** Check **Sign In with Apple**
7. Click **Continue** → **Register**

### Step 2: Create Service ID

1. Still in **Identifiers**, click **+** again
2. Select **Services IDs** → **Continue**
3. Fill in:
   - **Description:** Screen Budget Web Service
   - **Identifier:** `com.campbell.screenbudget.service` (or your identifier)
4. Click **Continue** → **Register**
5. **Check "Sign In with Apple"** → **Configure**
6. Configure Sign In with Apple:
   - **Primary App ID:** Select your App ID from Step 1
   - **Website URLs:**
     - **Domains and Subdomains:** `your-api-domain.vercel.app` (your Vercel URL)
     - **Return URLs:** `https://your-api-domain.vercel.app/api/v1/auth/apple/callback`
   - Click **Save** → **Continue** → **Register**

### Step 3: Create Key for Sign In with Apple

1. In **Certificates, Identifiers & Profiles**, go to **Keys**
2. Click **+** (top left)
3. Fill in:
   - **Key Name:** Screen Budget Apple Sign In Key
   - **Enable "Sign In with Apple"**
4. Click **Continue** → **Register**
5. **Download the key file** (`.p8` file) - **You can only download this once!**
6. **Copy the Key ID** - you'll need this

### Step 4: Create Private Key File

1. The downloaded file is a `.p8` file
2. Save it in your project (recommended: `backend/keys/apple-signin-key.p8`)
3. **Add to `.gitignore`**:
   ```bash
   echo "backend/keys/*.p8" >> .gitignore
   echo "backend/.env" >> .gitignore
   ```

### Step 5: Get Your Team ID

1. In Apple Developer Portal, go to **Membership**
2. Copy your **Team ID** (looks like: `ABC123XYZ`)

### Step 6: Configure Backend Environment Variables

Update your `backend/.env` file:

```env
# Database
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.xxxxx.supabase.co:5432/postgres?pgbouncer=true&connection_limit=1"

# JWT
JWT_SECRET="your-random-jwt-secret-key-here"

# Apple Sign In
APPLE_TEAM_ID="ABC123XYZ"                    # Your Team ID
APPLE_CLIENT_ID="com.campbell.screenbudget.service"  # Your Service ID
APPLE_KEY_ID="XYZ123ABC"                     # Key ID from Step 3
APPLE_PRIVATE_KEY_PATH="./keys/apple-signin-key.p8"  # Path to .p8 file

# CORS
CORS_ORIGIN="*"

# Node Environment
NODE_ENV=development
```

### Step 7: Install Apple Sign In Package

The backend already uses `apple-signin-auth`. Verify it's installed:

```bash
cd backend
npm list apple-signin-auth
```

If not installed:
```bash
npm install apple-signin-auth
```

---

## Part 3: Vercel Deployment Setup

### Step 1: Connect Repository to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **Add New...** → **Project**
3. Import your GitHub repository (`campbellerickson/screen-copilot`)
4. Vercel will detect the project

### Step 2: Configure Vercel Environment Variables

In Vercel project settings → **Environment Variables**, add:

#### Database (Production)
```
DATABASE_URL=postgresql://postgres.xxxxx:YOUR_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```
Use the **connection pooling URL** from Supabase!

#### JWT Secret
```
JWT_SECRET=your-production-jwt-secret-key-here
```
Generate a new secure key for production (different from dev).

#### Apple Sign In
```
APPLE_TEAM_ID=ABC123XYZ
APPLE_CLIENT_ID=com.campbell.screenbudget.service
APPLE_KEY_ID=XYZ123ABC
APPLE_PRIVATE_KEY_PATH=/var/task/keys/apple-signin-key.p8
```

#### CORS (Update with your Vercel URL)
```
CORS_ORIGIN=https://your-api-domain.vercel.app
```

#### Node Environment
```
NODE_ENV=production
VERCEL=1
```

### Step 3: Upload Apple Private Key to Vercel

Vercel doesn't support file uploads directly. You have two options:

**Option A: Use Environment Variable (Base64)**
1. Convert `.p8` file to base64:
   ```bash
   base64 -i backend/keys/apple-signin-key.p8 | pbcopy
   ```
2. Add to Vercel environment variables:
   ```
   APPLE_PRIVATE_KEY_BASE64=<paste-base64-string>
   ```
3. Update code to decode it (modify `authController.ts` to decode if using this method)

**Option B: Include in Git (Not Recommended)**
- Only if you're okay with the key in your repository
- Add to repo and reference it in code

**Option C: Use Vercel Blob (Recommended for Production)**
- Store key in Vercel Blob storage
- Reference in code

### Step 4: Update Apple Callback URL

Once you have your Vercel URL, update Apple Service ID configuration:

1. Go back to Apple Developer Portal
2. **Identifiers** → Your Service ID
3. **Sign In with Apple** → **Configure**
4. Update **Return URLs:**
   - `https://your-api-domain.vercel.app/api/v1/auth/apple/callback`
5. Click **Save**

---

## Part 4: iOS App Configuration

### Step 1: Enable Sign In with Apple Capability

1. Open `ios/ScreenTimeBudget.xcodeproj` in Xcode
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign In with Apple**

### Step 2: Update Bundle Identifier

Make sure your Bundle ID matches the App ID you created:

1. In Xcode, select your target
2. Go to **General** tab
3. **Bundle Identifier:** `com.campbell.screenbudget` (must match Apple Developer)

### Step 3: Update API Base URL

Update `ios/ScreenTimeBudget/Utilities/Constants.swift`:

```swift
static let baseURL = "https://your-api-domain.vercel.app/api/v1"
```

---

## Part 5: Testing the Setup

### Test Database Connection

```bash
cd backend
npm run dev
```

Check console for database connection success.

### Test Apple Sign In

1. Run iOS app on device (Sign In with Apple only works on real devices)
2. Tap "Sign In with Apple"
3. Authenticate with Apple
4. Check backend logs for successful authentication

### Test API Endpoints

```bash
# Health check
curl https://your-api-domain.vercel.app/health

# Should return:
# {"status":"ok","timestamp":"...","environment":"production"}
```

---

## 🔒 Security Checklist

- [ ] Database password is strong and unique
- [ ] JWT_SECRET is randomly generated and secure
- [ ] `.env` files are in `.gitignore`
- [ ] `.p8` key file is NOT committed to git
- [ ] Apple private key is stored securely
- [ ] Production environment variables are set in Vercel
- [ ] CORS_ORIGIN is set to your actual domain (not `*` in production)
- [ ] Database connection pooling is used in production
- [ ] HTTPS is enabled (automatic with Vercel)

---

## 🐛 Troubleshooting

### Database Connection Issues

**Error: "Connection refused"**
- Check DATABASE_URL is correct
- Verify Supabase project is active
- Check if IP is whitelisted (Supabase allows all by default)

**Error: "Too many connections"**
- Use connection pooling URL in production
- Check Prisma connection limit settings

### Apple Sign In Issues

**Error: "Invalid client"**
- Verify APPLE_CLIENT_ID matches Service ID
- Check Service ID is configured correctly
- Verify callback URL matches exactly

**Error: "Invalid key"**
- Verify APPLE_KEY_ID matches downloaded key
- Check .p8 file path is correct
- Ensure key has "Sign In with Apple" enabled

**Error: "Team ID mismatch"**
- Verify APPLE_TEAM_ID is correct
- Check Bundle ID matches App ID

### Vercel Deployment Issues

**Build fails**
- Check all environment variables are set
- Verify `vercel.json` is correct
- Check build logs for specific errors

**Runtime errors**
- Check function logs in Vercel dashboard
- Verify DATABASE_URL uses pooling URL
- Check all required env vars are present

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Vercel Documentation](https://vercel.com/docs)
- [Prisma Documentation](https://www.prisma.io/docs)

---

## ✅ Next Steps

After setup is complete:

1. ✅ Test database connections
2. ✅ Test Apple Sign In
3. ✅ Deploy to Vercel
4. ✅ Update iOS app with production URL
5. ✅ Test end-to-end flow
6. ✅ Set up monitoring and error tracking
7. ✅ Configure domain (optional)

---

**Need Help?** Check the troubleshooting section or review the specific setup files:
- `SUPABASE_SETUP.md` - Detailed Supabase setup
- `APPLE_SETUP.md` - Detailed Apple setup
- `DEPLOYMENT_CHECKLIST.md` - Deployment checklist

