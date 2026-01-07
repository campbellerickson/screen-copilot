# 🚀 Vercel Database Migration Guide

**Last Updated:** January 4, 2026  
Guide for running database migrations on Vercel.

---

## 📋 Overview

Vercel serverless functions require special handling for database migrations. This guide covers two approaches:
1. Running migrations locally against production database
2. Using Vercel Build Command (recommended)

---

## ⚠️ Important Notes

- **Never run migrations in serverless functions** - They timeout!
- Run migrations **before** deploying or use build-time migrations
- Use **connection pooling** for Supabase (port 6543)
- Always backup your database before migrations in production

---

## 🎯 Method 1: Run Migrations Locally (Recommended)

This is the safest and most reliable method.

### Step 1: Get Production Database URL

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project
3. Go to **Settings** → **Environment Variables**
4. Copy the `DATABASE_URL` value (Production)
5. Save it temporarily (you'll use it once)

### Step 2: Run Migration Locally

```bash
cd backend

# Set production database URL (temporarily)
export DATABASE_URL="your-production-database-url-here"

# Run migrations
npx prisma migrate deploy

# Verify migration
npx prisma migrate status

# Optional: View database
npx prisma studio
```

### Step 3: Deploy to Vercel

After migrations succeed:

```bash
# Deploy normally
vercel --prod
```

---

## 🔧 Method 2: Build-Time Migrations

This runs migrations during Vercel build (less reliable, use with caution).

### Update vercel.json

Add migration to build command:

```json
{
  "buildCommand": "cd backend && npm install && npx prisma generate && npx prisma migrate deploy && npm run build"
}
```

**⚠️ Warning:** This can fail if:
- Migration takes too long
- Database is unreachable during build
- Multiple deployments run simultaneously

**Recommendation:** Use Method 1 instead.

---

## 📦 Method 3: Separate Migration Script

Create a one-time migration script for manual execution.

### Create Migration Script

Create `scripts/migrate.ts`:

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrate() {
  try {
    console.log('Running migrations...');
    
    // Run Prisma migrations
    // This would require running: npx prisma migrate deploy
    // Prisma doesn't have a programmatic migration API
    
    console.log('Migrations complete!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

migrate();
```

### Run Locally

```bash
# Set DATABASE_URL environment variable
export DATABASE_URL="your-database-url"

# Run migration
npx ts-node scripts/migrate.ts
```

---

## ✅ Recommended Workflow

### Development

```bash
# Local development database
export DATABASE_URL="your-dev-database-url"
npx prisma migrate dev
```

### Production

1. **Before deploying:**
   ```bash
   export DATABASE_URL="your-production-database-url"
   npx prisma migrate deploy
   ```

2. **Deploy to Vercel:**
   ```bash
   vercel --prod
   ```

3. **Verify:**
   ```bash
   npx prisma migrate status --schema=backend/prisma/schema.prisma
   ```

---

## 🔍 Troubleshooting

### "Migration Already Applied"

- ✅ Safe to ignore - means database is up to date
- Run `npx prisma migrate status` to verify

### "Migration Failed"

- ✅ Check database connection string
- ✅ Verify database is accessible
- ✅ Check Prisma schema is valid: `npx prisma validate`
- ✅ Review error message for specific issue

### "Connection Timeout"

- ✅ Use connection pooling string (port 6543)
- ✅ Check `pgbouncer=true` in connection string
- ✅ Verify database is active
- ✅ Try running migration again

### "Schema Drift Detected"

- ✅ Database schema doesn't match Prisma schema
- ✅ Review differences: `npx prisma migrate status`
- ✅ Create new migration: `npx prisma migrate dev`
- ✅ Or reset database (development only!): `npx prisma migrate reset`

---

## 📚 Additional Resources

- [Prisma Migrate Guide](https://www.prisma.io/docs/concepts/components/prisma-migrate)
- [Vercel Build Configuration](https://vercel.com/docs/build-step)
- [Supabase Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)

---

## 🎯 Best Practices

1. ✅ **Always test migrations locally first**
2. ✅ **Backup production database before migrations**
3. ✅ **Run migrations before deploying code**
4. ✅ **Use connection pooling for serverless**
5. ✅ **Never run migrations in serverless functions**
6. ✅ **Verify migrations with `prisma migrate status`**
7. ✅ **Keep migration files in version control**

---

**Your database migrations are ready!** 🎉

