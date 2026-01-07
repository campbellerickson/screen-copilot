# 🏗️ Architecture Overview

## System Architecture

Screen Budget uses a modern serverless architecture with Supabase Edge Functions.

```
┌─────────────┐
│  iOS App    │  SwiftUI + StoreKit
│ (SwiftUI)   │
└──────┬──────┘
       │ HTTPS
       │
┌──────▼──────────────────┐
│  Supabase Edge Functions │  Deno Runtime
│  (18 Functions)          │
└──────┬───────────────────┘
       │
┌──────▼──────┐
│  Supabase   │  PostgreSQL
│  Database   │
└─────────────┘
```

---

## Backend Architecture

### Edge Functions

All API endpoints are Supabase Edge Functions:

**Authentication:**
- `auth-signup` - User registration
- `auth-login` - User login
- `auth-me` - Get current user
- `auth-delete-account` - Delete user account

**Subscriptions:**
- `subscription-status` - Get subscription status
- `subscription-cancel` - Cancel subscription
- `subscription-validate-receipt` - Validate iOS App Store receipt

**Budget Management:**
- `budget-create` - Create screen time budget
- `budget-get` - Get current budget
- `budget-update-category` - Update category budget

**Usage Tracking:**
- `usage-sync` - Sync daily usage data
- `usage-daily` - Get daily usage summary

**Features:**
- `weekly-goals-current` - Get current week goal
- `weekly-goals-set` - Set weekly goal
- `weekly-goals-history` - Get goal history
- `break-reminders-get` - Get break reminder settings
- `break-reminders-update` - Update break reminder settings
- `weekly-insights` - Get weekly insights

### Shared Utilities

Located in `supabase/functions/_shared/`:
- `cors.ts` - CORS handling
- `database.ts` - Supabase client setup
- `auth.ts` - Authentication helpers
- `response.ts` - Response helpers

---

## Database Schema

### Core Tables

- **users** - User accounts
- **subscriptions** - Subscription management (iOS App Store)
- **screen_time_budgets** - Monthly budgets
- **category_budgets** - Budget per category
- **user_apps** - User's installed apps
- **daily_app_usage** - Daily usage tracking
- **budget_alerts** - Budget overage alerts

### Feature Tables

- **streaks** - User streaks
- **achievements** - User achievements
- **weekly_goals** - Weekly goals
- **break_reminders** - Break reminder settings

---

## iOS App Architecture

### Structure

```
ScreenTimeBudget/
├── Views/              # SwiftUI views
├── Models/             # Data models
├── Services/           # API and business logic
└── Utilities/          # Helpers and constants
```

### Key Components

- **APIService** - Handles all API calls to Supabase Edge Functions
- **AuthManager** - Manages authentication state
- **StoreKitManager** - Handles App Store subscriptions
- **NotificationService** - Manages local notifications

---

## Authentication Flow

1. User signs up/logs in via iOS app
2. App calls `auth-signup` or `auth-login` Edge Function
3. Supabase Auth creates user and returns JWT token
4. App stores token in Keychain
5. All subsequent requests include token in Authorization header
6. Edge Functions verify token using Supabase Auth

---

## Subscription Flow (iOS)

1. User taps "Subscribe" in app
2. StoreKit presents App Store purchase flow
3. User completes purchase
4. App receives transaction receipt
5. App calls `subscription-validate-receipt` Edge Function
6. Edge Function validates receipt with Apple
7. Database updated with subscription status
8. User gains access to premium features

---

## Data Flow

### Usage Sync

1. iOS app reads Screen Time data
2. App calls `usage-sync` Edge Function with usage data
3. Edge Function:
   - Creates/updates user apps
   - Records daily usage
   - Calculates budget status
   - Checks for overages
   - Returns notifications to schedule
4. App schedules local notifications for overages

### Budget Status

1. App calls `usage-daily` Edge Function
2. Edge Function:
   - Fetches current budget
   - Aggregates daily usage by category
   - Calculates monthly totals
   - Returns budget status
3. App displays budget status in UI

---

## Security

- **Authentication:** Supabase Auth with JWT tokens
- **Authorization:** Token verification in Edge Functions
- **Database:** Row Level Security (RLS) policies
- **API:** HTTPS only, CORS configured
- **Secrets:** Stored in Supabase Edge Functions secrets

---

## Scalability

- **Serverless:** Edge Functions auto-scale
- **Database:** Supabase PostgreSQL with connection pooling
- **CDN:** Supabase provides global CDN
- **Caching:** Can add Redis for frequently accessed data

---

## Monitoring

- **Supabase Dashboard:** Function logs and metrics
- **Database:** Query performance in Supabase Dashboard
- **iOS:** Analytics via Analytics service (to be implemented)

---

## Future Improvements

- [ ] Add Redis caching layer
- [ ] Implement WebSocket for real-time updates
- [ ] Add analytics tracking
- [ ] Implement rate limiting
- [ ] Add request logging and monitoring

