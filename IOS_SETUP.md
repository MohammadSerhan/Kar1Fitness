# iOS Setup Guide for KAR1 Fitness

## Prerequisites
- Mac computer with macOS 12.0 or later
- Xcode 14.0 or later (from Mac App Store)
- Physical iPhone or iOS Simulator
- Apple Developer Account (for physical device testing)

## Initial Setup

### 1. Install Xcode and Command Line Tools
```bash
# Install Xcode from Mac App Store first, then:
xcode-select --install
sudo xcodebuild -license accept
```

### 2. Install CocoaPods
```bash
sudo gem install cocoapods
```

### 3. Verify Flutter Setup
```bash
flutter doctor
# Fix any iOS-related issues shown
```

### 4. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### 5. Generate iOS Launcher Icons
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Running on iOS Simulator

### 1. Open iOS Simulator
```bash
open -a Simulator
```

### 2. List Available Simulators
```bash
flutter devices
```

### 3. Run the App
```bash
flutter run -d ios
# Or specify a specific simulator:
flutter run -d <simulator-id>
```

## Running on Physical iPhone

### 1. Connect iPhone via USB
- Connect your iPhone to the Mac
- Unlock your iPhone
- Tap "Trust" when prompted

### 2. Configure Code Signing in Xcode
```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Runner" in the project navigator
2. Select "Runner" target
3. Go to "Signing & Capabilities" tab
4. Check "Automatically manage signing"
5. Select your Team (add your Apple ID if needed)
6. Change the Bundle Identifier if needed (make it unique)

### 3. Run on Device
```bash
# List connected devices
flutter devices

# Run on your iPhone
flutter run -d <device-id>
```

## Important iOS-Specific Configurations

### Bundle Identifier
Default: `com.kar1fitness.app`
- You may need to change this to something unique in Xcode
- Location: `ios/Runner.xcodeproj` → Signing & Capabilities

### App Display Name
Current: "KAR1 Fitness"
- Configured in `ios/Runner/Info.plist`

### Permissions Already Configured
The app already has these iOS permissions set up:
- Health data access (for future health tracking)
- Motion data access (for activity tracking)

### Firebase Configuration
Don't forget to:
1. Add `GoogleService-Info.plist` to `ios/Runner/` directory
2. Download from Firebase Console → Project Settings → iOS app
3. Configure iOS app in Firebase Console with Bundle ID: `com.kar1fitness.app`

## Building for Release

### 1. Build IPA (for App Store/TestFlight)
```bash
flutter build ipa
```

### 2. Archive in Xcode
```bash
open ios/Runner.xcworkspace
```
Then: Product → Archive → Distribute App

## Common Issues and Solutions

### Issue: "Unable to boot simulator"
```bash
# Reset simulator
xcrun simctl erase all
```

### Issue: "Pod install" fails
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Issue: Code signing errors
- Ensure you have a valid Apple Developer account
- Check that "Automatically manage signing" is enabled
- Try changing the Bundle Identifier to something unique

### Issue: "No devices found"
```bash
# For simulator
open -a Simulator
# Wait for simulator to boot, then:
flutter devices
```

## Testing Checklist

When testing on iOS:
- [ ] App launches successfully
- [ ] Login/Signup works
- [ ] Firebase Authentication works
- [ ] Firestore data loads correctly
- [ ] Images load properly
- [ ] Navigation works
- [ ] Logout works without errors
- [ ] Charts display correctly (fl_chart)
- [ ] Video player works (if applicable)
- [ ] App icon appears correctly

## Resources

- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [App Store Distribution](https://developer.apple.com/app-store/submissions/)

## Notes

- iOS simulator does not support all device features (camera, health data, etc.)
- Physical device testing is recommended for full functionality
- First build may take 10-15 minutes
- Subsequent builds are much faster with hot reload
