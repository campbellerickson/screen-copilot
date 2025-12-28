# iOS Screen Time Budget App

## Overview
This directory contains the Swift/SwiftUI files for the Screen Time Budget iOS application. These files need to be integrated into an Xcode project.

## Manual Setup Required

Since Xcode projects cannot be created programmatically, you'll need to:

1. **Create Xcode Project**
   - Open Xcode
   - File → New → Project
   - Choose "iOS App"
   - Product Name: `CopilotScreenTime`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployments: iOS 16.0

2. **Enable Required Capabilities**
   In Xcode project settings:
   - Select project → Target → Signing & Capabilities
   - Click "+ Capability"
   - Add:
     - **Family Controls**
     - **App Groups** (identifier: `group.com.copilot.screentime`)
     - **Background Modes** (select "Background fetch")
     - **Push Notifications**

3. **Update Info.plist**
   Add the following keys:
   ```xml
   <key>NSFamilyControlsUsageDescription</key>
   <string>Copilot needs Screen Time access to help you track and budget your app usage.</string>

   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
       <string>com.copilot.screentime.sync</string>
   </array>
   ```

4. **Copy Swift Files**
   Copy all files from this directory structure into your Xcode project:
   - App/
   - Models/
   - ViewModels/
   - Views/
   - Services/
   - Utilities/
   - Resources/

5. **Create Device Activity Report Extension**
   - File → New → Target
   - Choose "Device Activity Report Extension"
   - Enable App Groups for the extension
   - Use the same App Group identifier: `group.com.copilot.screentime`

## Required Frameworks
Add these frameworks to your project:
- FamilyControls
- DeviceActivity
- UserNotifications
- BackgroundTasks

## Testing
- Screen Time APIs only work on physical devices, not simulators
- You'll need to test on an iPhone running iOS 16.0+

## API Configuration
Update the `baseURL` in `Utilities/Constants.swift` with your backend API URL:
- Development: `http://localhost:3000/api/v1` (simulator)
- Development (device): `http://YOUR-MAC-IP:3000/api/v1`
- Production: Your deployed API URL

## Files Included

### Models
- `ScreenTimeBudget.swift` - Budget data models
- `AppUsage.swift` - App usage tracking models
- `BudgetStatus.swift` - Budget status and sync response models

### Services
- `APIService.swift` - Backend API communication

### Utilities
- `Constants.swift` - App constants and category definitions
- `Analytics.swift` - Analytics placeholder

## Next Steps
1. Create the Xcode project manually
2. Copy these files into the project
3. Implement the remaining service classes (see PART 1 instructions)
4. Implement ViewModels and Views (see PART 1 instructions)
5. Test on a physical device
