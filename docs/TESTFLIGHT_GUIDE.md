# TestFlight Release Guide

Complete guide for releasing Screen Time Copilot to TestFlight.

## Prerequisites

- ✅ Apple Developer Account ($99/year) - **Active and approved**
- ✅ App ID created in Apple Developer Portal
- ✅ App Store Connect app created
- ✅ Development team configured in Xcode
- ✅ Production API URL configured
- ✅ All certificates and provisioning profiles set up

---

## Step 1: Verify App Configuration

### 1.1: Check Bundle Identifier

**In Xcode:**
1. Select project → Target `ScreenTimeBudget` → General
2. Verify **Bundle Identifier:** `com.campbell.ScreenTimeCopilot`
3. This must match your App ID in Apple Developer Portal

### 1.2: Verify Version Numbers

**In Xcode:**
1. Select project → Target `ScreenTimeBudget` → General
2. **Version:** `1.0` (Marketing Version)
3. **Build:** `1` (Current Project Version)
4. Increment build number for each TestFlight upload

### 1.3: Verify Signing & Capabilities

**In Xcode:**
1. Select project → Target `ScreenTimeBudget` → Signing & Capabilities
2. Verify:
   - ✅ **Team:** Your development team selected
   - ✅ **Bundle Identifier:** `com.campbell.ScreenTimeCopilot`
   - ✅ **Signing Certificate:** Automatic (or your distribution certificate)
   - ✅ **Family Controls** capability enabled
   - ✅ **App Groups** capability enabled with: `group.com.campbell.ScreenTimeCopilot`
   - ✅ **Push Notifications** capability enabled (if using)

### 1.4: Verify Extension Configuration

**ScreenTimeReportExtension:**
1. Select project → Target `ScreenTimeReportExtension` → Signing & Capabilities
2. Verify:
   - ✅ Same team as main app
   - ✅ Bundle Identifier: `com.campbell.ScreenTimeCopilot.ScreenTimeReportExtension`
   - ✅ **App Groups** enabled with same group: `group.com.campbell.ScreenTimeCopilot`

---

## Step 2: Update Production API URL

### 2.1: Update Constants.swift

**File:** `ios/ScreenTimeBudget/Utilities/Constants.swift`

```swift
struct Constants {
    // API Configuration
    #if DEBUG
    static let baseURL = "http://192.168.68.50:3000/api/v1"  // Local dev
    #else
    static let baseURL = "https://your-production-api.vercel.app/api/v1"  // PRODUCTION
    #endif
    
    // ... rest of file
}
```

**⚠️ Important:** Replace `your-production-api.vercel.app` with your actual Vercel deployment URL!

### 2.2: Verify API is Deployed

Test your production API:
```bash
curl https://your-production-api.vercel.app/health
```

Should return:
```json
{
  "status": "ok",
  "timestamp": "...",
  "environment": "production"
}
```

---

## Step 3: Create App in App Store Connect

### 3.1: Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** → **New App**
3. Fill out:
   - **Platform:** iOS
   - **Name:** Screen Time Copilot (or your preferred name)
   - **Primary Language:** English
   - **Bundle ID:** Select `com.campbell.ScreenTimeCopilot`
   - **SKU:** `screen-time-budget-001` (unique identifier)
   - **User Access:** Full Access (or Limited if using team)

4. Click **Create**

### 3.2: Configure App Information

**App Information:**
- **Category:** Health & Fitness (or Productivity)
- **Privacy Policy URL:** (Required - add your privacy policy URL)

**Pricing and Availability:**
- Set pricing tier (Free or Paid)
- Select countries/regions

---

## Step 4: Prepare App Icon and Screenshots

### 4.1: App Icon

**Requirements:**
- 1024x1024 pixels
- PNG format
- No transparency
- No rounded corners (Apple adds them automatically)

**Location in Xcode:**
1. Select `Assets.xcassets` → `AppIcon`
2. Drag 1024x1024 icon into App Store slot

### 4.2: Screenshots (Optional for TestFlight)

For TestFlight, screenshots are optional but recommended:
- iPhone 6.7" (iPhone 14 Pro Max, etc.)
- iPhone 6.5" (iPhone 11 Pro Max, etc.)
- iPhone 5.5" (iPhone 8 Plus, etc.)

---

## Step 5: Build Archive for TestFlight

### 5.1: Clean Build

**In Xcode:**
1. Product → Clean Build Folder (⇧⌘K)
2. Wait for clean to complete

### 5.2: Select Generic iOS Device

**In Xcode:**
1. Click device selector at top (next to Play button)
2. Select **Any iOS Device** or **Generic iOS Device**

### 5.3: Create Archive

**In Xcode:**
1. Product → Archive (or ⌘B then Product → Archive)
2. Wait for archive to build (may take 2-5 minutes)
3. Organizer window opens automatically

### 5.4: Verify Archive

**In Organizer:**
1. Verify archive appears in list
2. Check:
   - ✅ App name: `ScreenTimeCopilot`
   - ✅ Version: `1.0`
   - ✅ Build: `1` (or your current build number)
   - ✅ Date: Today's date

---

## Step 6: Upload to App Store Connect

### 6.1: Distribute App

**In Organizer:**
1. Select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Click **Next**

### 6.2: Distribution Options

1. **Distribution Method:** App Store Connect
2. **Distribution Options:**
   - ✅ **Upload** (recommended for TestFlight)
   - ⬜ Export (for manual upload later)
3. Click **Next**

### 6.3: App Thinning

1. Select **All compatible device variants** (recommended)
2. Click **Next**

### 6.4: Re-sign (if needed)

If Xcode shows signing options:
1. Select **Automatically manage signing**
2. Click **Next**

### 6.5: Review and Upload

1. Review summary:
   - App: ScreenTimeCopilot
   - Version: 1.0
   - Build: 1
   - Bundle ID: com.campbell.ScreenTimeCopilot
2. Click **Upload**
3. Wait for upload (5-15 minutes depending on size)

### 6.6: Upload Progress

You'll see:
- ✅ Validating
- ✅ Processing
- ✅ Uploading
- ✅ Complete

**Note:** If upload fails, check:
- Internet connection
- Apple Developer account status
- Bundle identifier matches App Store Connect
- Certificates are valid

---

## Step 7: Process Build in App Store Connect

### 7.1: Wait for Processing

**Timeline:**
- Upload: 5-15 minutes
- Processing: 10-30 minutes (sometimes up to 1 hour)

**Check Status:**
1. Go to App Store Connect
2. Your App → TestFlight tab
3. Look for build under **iOS Builds**

### 7.2: Build Processing States

- **Processing:** Apple is processing your build
- **Ready to Submit:** Build is ready for TestFlight
- **Invalid Binary:** Build failed validation (check email for details)

### 7.3: Export Compliance

**First upload only:**
1. App Store Connect will ask about Export Compliance
2. Answer questions:
   - **Does your app use encryption?** Usually "No" (unless you use custom encryption)
   - If "Yes", you may need to provide export compliance documentation

---

## Step 8: Configure TestFlight

### 8.1: Add Test Information

**In App Store Connect:**
1. Go to your app → **TestFlight** tab
2. Select your build
3. Click **Test Information**
4. Add:
   - **What to Test:** Brief description of what testers should focus on
   - **Description:** More detailed testing instructions
   - **Feedback Email:** Your email for tester feedback

**Example:**
```
What to Test:
- Screen Time permission request flow
- Budget setup and category configuration
- Daily usage tracking and sync
- Budget overage notifications
- Dashboard display accuracy

Description:
Please test the core functionality:
1. Grant Screen Time permission when prompted
2. Set monthly budgets for different categories
3. Use apps in different categories
4. Verify usage data appears in dashboard
5. Check notifications when exceeding daily limits

Report any crashes or issues via TestFlight feedback.
```

### 8.2: Add Internal Testers

**Internal Testers (up to 100):**
1. Go to **TestFlight** → **Internal Testing**
2. Click **+** to add testers
3. Add email addresses of team members
4. They'll receive email invitation

### 8.3: Add External Testers (Beta Testing)

**External Testers (up to 10,000):**
1. Go to **TestFlight** → **External Testing**
2. Click **+** to create group
3. Name it (e.g., "Beta Testers")
4. Add your build
5. Add testers by email
6. Submit for Beta App Review (required for external testers)

**Beta App Review:**
- Apple reviews your app (usually 24-48 hours)
- Must provide:
  - App description
  - Privacy policy URL
  - Demo account (if app requires login)
  - Testing instructions

---

## Step 9: Testers Install App

### 9.1: Tester Receives Email

Testers receive email:
- Subject: "You're invited to test [App Name]"
- Contains link to install TestFlight app

### 9.2: Install TestFlight App

1. Tester opens email on iPhone
2. Clicks "View in TestFlight" or "Start Testing"
3. If TestFlight app not installed, redirects to App Store
4. Install TestFlight app (free from App Store)

### 9.3: Accept Invitation

1. Open TestFlight app
2. Tap **Accept** on invitation
3. App downloads automatically
4. Tap **Open** to launch app

---

## Step 10: Monitor TestFlight

### 10.1: View Tester Feedback

**In App Store Connect:**
1. Go to **TestFlight** → **Feedback**
2. View crash reports and tester feedback
3. Respond to testers if needed

### 10.2: View Analytics

**In App Store Connect:**
1. Go to **TestFlight** → **Analytics**
2. View:
   - Number of installs
   - Crashes
   - Tester activity

### 10.3: Update Build

**To upload new build:**
1. Increment build number in Xcode (e.g., 1 → 2)
2. Create new archive
3. Upload to App Store Connect
4. New build appears in TestFlight
5. Testers can update automatically

---

## Troubleshooting

### Build Upload Fails

**Error: "Invalid Bundle"**
- Check bundle identifier matches App Store Connect
- Verify all required capabilities are enabled
- Check Info.plist has all required keys

**Error: "Code Signing Failed"**
- Verify development team is selected
- Check certificates are valid in Keychain
- Try cleaning build folder and rebuilding

**Error: "Missing Compliance"**
- Answer export compliance questions in App Store Connect
- Provide documentation if required

### Build Processing Fails

**Error: "Invalid Binary"**
- Check email from Apple for specific errors
- Common issues:
  - Missing required permissions in Info.plist
  - Invalid entitlements
  - Missing app icon
  - Architecture issues

### Testers Can't Install

**"Unable to Install"**
- Verify tester accepted invitation
- Check TestFlight app is installed
- Verify iOS version compatibility (iOS 16.0+)
- Check device has enough storage

**"App Crashes on Launch"**
- Check crash reports in App Store Connect
- Verify API URL is correct
- Check network connectivity
- Review device logs

---

## Checklist Before Upload

- [ ] Bundle identifier matches App Store Connect
- [ ] Version and build numbers are correct
- [ ] Production API URL is set in Constants.swift
- [ ] App icon is 1024x1024 and added to Assets
- [ ] All capabilities are enabled (Family Controls, App Groups)
- [ ] Extension is properly configured
- [ ] Code signing is set to Automatic
- [ ] Archive builds successfully
- [ ] App Store Connect app is created
- [ ] Privacy policy URL is added (if required)

---

## Next Steps After TestFlight

1. **Gather Feedback:** Collect tester feedback and crash reports
2. **Fix Issues:** Address bugs and crashes
3. **Iterate:** Upload new builds with fixes
4. **Prepare for App Store:** Once stable, prepare for App Store submission
5. **App Store Review:** Submit for App Store review when ready

---

## Additional Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Good luck with your TestFlight release! 🚀**

