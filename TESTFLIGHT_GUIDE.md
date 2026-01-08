# TestFlight Deployment Guide

Complete guide for deploying Screen Time Budget to TestFlight for beta testing.

---

## Prerequisites

### 1. Apple Developer Account
- Active Apple Developer Program membership ($99/year)
- Access to https://developer.apple.com
- Team ID and provisioning profiles set up

### 2. App Store Connect Access
- Access to https://appstoreconnect.apple.com
- Admin or App Manager role

### 3. Xcode Configuration
- Latest version of Xcode installed
- Valid signing certificate
- Distribution provisioning profile

---

## Step 1: Prepare the iOS App

### A. Update Version and Build Numbers

1. Open `ScreenTimeBudget.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "ScreenTimeBudget" target
4. Go to the "General" tab
5. Update:
   - **Version**: `1.0.0` (Marketing version)
   - **Build**: Increment build number (e.g., `1`, `2`, `3`...)

### B. Verify Bundle Identifier

Ensure the bundle identifier matches:
```
com.campbell.ScreenTimeCopilot
```

### C. Configure Signing

1. Go to "Signing & Capabilities" tab
2. Check "Automatically manage signing"
3. Select your Team
4. Ensure "Release" configuration is set for distribution

### D. Verify Production API URL

Check `ios/ScreenTimeBudget/Utilities/Constants.swift`:
```swift
#else
// Production - Vercel Deployment
static let baseURL = "https://screen-copilot-ysge.vercel.app/api/v1"
#endif
```

---

## Step 2: Create App in App Store Connect

### A. Create App Record

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platforms**: iOS
   - **Name**: Screen Time Budget
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.campbell.ScreenTimeCopilot
   - **SKU**: screen-time-budget (unique identifier)
   - **User Access**: Full Access

### B. App Information

Fill in required fields:
- **Privacy Policy URL**: (Your privacy policy URL)
- **Category**: Primary - Productivity, Secondary - Health & Fitness
- **Content Rights**: Check if you have rights

### C. Pricing and Availability

- **Price**: Free (for beta testing)
- **Availability**: All countries

---

## Step 3: Build for TestFlight

### A. Archive the App

1. In Xcode, select "Any iOS Device" or a connected device (not Simulator)
2. Go to **Product** → **Archive**
3. Wait for the archive to complete (this may take a few minutes)
4. The Organizer window will open automatically

### B. Validate the Archive

1. In Organizer, select the archive
2. Click **Validate App**
3. Select your distribution certificate
4. Click **Validate**
5. Wait for validation to complete
6. Fix any errors or warnings

### C. Upload to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Click **Upload**
4. Select distribution options:
   - ✅ Upload your app's symbols to receive symbolicated reports
   - ✅ Manage Version and Build Number (Xcode will handle this)
5. Click **Upload**
6. Wait for upload to complete

---

## Step 4: Configure TestFlight

### A. Complete App Review Information

1. Go to App Store Connect → Your App → TestFlight
2. Wait for "Processing" to complete (can take 5-30 minutes)
3. Once processing is complete, you'll see the build

### B. Fill in Export Compliance

1. Click on the build
2. Answer export compliance questions:
   - **Does your app use encryption?**
     - If using HTTPS only: No
     - If using additional encryption: Yes (and provide details)
3. Click **Start Internal Testing** or **Submit for Review** (for external testing)

### C. Add Test Information (for External Testing)

If doing external testing, fill in:
- **What to Test**: Describe what testers should focus on
- **App Description**: Brief description of the app
- **Feedback Email**: Your support email
- **Marketing URL**: (optional)
- **Privacy Policy URL**: (required)

---

## Step 5: Add Beta Testers

### Internal Testing (up to 100 testers)

1. Go to TestFlight → Internal Testing
2. Create a new group (e.g., "Core Team")
3. Add testers by email
4. Testers will receive an email invitation
5. They download TestFlight app from App Store
6. Accept the invite and install your app

### External Testing (up to 10,000 testers)

1. Go to TestFlight → External Testing
2. Create a new group (e.g., "Beta Testers")
3. Add testers by email or public link
4. **Note**: External testing requires App Review (1-2 days)
5. Submit for review before testers can access

---

## Step 6: Monitor and Iterate

### A. Crash Reports

1. Go to TestFlight → your build → Crashes
2. Review crash logs and symbolicated stack traces
3. Fix critical issues

### B. Tester Feedback

1. Check feedback in TestFlight tab
2. Screenshot submissions from testers
3. Respond to feedback and iterate

### C. Release New Builds

For each new build:
1. Increment build number in Xcode
2. Archive and upload
3. Wait for processing
4. Builds automatically go to existing test groups

---

## Troubleshooting

### Build Processing Stuck
- **Issue**: Build stuck on "Processing" for hours
- **Fix**: This is normal for first build. Can take up to 48 hours. Subsequent builds process faster.

### Missing Compliance
- **Issue**: Can't start testing without export compliance
- **Fix**: Answer the encryption question. For HTTPS-only apps, select "No".

### Invalid Provisioning Profile
- **Issue**: Archive fails with provisioning error
- **Fix**: Go to Xcode → Preferences → Accounts → Download Manual Profiles

### Upload Fails
- **Issue**: Upload to App Store Connect fails
- **Fix**:
  - Check your internet connection
  - Ensure you have App Manager role
  - Try using Transporter app instead

### App Review Rejection (External Testing)
- **Issue**: Build rejected for external testing
- **Fix**: Common reasons:
  - Missing required permissions descriptions (Info.plist)
  - App crashes on launch
  - Missing functionality
  - Incomplete metadata

---

## Production Checklist

Before releasing to TestFlight, ensure:

- [ ] Production API is deployed and working (`https://screen-copilot-ysge.vercel.app`)
- [ ] Environment variables are set in Vercel
- [ ] Database is populated with schema
- [ ] API endpoints tested and responding correctly
- [ ] iOS app uses production URL in release builds
- [ ] App icons are properly set (all required sizes)
- [ ] Launch screen is configured
- [ ] Privacy permissions are described in Info.plist:
  - Screen Time permission (NSUserTrackingUsageDescription)
  - Any other required permissions
- [ ] App doesn't crash on launch
- [ ] Basic user flows work (signup, login, budget creation)
- [ ] Version and build numbers are correct
- [ ] Bundle identifier matches App Store Connect

---

## Required Info.plist Keys

Ensure these are in your `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We need access to your screen time data to help you track and manage your app usage.</string>

<key>NSPrivacyTrackingDomains</key>
<array>
    <string>screen-copilot-ysge.vercel.app</string>
</array>
```

---

## Useful Commands

### Check code signing
```bash
codesign -dv --verbose=4 /path/to/YourApp.app
```

### List provisioning profiles
```bash
security find-identity -v -p codesigning
```

### Export archive via command line (optional)
```bash
xcodebuild -exportArchive \
  -archivePath /path/to/archive.xcarchive \
  -exportPath /path/to/export \
  -exportOptionsPlist exportOptions.plist
```

---

## Next Steps After TestFlight

Once beta testing is successful:

1. **App Store Submission**
   - Fill in all App Store metadata
   - Provide screenshots (6.5", 6.7", 5.5" displays)
   - Write app description and keywords
   - Submit for App Review

2. **App Review Process**
   - Usually takes 1-3 days
   - Monitor status in App Store Connect
   - Respond promptly to any questions

3. **Release**
   - Choose manual or automatic release
   - Monitor crash reports and ratings
   - Respond to user reviews

---

## Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## Support

If you encounter issues:
1. Check Apple Developer Forums
2. Contact Apple Developer Support
3. Review rejection reasons carefully
4. Make required changes and resubmit
