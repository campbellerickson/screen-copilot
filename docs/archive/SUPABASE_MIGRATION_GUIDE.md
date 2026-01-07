# 🚀 Supabase Edge Functions Migration Guide

## Overview

The backend has been migrated from Express.js to Supabase Edge Functions. This provides:
- ✅ No IPv4 connection issues
- ✅ Built-in authentication
- ✅ Simplified architecture
- ✅ Better scalability

---

## 📋 Migration Steps

### 1. Supabase Setup

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note your project URL and API keys

2. **Configure Environment Variables**
   - In Supabase Dashboard → Settings → Edge Functions
   - Add these secrets:
     - `STRIPE_SECRET_KEY` - Your Stripe secret key
     - `STRIPE_WEBHOOK_SECRET` - Your Stripe webhook secret
     - `APPLE_BUNDLE_ID` - Your iOS app bundle ID (optional, for Apple Sign In)

3. **Set Up Database**
   - Run Prisma migrations on your Supabase database:
     ```bash
     cd backend
     DATABASE_URL="your-supabase-connection-string" npx prisma migrate deploy
     ```
   - Use the **pooled connection string** (port 6543) from Supabase dashboard

4. **Enable Authentication**
   - In Supabase Dashboard → Authentication → Providers
   - Enable Email provider
   - Configure Apple Sign In (if using):
     - Add your Apple Client ID
     - Add your Apple Secret Key
     - Set redirect URLs

---

### 2. Deploy Edge Functions

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**
   ```bash
   supabase login
   ```

3. **Link Your Project**
   ```bash
   cd /path/to/screen-budget
   supabase link --project-ref your-project-ref
   ```

4. **Deploy Functions**
   ```bash
   supabase functions deploy auth-signup
   supabase functions deploy auth-login
   supabase functions deploy auth-me
   supabase functions deploy auth-delete-account
   supabase functions deploy subscription-status
   supabase functions deploy subscription-cancel
   supabase functions deploy subscription-webhook
   supabase functions deploy budget-create
   supabase functions deploy budget-get
   supabase functions deploy budget-update-category
   supabase functions deploy usage-sync
   supabase functions deploy usage-daily
   supabase functions deploy weekly-goals-current
   supabase functions deploy weekly-goals-set
   supabase functions deploy weekly-goals-history
   supabase functions deploy break-reminders-get
   supabase functions deploy break-reminders-update
   supabase functions deploy weekly-insights
   ```

   Or deploy all at once:
   ```bash
   supabase functions deploy --no-verify-jwt
   ```

---

### 3. Update iOS App

1. **Update Constants.swift**
   - Change `baseURL` to your Supabase project URL:
     ```swift
     static let baseURL = "https://[your-project-ref].supabase.co/functions/v1"
     ```

2. **Update API Endpoints**
   - The iOS app has been updated to use the new endpoint structure
   - All endpoints now use the format: `/function-name` instead of `/api/v1/...`

3. **Update Authentication**
   - The app now uses Supabase Auth tokens
   - Tokens are automatically managed by Supabase

---

### 4. Environment Variables

Create a `.env` file in the `supabase` directory (for local development):

```env
SUPABASE_URL=https://[your-project-ref].supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
STRIPE_SECRET_KEY=your-stripe-secret
STRIPE_WEBHOOK_SECRET=your-webhook-secret
```

---

## 🔄 API Endpoint Changes

### Old (Express) → New (Supabase Edge Functions)

| Old Endpoint | New Endpoint |
|-------------|--------------|
| `POST /api/v1/auth/signup` | `POST /functions/v1/auth-signup` |
| `POST /api/v1/auth/login` | `POST /functions/v1/auth-login` |
| `GET /api/v1/auth/me` | `GET /functions/v1/auth-me` |
| `DELETE /api/v1/auth/account` | `DELETE /functions/v1/auth-delete-account` |
| `GET /api/v1/subscription/status` | `GET /functions/v1/subscription-status` |
| `POST /api/v1/subscription/cancel` | `POST /functions/v1/subscription-cancel` |
| `POST /api/v1/subscription/webhook` | `POST /functions/v1/subscription-webhook` |
| `POST /api/v1/screen-time/budgets` | `POST /functions/v1/budget-create` |
| `GET /api/v1/screen-time/budgets/:userId/current` | `GET /functions/v1/budget-get` |
| `PUT /api/v1/screen-time/budgets/categories/:categoryId` | `PUT /functions/v1/budget-update-category` |
| `POST /api/v1/screen-time/usage/sync` | `POST /functions/v1/usage-sync` |
| `GET /api/v1/screen-time/usage/:userId/daily` | `GET /functions/v1/usage-daily` |
| `GET /api/v1/weekly-goals/current` | `GET /functions/v1/weekly-goals-current` |
| `POST /api/v1/weekly-goals` | `POST /functions/v1/weekly-goals-set` |
| `GET /api/v1/weekly-goals/history` | `GET /functions/v1/weekly-goals-history` |
| `GET /api/v1/break-reminders` | `GET /functions/v1/break-reminders-get` |
| `PUT /api/v1/break-reminders` | `PUT /functions/v1/break-reminders-update` |
| `GET /api/v1/weekly-insights` | `GET /functions/v1/weekly-insights` |

---

## 🔐 Authentication Changes

### Before (Custom JWT)
- Custom JWT tokens generated by Express backend
- Token stored in Keychain
- Manual token validation

### After (Supabase Auth)
- Supabase manages authentication
- Tokens are Supabase JWT tokens
- Automatic token refresh
- Built-in user management

**Note:** The iOS app still uses the same token storage mechanism, but now stores Supabase tokens instead of custom JWT tokens.

---

## 🧪 Testing

1. **Test Authentication**
   ```bash
   curl -X POST https://[project-ref].supabase.co/functions/v1/auth-signup \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"Test1234","name":"Test User"}'
   ```

2. **Test with Auth Token**
   ```bash
   curl -X GET https://[project-ref].supabase.co/functions/v1/auth-me \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

## 🐛 Troubleshooting

### Issue: "Authentication required" errors
- **Solution:** Make sure you're sending the `Authorization: Bearer [token]` header
- Check that the token is a valid Supabase JWT token

### Issue: "Subscription required" errors
- **Solution:** Ensure the user has a trial or active subscription in the database
- Check the `subscriptions` table

### Issue: Database connection errors
- **Solution:** Use the pooled connection string (port 6543) from Supabase dashboard
- Make sure your database migrations have been run

### Issue: Edge Function deployment fails
- **Solution:** Check that all environment variables are set in Supabase dashboard
- Verify your Supabase CLI is logged in: `supabase projects list`

---

## 📝 Next Steps

1. ✅ Deploy all Edge Functions
2. ✅ Update iOS app `baseURL` in Constants.swift
3. ✅ Test authentication flow
4. ✅ Test subscription flow
5. ✅ Test usage syncing
6. ✅ Update Stripe webhook URL to point to new endpoint
7. ✅ Monitor Edge Function logs in Supabase dashboard

---

## 🔗 Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Supabase Swift Client](https://github.com/supabase/supabase-swift) (optional, for future migration)

---

## ⚠️ Important Notes

1. **Database Schema:** The database schema remains the same. Only the API layer changed.

2. **Migration Path:** Users will need to sign up again or you'll need to migrate existing users to Supabase Auth.

3. **Apple Sign In:** Currently uses a placeholder. You'll need to configure Apple OAuth in Supabase dashboard for full Apple Sign In support.

4. **Stripe Webhooks:** Update your Stripe webhook URL to point to the new Edge Function endpoint.

5. **Local Development:** Use `supabase functions serve` to test functions locally before deploying.

---

**Migration completed!** 🎉

