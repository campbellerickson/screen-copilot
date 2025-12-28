# Screen Budget - MVP

A Screen Time Budget feature that helps users track and manage their digital wellness by setting monthly time budgets for app categories.

## Overview

**Screen Budget** mirrors traditional financial budgeting but for screen time. Users can:
- Set monthly time budgets per app category (Social Media, Entertainment, etc.)
- Track daily app usage automatically via iOS Screen Time APIs
- Receive alerts when exceeding daily budget limits
- View usage dashboards with insights

## Project Structure

```
screen-budget/
├── backend/              # Node.js/Express API
│   ├── src/
│   │   ├── config/       # Database configuration
│   │   ├── controllers/  # API controllers
│   │   ├── services/     # Business logic
│   │   ├── routes/       # API routes
│   │   ├── types/        # TypeScript types
│   │   └── server.ts     # Express server
│   ├── prisma/           # Database schema & migrations
│   └── package.json
│
├── ios/                  # iOS Swift/SwiftUI app
│   ├── CopilotScreenTime/
│   │   ├── Models/       # Data models
│   │   ├── Services/     # API & Screen Time services
│   │   ├── Utilities/    # Constants & helpers
│   │   └── ...
│   └── README.md
│
└── docs/                 # Documentation
    ├── SETUP.md          # Development setup guide
    ├── DEPLOYMENT.md     # Production deployment guide
    ├── API.md            # Complete API documentation
    └── LAUNCH_INSTRUCTIONS.md  # Quick start guide
```

## Tech Stack

### Backend
- **Language:** TypeScript
- **Framework:** Express.js
- **Database:** PostgreSQL 15+
- **ORM:** Prisma
- **Runtime:** Node.js 18+

### iOS
- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Min iOS:** 16.0+
- **Frameworks:** FamilyControls, DeviceActivity, UserNotifications

## Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL 15+ (via Docker recommended)
- Xcode 15+ (for iOS development)
- iOS device with iOS 16.0+ (Screen Time APIs require physical device)

### Backend Setup

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Start PostgreSQL (Docker)
docker-compose up -d

# Copy environment file
cp .env.example .env

# Run database migrations
npm run prisma:migrate

# Start development server
npm run dev
```

Server will be running at `http://localhost:3000`

### iOS Setup

1. Create Xcode project (see `ios/README.md`)
2. Enable required capabilities (Family Controls, App Groups, etc.)
3. Copy Swift files into project
4. Update API base URL in `Constants.swift`
5. Build and run on physical device

### Testing

```bash
# Test backend health
curl http://localhost:3000/health

# Create test budget
curl -X POST http://localhost:3000/api/v1/screen-time/budgets \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "monthYear": "2025-01-01",
    "categories": [
      {
        "categoryType": "social_media",
        "categoryName": "Social Media",
        "monthlyHours": 30,
        "isExcluded": false
      }
    ]
  }'
```

## Documentation

- **[SETUP.md](./docs/SETUP.md)** - Complete development setup guide
- **[DEPLOYMENT.md](./docs/DEPLOYMENT.md)** - Production deployment instructions
- **[API.md](./docs/API.md)** - Complete API reference
- **[LAUNCH_INSTRUCTIONS.md](./docs/LAUNCH_INSTRUCTIONS.md)** - Database & API connection setup

## MVP Features

### Implemented ✓
- Screen Time permission request flow
- Budget setup (monthly hours per category)
- Usage tracking and backend sync
- Dashboard showing usage vs budget
- Local notifications for budget overages
- Backend API with PostgreSQL storage

### Out of Scope (Post-MVP)
- Trend graphs and analytics
- App recategorization UI
- Enforcing limits (blocking apps)
- Weekly/monthly summary emails
- Multiple budget periods

## Key Workflows

### 1. Initial Setup
```
User opens app
  → Request Screen Time permission
  → Auto-detect installed apps
  → Set monthly budgets per category
  → Save to backend
```

### 2. Daily Usage Tracking
```
Background service monitors usage
  → Sync to backend every 15 minutes
  → Calculate daily budget (monthly ÷ days in month)
  → Compare actual vs budget
  → Trigger alerts if over budget
```

### 3. Dashboard View
```
User opens app
  → Fetch today's usage from backend
  → Display per-category breakdown
  → Show visual progress bars
  → Highlight over-budget categories
```

## App Categories

- **Social Media** - Instagram, TikTok, Twitter, etc.
- **Entertainment** - Netflix, YouTube, Spotify, etc.
- **Gaming** - Game apps
- **Productivity** - Notion, Slack, Email, etc.
- **Shopping** - Amazon, shopping apps
- **News & Reading** - News apps, Kindle, etc.
- **Health & Fitness** - Fitness apps
- **Other** - Uncategorized apps

Apps are auto-categorized based on bundle ID and name.

## Database Schema

Key tables:
- `users` - User accounts
- `screen_time_budgets` - Monthly budgets
- `category_budgets` - Budget per category
- `user_apps` - Detected installed apps
- `daily_app_usage` - Daily usage records
- `budget_alerts` - Alert history

See [DATABASE.md](./docs/DATABASE.md) for complete schema.

## API Endpoints

### Budget Management
- `POST /api/v1/screen-time/budgets` - Create budget
- `GET /api/v1/screen-time/budgets/:userId/current` - Get current budget
- `PUT /api/v1/screen-time/budgets/categories/:categoryId` - Update category

### Usage Tracking
- `POST /api/v1/screen-time/usage/sync` - Sync usage data
- `GET /api/v1/screen-time/usage/:userId/daily` - Get daily usage

### Alerts
- `GET /api/v1/screen-time/alerts/:userId` - Get alerts
- `POST /api/v1/screen-time/alerts/:alertId/dismiss` - Dismiss alert

See [API.md](./docs/API.md) for complete API documentation.

## Development

### Running Tests
```bash
# Backend tests (add tests first!)
cd backend
npm test
```

### Database Management
```bash
# Open Prisma Studio
npm run prisma:studio

# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# Create new migration
npx prisma migrate dev --name description
```

### Debugging
```bash
# View backend logs
npm run dev  # Shows console logs

# View database logs
docker logs copilot_screentime_db

# iOS logs
# Use Xcode console when running on device
```

## Deployment

### Backend
- **Recommended:** Railway.app (easiest setup)
- **Alternative:** Heroku, AWS, DigitalOcean

See [DEPLOYMENT.md](./docs/DEPLOYMENT.md) for detailed instructions.

### iOS
- Submit to App Store via App Store Connect
- Requires Apple Developer Account ($99/year)
- TestFlight beta available for testing

## Security & Privacy

- **Data Minimization:** Only aggregate usage data stored
- **User Control:** Users can delete all data
- **Encryption:** Sensitive data encrypted at rest (production)
- **Opt-in:** Feature is completely optional
- **Privacy Policy:** Required for App Store submission

## Known Limitations

### iOS Simulator
Screen Time APIs do NOT work in iOS Simulator. Testing requires:
- Physical iPhone or iPad
- iOS 16.0 or higher
- Screen Time permission granted

This is an Apple limitation due to privacy/security requirements.

### Background Sync
- iOS restricts background execution
- Sync occurs when app is active or via background tasks
- Not truly "real-time" - may have 15-minute delays

### App Categorization
- Auto-categorization is heuristic-based
- May miscategorize some apps
- Manual recategorization planned for future

## Troubleshooting

**Backend won't start:**
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check environment variables
cat .env

# Reinstall dependencies
rm -rf node_modules
npm install
```

**iOS app can't connect:**
- Ensure backend is running: `curl http://localhost:3000/health`
- Check `Constants.swift` has correct API URL
- For physical device, use Mac's IP address (not localhost)
- Ensure Mac and iPhone on same WiFi network

**Screen Time permission denied:**
- Check Info.plist has `NSFamilyControlsUsageDescription`
- Must use iOS 16.0+ on physical device
- Check device doesn't have parental controls enabled

## Contributing

This is an MVP. Future enhancements welcome:
- Add authentication/authorization
- Implement trend graphs
- Add app recategorization UI
- Build family sharing features
- Add gamification (streaks, achievements)

## License

MIT License (or your chosen license)

## Support

For issues or questions:
- Check documentation in `/docs`
- Review troubleshooting section above
- Open GitHub issue (if repository is public)

## Acknowledgments

Built following iOS Screen Time API best practices and Express.js conventions.

---

## Next Steps

1. Complete setup following [SETUP.md](./docs/SETUP.md)
2. Configure database and API connections via [LAUNCH_INSTRUCTIONS.md](./docs/LAUNCH_INSTRUCTIONS.md)
3. Deploy to production using [DEPLOYMENT.md](./docs/DEPLOYMENT.md)
4. Refer to [API.md](./docs/API.md) for API integration

Good luck! 🚀
