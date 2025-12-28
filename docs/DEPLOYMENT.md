# Screen Budget - Deployment Guide

## Production Deployment

This guide covers deploying the Screen Budget backend to production and preparing the iOS app for App Store submission.

---

## Backend Deployment

### Prerequisites

- [ ] PostgreSQL production database
- [ ] Hosting service account (Railway, Heroku, AWS, etc.)
- [ ] Domain name (optional but recommended)
- [ ] SSL certificate (usually provided by hosting service)

---

## Option 1: Deploy to Railway.app (Recommended for MVP)

Railway provides easy PostgreSQL hosting and automatic deployments from GitHub.

### 1. Create Railway Account

1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Create new project

### 2. Add PostgreSQL Database

```bash
# In Railway dashboard:
1. Click "New"
2. Select "Database"
3. Choose "PostgreSQL"
4. Note the connection string
```

### 3. Prepare Repository

```bash
cd backend

# Initialize git if not already done
git init

# Add .gitignore (already created)
# Commit files
git add .
git commit -m "Initial backend setup"

# Create GitHub repository
gh repo create screen-budget-backend --private --source=. --push
```

### 4. Deploy to Railway

```bash
# In Railway dashboard:
1. Click "New" → "GitHub Repo"
2. Select your repository
3. Railway will auto-detect Node.js
4. Click "Deploy"
```

### 5. Set Environment Variables

In Railway dashboard → Variables:

```env
DATABASE_URL=<Railway will auto-populate this>
PORT=3000
NODE_ENV=production
JWT_SECRET=<GENERATE_SECURE_RANDOM_STRING_HERE>
CORS_ORIGIN=https://your-domain.com
```

**Generate secure JWT_SECRET:**
```bash
# On Mac/Linux:
openssl rand -base64 32
```

### 6. Run Database Migrations

```bash
# In Railway dashboard:
1. Go to your service
2. Open "Settings"
3. Add Custom Start Command:
   npm run prisma:migrate && npm start
```

### 7. Get Production URL

Railway will provide a URL like: `https://screen-budget-backend-production.up.railway.app`

Save this URL for iOS app configuration.

---

## Option 2: Deploy to Heroku

### 1. Install Heroku CLI

```bash
brew tap heroku/brew && brew install heroku
```

### 2. Login and Create App

```bash
heroku login

cd backend
heroku create screen-budget-api
```

### 3. Add PostgreSQL

```bash
heroku addons:create heroku-postgresql:mini
```

### 4. Set Environment Variables

```bash
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=$(openssl rand -base64 32)
heroku config:set CORS_ORIGIN=https://your-domain.com
```

### 5. Deploy

```bash
git push heroku main
```

### 6. Run Migrations

```bash
heroku run npm run prisma:migrate
```

### 7. Verify Deployment

```bash
heroku open
# Visit /health endpoint
```

---

## Option 3: Deploy to AWS/DigitalOcean

### Requirements

- EC2 instance or Droplet (Ubuntu 22.04 recommended)
- PostgreSQL database (RDS or managed database)
- Domain name
- SSL certificate (Let's Encrypt)

### Quick Setup

```bash
# SSH into server
ssh ubuntu@your-server-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 (process manager)
sudo npm install -g pm2

# Clone repository
git clone https://github.com/your-username/screen-budget-backend.git
cd screen-budget-backend/backend

# Install dependencies
npm install

# Set up environment
cp .env.example .env
nano .env  # Edit with production values

# Build
npm run build

# Run migrations
npm run prisma:migrate

# Start with PM2
pm2 start dist/server.js --name screen-budget

# Auto-start on reboot
pm2 startup
pm2 save
```

### Set Up Nginx Reverse Proxy

```bash
sudo apt install nginx

# Create config
sudo nano /etc/nginx/sites-available/screen-budget
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable and restart:
```bash
sudo ln -s /etc/nginx/sites-available/screen-budget /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Add SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## iOS App Deployment

### Prerequisites

- [ ] Apple Developer Account ($99/year)
- [ ] App Store Connect account
- [ ] Provisioning profiles and certificates
- [ ] App icons and screenshots
- [ ] Privacy policy URL

### 1. Update API Base URL

Edit `Constants.swift`:

```swift
struct Constants {
    #if DEBUG
    static let baseURL = "http://localhost:3000/api/v1"
    #else
    static let baseURL = "https://your-production-api.com/api/v1"
    #endif
}
```

### 2. Configure App Signing

1. Open Xcode
2. Select project → Target
3. Go to "Signing & Capabilities"
4. Select your team
5. Ensure provisioning profile is set

### 3. Update Version and Build Number

1. Select target
2. General tab
3. Set Version (e.g., 1.0.0)
4. Set Build (e.g., 1)

### 4. Archive the App

1. In Xcode: Product → Archive
2. Wait for archive to complete
3. Organizer window will open

### 5. Validate Archive

1. Select archive
2. Click "Validate App"
3. Follow prompts
4. Fix any issues

### 6. Distribute to App Store Connect

1. Click "Distribute App"
2. Select "App Store Connect"
3. Select "Upload"
4. Follow prompts
5. Wait for processing (can take 30+ minutes)

### 7. Create App Store Listing

In [App Store Connect](https://appstoreconnect.apple.com):

1. **App Information:**
   - Name: Screen Budget
   - Subtitle: Manage Your Screen Time
   - Category: Productivity / Health & Fitness

2. **Privacy Information:**
   - Privacy Policy URL: (required)
   - Data Types Collected:
     - Screen Time Data
     - User ID
   - Purpose: App Functionality
   - Linked to User: Yes
   - Used for Tracking: No

3. **App Review Information:**
   - Demo account credentials (if needed)
   - Notes for reviewer explaining Screen Time permission

4. **Screenshots:**
   - iPhone 6.7" (required)
   - iPhone 6.5" (required)
   - iPad Pro 12.9" (optional)

5. **Description:**
   ```
   Take control of your digital wellness with Screen Budget. Set monthly
   time budgets for app categories, track your usage, and receive alerts
   when you exceed your limits.

   Features:
   • Set custom budgets per app category
   • Real-time usage tracking
   • Budget alerts and notifications
   • Beautiful dashboard with insights
   • Privacy-first: your data stays yours
   ```

### 8. Submit for Review

1. Select build
2. Add What's New in this version
3. Click "Submit for Review"
4. Wait for approval (typically 24-48 hours)

---

## Post-Deployment Checklist

### Backend
- [ ] Health endpoint accessible: `https://your-api.com/health`
- [ ] Database migrations applied
- [ ] Environment variables set correctly
- [ ] SSL certificate valid
- [ ] CORS configured for production domain
- [ ] Monitoring set up (optional: Sentry, Datadog)
- [ ] Database backups enabled
- [ ] Error logging configured

### iOS
- [ ] Production API URL configured
- [ ] App submitted to App Store
- [ ] Privacy policy published
- [ ] TestFlight beta available (optional)
- [ ] Push notification certificates configured
- [ ] Analytics configured (optional)

---

## Monitoring & Maintenance

### Backend Monitoring

**Health Checks:**
```bash
# Set up automated health check
curl https://your-api.com/health

# Expected: {"status":"ok","timestamp":"..."}
```

**Database Backups:**
```bash
# Railway: Automatic backups included
# Heroku: Enable automated backups
heroku pg:backups:schedule --at '02:00 America/Los_Angeles'

# Manual backup:
heroku pg:backups:capture
```

**Logs:**
```bash
# Railway: View in dashboard
# Heroku:
heroku logs --tail

# PM2:
pm2 logs screen-budget
```

### iOS Monitoring

**Crash Reports:**
- Monitor in App Store Connect → Analytics → Crashes

**User Feedback:**
- Monitor App Store reviews
- Set up support email in App Store listing

**Usage Analytics:**
- Track MAU (Monthly Active Users)
- Track feature adoption rate
- Monitor API success/failure rates

---

## Rollback Procedures

### Backend Rollback

**Railway:**
```bash
# In Railway dashboard:
1. Go to Deployments
2. Select previous deployment
3. Click "Redeploy"
```

**Heroku:**
```bash
heroku releases
heroku rollback v123  # Replace with version number
```

**Manual:**
```bash
# SSH into server
cd screen-budget-backend
git checkout <previous-commit>
npm install
npm run build
pm2 restart screen-budget
```

### Database Rollback

**WARNING:** Database rollbacks can cause data loss!

```bash
# Restore from backup
heroku pg:backups:restore <backup-id>

# Or for Railway, use dashboard restore feature
```

### iOS Rollback

If critical bug found after App Store release:

1. Submit expedited review for fixed version
2. (If severe) Request app removal temporarily
3. Communicate with users via App Store "What's New"

---

## Security Checklist

- [ ] JWT_SECRET is strong and unique
- [ ] DATABASE_URL is not exposed in logs
- [ ] HTTPS enforced for all API calls
- [ ] CORS properly configured
- [ ] Rate limiting enabled (optional for MVP)
- [ ] SQL injection protection (Prisma handles this)
- [ ] XSS protection enabled (Helmet middleware)
- [ ] API authentication implemented
- [ ] User data encrypted at rest
- [ ] Regular security updates applied

---

## Cost Estimates

### Backend Hosting (Monthly)

**Railway:**
- Hobby Plan: $5/month (includes PostgreSQL)
- Pro Plan: $20/month (better performance)

**Heroku:**
- Hobby Dyno: $7/month
- PostgreSQL Mini: $9/month
- **Total:** ~$16/month

**AWS (EC2 + RDS):**
- t3.micro EC2: ~$8/month
- db.t3.micro RDS: ~$15/month
- **Total:** ~$23/month

### iOS
- Apple Developer Account: $99/year

### Total First Year
- Minimum: ~$200/year (Railway + Apple)
- Mid-range: ~$400/year (Heroku + Apple)

---

## Support & Updates

### Backend Updates

```bash
# Update dependencies
npm update

# Run tests (add tests first!)
npm test

# Deploy
git push heroku main  # or railway deploy
```

### iOS Updates

1. Fix bugs or add features
2. Increment build number
3. Archive and submit new version
4. Add release notes in App Store Connect

---

## Next Steps

1. Monitor error rates and performance
2. Gather user feedback
3. Iterate on features
4. Scale infrastructure as needed
5. Consider adding:
   - Email notifications
   - Weekly/monthly reports
   - Family sharing
   - Premium features
