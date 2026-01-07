# 📚 Documentation Index

Complete documentation for Screen Budget iOS app.

---

## 🚀 Getting Started

- **[Setup Guide](SETUP.md)** - Complete setup instructions
- **[Quick Start](QUICK_START.md)** - Fastest path to get running
- **[Migration Instructions](MIGRATION_INSTRUCTIONS.md)** - Database migration guide

---

## 📱 iOS App

- **[iOS README](../ios/README.md)** - iOS app overview
- **[iOS App Details](../ios/README_APP.md)** - Detailed iOS documentation
- **[TestFlight Guide](TESTFLIGHT_GUIDE.md)** - TestFlight setup and distribution

---

## 🏗️ Backend & Infrastructure

- **[Architecture](ARCHITECTURE.md)** - System architecture overview
- **[API Documentation](API.md)** - API endpoints reference
- **[Supabase Migration Guide](SUPABASE_MIGRATION_GUIDE.md)** - Complete migration details
- **[Supabase Setup](SUPABASE_SETUP.md)** - Supabase configuration
- **[Subscription Setup](SUBSCRIPTION_CLARIFICATION.md)** - iOS subscription configuration

---

## 🚢 Deployment

- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment
- **[Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** - Pre-deployment checklist
- **[Launch Instructions](LAUNCH_INSTRUCTIONS.md)** - Pre-launch checklist
- **[Deployment & Testing](DEPLOYMENT_AND_TESTING.md)** - Testing procedures

---

## 🔧 Configuration

- **[Setup Steps](SETUP_STEPS.md)** - Step-by-step setup
- **[Quick Setup](QUICK_SETUP.md)** - Quick reference
- **[Apple Setup](APPLE_SETUP.md)** - Apple Developer configuration
- **[Auth & Subscription Setup](AUTH_SUBSCRIPTION_SETUP.md)** - Authentication setup

---

## 📦 Archive

Historical documentation and completed guides:

- [Backend Options](../docs/archive/BACKEND_OPTIONS.md)
- [Code Analysis Summary](../docs/archive/CODE_ANALYSIS_SUMMARY.md)
- [Features Analysis](../docs/archive/FEATURES_ANALYSIS.md)
- [Features Implementation](../docs/archive/FEATURES_IMPLEMENTATION_SUMMARY.md)
- [Git Tagging](../docs/archive/GIT_TAGGING.md)
- [Local Setup Complete](../docs/archive/LOCAL_SETUP_COMPLETE.md)
- [Optimizations](../docs/archive/OPTIMIZATIONS.md)
- [Setup Complete](../docs/archive/SETUP_COMPLETE.md)
- [UI Build Complete](../docs/archive/UI_BUILD_COMPLETE.md)
- [UI Improvements](../docs/archive/UI_IMPROVEMENTS.md)
- [Vercel Migration](../docs/archive/VERCEL_MIGRATION.md) (deprecated - using Supabase)

---

## 📖 Quick Reference

### Common Tasks

**Set up database:**
1. Run `backend/ALL_MIGRATIONS.sql` in Supabase SQL Editor
2. See [Migration Instructions](MIGRATION_INSTRUCTIONS.md)

**Deploy Edge Functions:**
```bash
supabase functions deploy
```

**Update iOS app URL:**
- Edit `ios/ScreenTimeBudget/Utilities/Constants.swift`
- Set `baseURL` to your Supabase project URL

**Add environment variables:**
- Supabase Dashboard → Settings → Edge Functions → Secrets
- Add `SERVICE_ROLE_KEY`

---

## 🆘 Troubleshooting

See [Setup Guide - Troubleshooting](SETUP.md#-troubleshooting) for common issues and solutions.

---

## 📝 Contributing

Documentation improvements are welcome! Please keep documentation:
- Clear and concise
- Up-to-date with code changes
- Organized in appropriate sections

---

**Last Updated:** 2025-01-04

