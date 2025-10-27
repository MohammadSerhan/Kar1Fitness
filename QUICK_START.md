# KAR1 Fitness App - Quick Start Checklist

## ⚡ Get Your App Running in 1 Hour!

Follow this checklist in order. Each step should take about 10-15 minutes.

---

## 📋 Pre-Flight Checklist

Before starting, make sure you have:
- [ ] Windows/Mac/Linux computer
- [ ] Stable internet connection
- [ ] At least 5 GB free disk space
- [ ] Administrator/sudo access on your computer

---

## Step 1: Install Flutter (20 minutes)

### Windows Users:

1. **Download Flutter**
   - [ ] Go to: https://docs.flutter.dev/get-started/install/windows
   - [ ] Download Flutter SDK ZIP
   - [ ] Extract to `C:\src\flutter`

2. **Update PATH**
   - [ ] Open "Environment Variables" from Start menu
   - [ ] Edit "Path" under User variables
   - [ ] Add: `C:\src\flutter\bin`
   - [ ] Click OK

3. **Install Android Studio**
   - [ ] Download: https://developer.android.com/studio
   - [ ] Install with default settings
   - [ ] Open Android Studio → More Actions → SDK Manager
   - [ ] Install Android SDK Platform 34

4. **Verify Installation**
   - [ ] Open Command Prompt
   - [ ] Run: `flutter doctor`
   - [ ] Fix any red X marks by following instructions

### Mac Users:

1. **Download Flutter**
   - [ ] Go to: https://docs.flutter.dev/get-started/install/macos
   - [ ] Download Flutter SDK
   - [ ] Extract to `~/development/flutter`

2. **Update PATH**
   - [ ] Open Terminal
   - [ ] Run: `nano ~/.zshrc`
   - [ ] Add: `export PATH="$PATH:$HOME/development/flutter/bin"`
   - [ ] Save and exit

3. **Install Xcode** (for iOS)
   - [ ] Install from App Store
   - [ ] Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - [ ] Run: `sudo xcodebuild -runFirstLaunch`

4. **Verify Installation**
   - [ ] Run: `flutter doctor`
   - [ ] Accept licenses: `flutter doctor --android-licenses`

---

## Step 2: Setup Firebase (15 minutes)

1. **Create Firebase Project**
   - [ ] Go to: https://console.firebase.google.com
   - [ ] Click "Add Project"
   - [ ] Name: "KAR1 Fitness"
   - [ ] Disable Google Analytics (optional)
   - [ ] Click "Create Project"

2. **Enable Authentication**
   - [ ] Go to: Build → Authentication → Get Started
   - [ ] Click "Email/Password"
   - [ ] Enable "Email/Password"
   - [ ] Save

3. **Enable Firestore**
   - [ ] Go to: Build → Firestore Database
   - [ ] Click "Create Database"
   - [ ] Select "Start in test mode"
   - [ ] Choose nearest location
   - [ ] Click "Enable"

4. **Enable Storage**
   - [ ] Go to: Build → Storage
   - [ ] Click "Get Started"
   - [ ] Start in test mode
   - [ ] Done

5. **Configure Your App (EASIEST METHOD)**
   - [ ] Open terminal in project folder: `cd C:\Users\MohammadSerhan\Desktop\Kar1Fitness`
   - [ ] Install FlutterFire: `dart pub global activate flutterfire_cli`
   - [ ] Run: `flutterfire configure`
   - [ ] Select your Firebase project
   - [ ] Select platforms: Android, iOS
   - [ ] Done! This automatically configures everything!

---

## Step 3: Add Sample Exercises (10 minutes)

1. **Go to Firestore Database**
   - [ ] Firebase Console → Firestore Database

2. **Create Collection**
   - [ ] Click "Start collection"
   - [ ] Collection ID: `exercises`
   - [ ] Auto-generate first document ID

3. **Add First Exercise**
   Click "Add field" for each:
   - [ ] `name` (string): "Bench Press"
   - [ ] `description` (string): "A compound exercise for chest, shoulders, and triceps."
   - [ ] `video_url` (string): "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   - [ ] `thumbnail_url` (string): ""
   - [ ] `muscle_groups` (array): Add 3 items: "Chest", "Arms", "Shoulders"
   - [ ] `equipment` (array): Add 2 items: "Barbell", "Bench"
   - [ ] Click "Save"

4. **Quick Add More Exercises**
   Copy this format for each:

   **Squats**
   ```
   name: "Squats"
   description: "Lower body compound exercise targeting legs and glutes."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   muscle_groups: ["Legs"]
   equipment: ["Barbell"]
   ```

   **Pull-ups**
   ```
   name: "Pull-ups"
   description: "Upper body exercise for back and arms."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   muscle_groups: ["Back", "Arms"]
   equipment: ["Pull-up Bar"]
   ```

   - [ ] Add at least 3-5 exercises total

---

## Step 4: Run the App (15 minutes)

1. **Install Dependencies**
   - [ ] Open terminal/command prompt
   - [ ] Navigate to: `cd C:\Users\MohammadSerhan\Desktop\Kar1Fitness`
   - [ ] Run: `flutter pub get`
   - [ ] Wait for completion (2-3 minutes)

2. **Start Emulator**

   **Android:**
   - [ ] Open Android Studio
   - [ ] Tools → Device Manager
   - [ ] Create Device (if none exists)
   - [ ] Select Pixel 5
   - [ ] Download system image (Android 13/14)
   - [ ] Click "Play" button to start

   **iOS (Mac only):**
   - [ ] Run: `open -a Simulator`

3. **Run the App**
   - [ ] In terminal, run: `flutter run`
   - [ ] Wait for app to build (3-5 minutes first time)
   - [ ] App should launch on emulator!

4. **Test Basic Features**
   - [ ] Click "Sign Up"
   - [ ] Create account with email/password
   - [ ] Log in
   - [ ] View Home screen
   - [ ] Tap "About" tab
   - [ ] See exercise list
   - [ ] Tap an exercise to view details
   - [ ] Check Profile tab

---

## Step 5: Troubleshooting (if needed)

### Problem: "flutter: command not found"
**Solution:**
- [ ] Restart terminal/command prompt
- [ ] Verify PATH was updated correctly
- [ ] Restart computer

### Problem: "No devices found"
**Solution:**
- [ ] Make sure emulator is running
- [ ] Run: `flutter devices` to check
- [ ] Create new emulator in Android Studio

### Problem: Firebase errors
**Solution:**
- [ ] Verify `flutterfire configure` completed successfully
- [ ] Check Firebase services are enabled
- [ ] Run: `flutter clean` then `flutter pub get`

### Problem: Build errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Still having issues?
- [ ] Check `SETUP_GUIDE.md` for detailed instructions
- [ ] Run `flutter doctor -v` for diagnostic info
- [ ] Check Firebase Console for any error messages

---

## ✅ Success! What's Next?

Once your app is running:

### Immediate Next Steps:
1. **Customize Gym Info**
   - [ ] Edit: `lib/screens/about/about_screen.dart`
   - [ ] Update location, phone, email (line ~120)

2. **Add Real Exercise Videos**
   - [ ] Upload videos to Firebase Storage
   - [ ] Update video URLs in Firestore

3. **Test All Features**
   - [ ] Create multiple test accounts
   - [ ] Add workout data
   - [ ] Check profile statistics

### Future Enhancements:
- [ ] Add workout logging UI
- [ ] Implement push notifications
- [ ] Add social features
- [ ] Create workout programs
- [ ] Build personal trainer chat

---

## 📱 Building for Real Device

### Android (APK for testing):
```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (Mac only):
```bash
flutter build ios --release
# Then archive in Xcode
```

---

## 📚 Resources

- **Full Documentation**: `README.md`
- **Detailed Setup**: `SETUP_GUIDE.md`
- **Project Overview**: `PROJECT_SUMMARY.md`
- **Flutter Docs**: https://docs.flutter.dev
- **Firebase Docs**: https://firebase.google.com/docs

---

## 🎉 Congratulations!

You now have a fully functional gym app running!

**Time taken**: ~1 hour ⏱️
**Result**: Professional fitness app ✅

### Share Your Success!
Take a screenshot of your app running and share with your team!

---

**Need help?** Check the detailed guides in:
- `README.md` - Full documentation
- `SETUP_GUIDE.md` - Step-by-step walkthrough
- `PROJECT_SUMMARY.md` - Technical details

**Happy coding!** 💻🏋️‍♂️
