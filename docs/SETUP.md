# Screen Budget - Setup Guide

## Prerequisites

### Required Software
- **Node.js** v18 or higher
- **PostgreSQL** 15 or higher (via Docker or native)
- **Docker** (recommended for database)
- **Xcode** 15.0+ (for iOS development)
- **iOS Device** running iOS 16.0+ (Screen Time APIs don't work in simulator)

### Required Accounts
- Apple Developer Account (for iOS app development)
- (Optional) Hosting service for production deployment (Railway, Heroku, etc.)

---

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Set Up Environment Variables

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` and configure:

```env
# Database Connection
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/copilot_screentime?schema=public"

# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Secret (generate a secure random string)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# CORS (allow all origins in development)
CORS_ORIGIN=*
```

**Important:** Change `JWT_SECRET` to a secure random string for production!

### 3. Start PostgreSQL Database

#### Option A: Using Docker (Recommended)

```bash
# Start PostgreSQL container
docker-compose up -d

# Verify it's running
docker ps | grep postgres
```

#### Option B: Native PostgreSQL Installation

If you have PostgreSQL installed locally:

```bash
# Create database
createdb copilot_screentime

# Verify connection
psql copilot_screentime
```

Update `DATABASE_URL` in `.env` to match your local PostgreSQL configuration.

### 4. Run Database Migrations

```bash
# Generate Prisma Client
npm run prisma:generate

# Run migrations to create tables
npm run prisma:migrate

# (Optional) Open Prisma Studio to view database
npm run prisma:studio
```

### 5. Start Development Server

```bash
npm run dev
```

You should see:
```
Server running on port 3000
```

### 6. Test API Endpoints

```bash
# Health check
curl http://localhost:3000/health

# Expected response:
# {"status":"ok","timestamp":"2025-01-15T10:00:00.000Z"}
```

---

## iOS Setup

### 1. Create Xcode Project

Since Xcode projects cannot be created programmatically, follow these steps:

1. Open Xcode
2. File → New → Project
3. Select "iOS App"
4. Configure:
   - Product Name: `CopilotScreenTime`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployments: iOS 16.0

### 2. Enable Capabilities

In Xcode:
1. Select your project in the navigator
2. Select the target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" button
5. Add the following capabilities:
   - **Family Controls**
   - **App Groups** (create group: `group.com.copilot.screentime`)
   - **Background Modes** (check "Background fetch")
   - **Push Notifications**

### 3. Update Info.plist

Add these keys to your `Info.plist`:

```xml
<key>NSFamilyControlsUsageDescription</key>
<string>Copilot needs Screen Time access to help you track and budget your app usage.</string>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.copilot.screentime.sync</string>
</array>
```

### 4. Copy Swift Files

Copy all Swift files from `ios/CopilotScreenTime/` into your Xcode project:
- Drag and drop the folders into Xcode
- Make sure "Copy items if needed" is checked
- Select your target

### 5. Create Device Activity Report Extension

1. File → New → Target
2. Select "Device Activity Report Extension"
3. Product Name: `ScreenTimeReportExtension`
4. Enable App Groups for the extension
5. Use the same identifier: `group.com.copilot.screentime`

### 6. Configure API Base URL

Edit `ios/CopilotScreenTime/Utilities/Constants.swift`:

For **iOS Simulator**:
```swift
static let baseURL = "http://localhost:3000/api/v1"
```

For **Physical Device** (find your Mac's IP):
```bash
# On Mac, run:
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Then update:
```swift
static let baseURL = "http://192.168.1.XXX:3000/api/v1"  // Replace with your Mac's IP
```

### 7. Build and Run

1. Connect iPhone via USB
2. Select your iPhone as the target device
3. Click Run (⌘R)
4. Trust developer certificate on iPhone if prompted

---

## Testing the Complete Flow

### 1. Create a Test User and Budget

```bash
# Create a budget for test user
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
      },
      {
        "categoryType": "entertainment",
        "categoryName": "Entertainment",
        "monthlyHours": 40,
        "isExcluded": false
      }
    ]
  }'
```

### 2. Verify Budget Creation

```bash
# Get current budget
curl http://localhost:3000/api/v1/screen-time/budgets/test-user-123/current
```

### 3. Simulate Usage Sync

```bash
# Sync some usage data
curl -X POST http://localhost:3000/api/v1/screen-time/usage/sync \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "usageDate": "2025-01-15",
    "apps": [
      {
        "bundleId": "com.instagram.instagram",
        "appName": "Instagram",
        "totalMinutes": 65
      },
      {
        "bundleId": "com.netflix.Netflix",
        "appName": "Netflix",
        "totalMinutes": 120
      }
    ]
  }'
```

### 4. Check Daily Usage

```bash
# Get daily usage summary
curl http://localhost:3000/api/v1/screen-time/usage/test-user-123/daily?date=2025-01-15
```

### 5. Check Alerts

```bash
# Get user alerts
curl http://localhost:3000/api/v1/screen-time/alerts/test-user-123
```

---

## Troubleshooting

### Backend Issues

**Problem:** Cannot connect to database
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Or if native:
pg_isready

# Restart PostgreSQL
docker-compose restart
```

**Problem:** Prisma errors
```bash
# Regenerate Prisma client
npm run prisma:generate

# Reset database (WARNING: deletes all data)
npx prisma migrate reset
```

### iOS Issues

**Problem:** Cannot connect to backend from device
- Ensure iPhone and Mac are on same WiFi network
- Update `Constants.swift` with Mac's local IP address
- Check Mac firewall isn't blocking port 3000

**Problem:** Screen Time permission denied
- Check `Info.plist` has `NSFamilyControlsUsageDescription`
- iOS 16.0+ required
- Must test on physical device (not simulator)

**Problem:** App Groups not working
- Verify App Group is created in Apple Developer Portal
- Both main app and extension use same App Group ID
- Clean build folder (Shift+⌘+K) and rebuild

---

## Next Steps

1. See [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment
2. See [API.md](./API.md) for complete API documentation
3. See [DATABASE.md](./DATABASE.md) for database schema details
