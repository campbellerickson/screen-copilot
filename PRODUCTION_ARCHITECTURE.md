# Production Architecture Documentation

Complete architecture overview for Screen Time Budget in production.

---

## Architecture Overview

```
┌─────────────────┐
│   iOS App       │
│  (SwiftUI)      │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────────────────────────┐
│   Vercel Edge Network               │
│   screen-copilot-ysge.vercel.app    │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Express.js API                    │
│   (Serverless Functions)            │
│   - Authentication (JWT)            │
│   - Screen Time Tracking            │
│   - Budget Management               │
│   - Weekly Goals & Insights         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Neon PostgreSQL                   │
│   (Serverless Database)             │
│   - Users                           │
│   - Subscriptions                   │
│   - Screen Time Data                │
│   - Budgets & Goals                 │
└─────────────────────────────────────┘
```

---

## Component Details

### 1. iOS Application

**Technology Stack:**
- SwiftUI (iOS 17+)
- Screen Time API
- Keychain for secure token storage
- URLSession for networking
- Combine for reactive programming

**Key Features:**
- User authentication (Email/Password + Apple Sign In)
- Screen time data collection
- Budget setting and tracking
- Real-time notifications
- Offline support with background sync

**Bundle ID:** `com.campbell.ScreenTimeCopilot`

**API Integration:**
- Base URL: `https://screen-copilot-ysge.vercel.app/api/v1`
- Authentication: JWT Bearer tokens
- Request timeout: 30 seconds
- Retry logic: 3 attempts with exponential backoff

---

### 2. Backend API (Vercel Serverless)

**Deployment:**
- Platform: Vercel
- Region: Auto (Edge Network)
- Function Runtime: Node.js 24.x
- Root Directory: `backend/`

**Framework:**
- Express.js 4.18+
- TypeScript 5.0+
- Prisma ORM 5.22+

**Serverless Functions:**
```
backend/
├── api/
│   └── index.ts          → Main Express app handler
├── src/
│   ├── server.ts         → Express app configuration
│   ├── routes/           → API route definitions
│   ├── controllers/      → Business logic
│   ├── middleware/       → Auth, error handling
│   └── config/           → Database, environment config
```

**API Endpoints:**

**Authentication** (`/api/v1/auth`)
- `POST /signup` - Email/password registration
- `POST /login` - Email/password login
- `POST /apple` - Apple Sign In
- `GET /me` - Get current user (requires auth)

**Screen Time** (`/api/v1/screen-time`)
- `GET /budgets` - Get user's budgets
- `POST /budgets` - Create new budget
- `PUT /budgets/:id` - Update budget
- `POST /sync` - Sync screen time data from iOS
- `GET /usage` - Get usage analytics

**Subscriptions** (`/api/v1/subscription`)
- `GET /status` - Get subscription status
- `POST /webhook` - Stripe webhook handler
- `POST /apple/verify` - Verify iOS receipt

**Weekly Goals** (`/api/v1/weekly-goals`)
- `GET /` - Get weekly goals
- `POST /` - Create weekly goal
- `PUT /:id` - Update progress

**Break Reminders** (`/api/v1/break-reminders`)
- `GET /settings` - Get reminder settings
- `PUT /settings` - Update reminder settings

**Weekly Insights** (`/api/v1/weekly-insights`)
- `GET /` - Get weekly insights and trends

**Environment Variables:**
```bash
DATABASE_URL=postgresql://[user]:[password]@[host]/[database]
JWT_SECRET=[64-char-random-string]
NODE_ENV=production
CORS_ORIGIN=*
APPLE_BUNDLE_ID=com.campbell.ScreenTimeCopilot
STRIPE_SECRET_KEY=[optional-for-subscriptions]
```

---

### 3. Database (Neon PostgreSQL)

**Provider:** Neon (Serverless PostgreSQL)
- Auto-scaling
- Connection pooling
- Point-in-time recovery
- Automatic backups

**Schema Overview:**

**Users Table** (`users`)
```sql
- id (UUID, primary key)
- email (unique)
- password (hashed with bcrypt)
- name
- appleId (for Apple Sign In)
- profileImage
- lastLoginAt
- createdAt, updatedAt
```

**Subscriptions Table** (`subscriptions`)
```sql
- id (UUID, primary key)
- userId (FK to users)
- status (trial, active, expired, cancelled)
- platform (ios, android, web)
- trialStartDate, trialEndDate
- subscriptionStartDate, subscriptionEndDate
- renewalDate
- stripeCustomerId, stripeSubscriptionId
- iosReceiptData, iosTransactionId
```

**Screen Time Budgets** (`screen_time_budgets`)
```sql
- id (UUID, primary key)
- userId (FK to users)
- monthYear (date)
- categories (one-to-many with category_budgets)
```

**Category Budgets** (`category_budgets`)
```sql
- id (UUID, primary key)
- budgetId (FK to screen_time_budgets)
- categoryType (social_media, entertainment, gaming, etc.)
- categoryName
- monthlyHours
- isExcluded
```

**Daily App Usage** (`daily_app_usage`)
```sql
- id (UUID, primary key)
- userId (FK to users)
- appId (FK to user_apps)
- usageDate
- totalMinutes
- syncedAt
```

**User Apps** (`user_apps`)
```sql
- id (UUID, primary key)
- userId (FK to users)
- bundleId
- appName
- categoryType
- lastDetected
```

**Additional Tables:**
- `budget_alerts` - Overage notifications
- `streaks` - Consecutive days within budget
- `achievements` - User milestones
- `weekly_goals` - Weekly screen time targets
- `break_reminders` - Break reminder settings

---

## Security

### Authentication Flow

1. **User Signup/Login:**
   ```
   iOS App → POST /api/v1/auth/signup
   ← JWT token (valid for 30 days)
   iOS stores token in Keychain
   ```

2. **Authenticated Requests:**
   ```
   iOS App → GET /api/v1/screen-time/budgets
   Headers: Authorization: Bearer <jwt-token>
   Middleware verifies JWT
   ← Budget data
   ```

3. **Token Refresh:**
   - Tokens expire after 30 days
   - User must re-authenticate
   - Future: Implement refresh tokens

### Security Measures

**Backend:**
- Helmet.js for HTTP header security
- CORS configured for specific origins
- Rate limiting (future: implement with Vercel Edge Config)
- SQL injection prevention via Prisma
- Password hashing with bcrypt (10 rounds)
- JWT signing with HS256 algorithm

**iOS:**
- Keychain storage for tokens (encrypted at rest)
- HTTPS only (no HTTP fallback)
- Certificate pinning (future enhancement)
- App Transport Security enabled

**Database:**
- Encrypted at rest (Neon default)
- Encrypted in transit (SSL/TLS)
- Parameterized queries (Prisma)
- Row-level security (future: implement RLS)

---

## Performance

### Latency Targets

- **API Response Time:** < 500ms (p95)
- **Database Queries:** < 100ms (p95)
- **App Launch:** < 2s
- **Screen Time Sync:** < 3s

### Optimization Strategies

**Backend:**
- Serverless functions with instant cold start
- Connection pooling via Prisma
- Database indexes on frequently queried columns
- Efficient SQL queries with Prisma

**iOS:**
- Background sync with WorkManager
- Local caching with UserDefaults
- Lazy loading of data
- Image caching

**Database:**
- Indexes on: userId, usageDate, bundleId, weekStartDate
- Compound indexes for common queries
- Partial indexes for active subscriptions

---

## Monitoring & Observability

### Vercel Dashboard
- Function invocation logs
- Error tracking
- Performance metrics
- Deployment history

### Database Monitoring (Neon)
- Query performance
- Connection pool utilization
- Storage usage
- Backup status

### iOS Crash Reporting
- TestFlight crash reports
- App Store Connect analytics
- Future: Sentry or Crashlytics

### Key Metrics to Monitor

**Backend:**
- Request rate (requests/minute)
- Error rate (errors/total requests)
- Response time (p50, p95, p99)
- Function duration
- Database connection count

**iOS:**
- Crash rate
- API error rate
- User retention
- Screen time sync success rate

---

## Deployment Pipeline

### Backend Deployment

```
1. Local Development
   ├── Edit code in backend/
   ├── Test locally: npm run dev
   └── Commit changes to git

2. Push to GitHub
   ├── git push origin main
   └── GitHub triggers Vercel

3. Vercel Build
   ├── Clones repo (Root: backend/)
   ├── npm install
   ├── prisma generate
   ├── Compiles api/index.ts → serverless function
   └── Deploys to edge network

4. Production Live
   └── https://screen-copilot-ysge.vercel.app
```

### iOS Deployment

```
1. Local Development
   ├── Edit code in Xcode
   ├── Test on Simulator/Device
   └── Update version/build number

2. Archive
   ├── Product → Archive
   ├── Validate archive
   └── Upload to App Store Connect

3. TestFlight Processing
   ├── App Store Connect processes build
   ├── Export compliance review
   └── Build available for testing

4. TestFlight Beta
   └── Internal/External testers receive update
```

---

## Disaster Recovery

### Database Backups

**Neon Automatic Backups:**
- Daily backups retained for 7 days
- Point-in-time recovery available
- Manual snapshots before major changes

**Recovery Process:**
1. Identify backup restore point
2. Create new Neon branch from backup
3. Test data integrity
4. Update DATABASE_URL in Vercel
5. Redeploy

### API Rollback

**Vercel Instant Rollback:**
1. Go to Vercel Dashboard → Deployments
2. Select previous working deployment
3. Click "Promote to Production"
4. Instant rollback (< 1 minute)

### iOS Rollback

**TestFlight:**
- Previous builds remain available
- Can instruct testers to downgrade

**App Store:**
- Can't rollback published version
- Must submit new build with fixes

---

## Scaling Strategy

### Current Capacity

**Vercel:**
- Serverless: Scales automatically
- No manual scaling required
- Pay-per-use pricing

**Neon:**
- Serverless: Auto-scales compute
- Storage: 10 GB included
- Connections: Auto-pooling

**iOS:**
- Unlimited clients
- Background sync throttled to prevent API abuse

### Future Scaling Considerations

**10,000+ users:**
- Implement Redis caching (Vercel KV)
- Add rate limiting per user
- Consider CDN for static assets
- Monitor database connection limits

**100,000+ users:**
- Implement read replicas
- Add background job queue (Vercel Cron)
- Consider migrating to dedicated Postgres
- Implement advanced caching strategies

---

## Cost Estimate

### Monthly Costs (Estimated)

**Vercel Pro:**
- $20/month base
- Serverless function executions: ~$0-5
- Bandwidth: ~$0-10
- **Total: ~$20-35/month**

**Neon:**
- Free tier: 0.5 GB storage, 500 hours compute
- Paid: ~$19/month for 10 GB storage
- **Total: $0-19/month** (depending on usage)

**Apple Developer:**
- $99/year
- **Total: ~$8.25/month**

**Grand Total: ~$28-62/month**

---

## Future Enhancements

### Short Term (1-3 months)
- [ ] Implement refresh tokens
- [ ] Add rate limiting
- [ ] Set up error tracking (Sentry)
- [ ] Implement analytics (Mixpanel/Amplitude)
- [ ] Add end-to-end tests

### Medium Term (3-6 months)
- [ ] Push notifications for budget alerts
- [ ] Social features (friend comparisons)
- [ ] Advanced insights with charts
- [ ] Export data functionality
- [ ] Dark mode

### Long Term (6-12 months)
- [ ] Android app
- [ ] Web dashboard
- [ ] Family sharing
- [ ] Premium subscription tiers
- [ ] AI-powered recommendations

---

## Troubleshooting Guide

### Common Issues

**Issue: 404 on all API endpoints**
- **Cause:** Vercel not detecting serverless functions
- **Fix:** Verify Root Directory = `backend`, check vercel.json routing

**Issue: Database connection errors**
- **Cause:** Missing DATABASE_URL or invalid connection string
- **Fix:** Check Vercel environment variables, verify Neon is running

**Issue: JWT token invalid**
- **Cause:** Token expired or JWT_SECRET mismatch
- **Fix:** User must re-login, verify JWT_SECRET in Vercel matches

**Issue: iOS app can't connect to API**
- **Cause:** Wrong base URL or network error
- **Fix:** Verify Constants.swift has correct production URL, check internet

**Issue: Screen time data not syncing**
- **Cause:** Background sync disabled or iOS permissions denied
- **Fix:** Check Screen Time permission in iOS Settings

---

## Contact & Support

**Repository:** https://github.com/campbellerickson/screen-copilot

**Production URL:** https://screen-copilot-ysge.vercel.app

**Database:** Neon PostgreSQL (connection string in Vercel env)

---

*Last Updated: January 7, 2026*
