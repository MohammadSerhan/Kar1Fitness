# KAR1 Fitness App - Quick Setup Guide

## Step-by-Step Installation

### Part 1: Install Flutter (20-30 minutes)

#### Windows Installation

1. **Download Flutter SDK**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Download the Flutter SDK ZIP file
   - Extract to `C:\src\flutter` (create the `src` folder if it doesn't exist)

2. **Update PATH**
   - Search "Environment Variables" in Windows Start menu
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\src\flutter\bin`
   - Click "OK" to save

3. **Install Dependencies**
   - Download and install Git: https://git-scm.com/download/win
   - Download and install Android Studio: https://developer.android.com/studio

4. **Configure Android Studio**
   - Open Android Studio
   - Go to: More Actions → SDK Manager
   - Install:
     - Android SDK Platform 34
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
   - Install Android Emulator from "SDK Tools" tab

5. **Verify Flutter Installation**
   ```bash
   flutter doctor
   ```
   - Fix any issues that appear (follow the instructions shown)

### Part 2: Firebase Setup (15 minutes)

1. **Create Firebase Project**
   - Go to: https://console.firebase.google.com
   - Click "Add Project"
   - Name: "KAR1 Fitness" (or your preferred name)
   - Disable Google Analytics (optional)
   - Click "Create Project"

2. **Configure Android App**
   - In Firebase Console, click Android icon
   - Package name: `com.kar1fitness.app`
   - Download `google-services.json`
   - Copy file to: `C:\Users\MohammadSerhan\Desktop\Kar1Fitness\android\app\`

3. **Configure iOS App** (if you have a Mac)
   - In Firebase Console, click iOS icon
   - Bundle ID: `com.kar1fitness.app`
   - Download `GoogleService-Info.plist`
   - Open: `C:\Users\MohammadSerhan\Desktop\Kar1Fitness\ios\Runner.xcworkspace` in Xcode
   - Drag the plist file into the Runner folder

4. **Enable Firebase Services**

   **Authentication:**
   - Go to: Build → Authentication → Get Started
   - Click "Email/Password"
   - Enable "Email/Password"
   - Click "Save"

   **Firestore:**
   - Go to: Build → Firestore Database → Create Database
   - Choose "Start in test mode"
   - Select a location closest to you
   - Click "Enable"

   **Storage:**
   - Go to: Build → Storage → Get Started
   - Choose "Start in test mode"
   - Click "Next" and "Done"

5. **Use FlutterFire CLI** (Recommended - Automatic Configuration)
   ```bash
   # In your project directory
   cd C:\Users\MohammadSerhan\Desktop\Kar1Fitness

   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure Firebase
   flutterfire configure --project=your-firebase-project-id
   ```

   This will automatically update `lib/firebase_options.dart` with your credentials!

### Part 3: Add Sample Data to Firestore (10 minutes)

1. **Open Firestore Database**
   - Go to Firebase Console → Firestore Database

2. **Create Exercises Collection**
   - Click "Start collection"
   - Collection ID: `exercises`
   - Add first document with Auto-ID

3. **Add Sample Exercises**

   Copy and paste these one by one:

   **Exercise 1: Bench Press**
   ```
   name: "Bench Press"
   description: "A compound exercise that primarily works the chest, shoulders, and triceps. Lie on a bench and lower the barbell to your chest, then press it back up."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Chest", "Arms", "Shoulders"]
   equipment: ["Barbell", "Bench"]
   ```

   **Exercise 2: Squats**
   ```
   name: "Barbell Squat"
   description: "Stand with feet shoulder-width apart, barbell on upper back. Lower your body by bending knees and hips, keeping chest up. Push through heels to return to standing."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Legs"]
   equipment: ["Barbell", "Squat Rack"]
   ```

   **Exercise 3: Deadlift**
   ```
   name: "Deadlift"
   description: "Stand with feet hip-width apart, bend at hips and knees to grasp barbell. Lift by extending hips and knees, keeping back straight."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Back", "Legs"]
   equipment: ["Barbell"]
   ```

   **Exercise 4: Shoulder Press**
   ```
   name: "Overhead Press"
   description: "Stand with feet shoulder-width apart. Press barbell or dumbbells overhead until arms are fully extended. Lower with control."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Shoulders", "Arms"]
   equipment: ["Barbell", "Dumbbells"]
   ```

   **Exercise 5: Pull-ups**
   ```
   name: "Pull-ups"
   description: "Hang from a bar with hands slightly wider than shoulders. Pull yourself up until chin is above the bar. Lower with control."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Back", "Arms"]
   equipment: ["Pull-up Bar"]
   ```

   **Exercise 6: Plank**
   ```
   name: "Plank"
   description: "Hold a push-up position with forearms on the ground. Keep body straight from head to heels, engaging your core."
   video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
   thumbnail_url: ""
   muscle_groups: ["Core"]
   equipment: ["None"]
   ```

   *Note: Using sample video URLs for demonstration. Replace with actual exercise videos later.*

### Part 4: Run the App (5 minutes)

1. **Open Project in Terminal/Command Prompt**
   ```bash
   cd C:\Users\MohammadSerhan\Desktop\Kar1Fitness
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Start Android Emulator**
   - Open Android Studio
   - Go to: Tools → Device Manager
   - Click "Create Device"
   - Select a device (e.g., Pixel 5)
   - Download a system image (Android 13 or 14)
   - Click "Finish" and then "Play" to start the emulator

4. **Run the App**
   ```bash
   flutter run
   ```

5. **Test the App**
   - Create a new account using the Sign Up button
   - Log in with your credentials
   - Explore the Home, About, and Profile screens
   - Click on exercises to view details

### Part 5: Update Firestore Security Rules (5 minutes)

1. **Go to Firestore Database → Rules**

2. **Replace the rules with:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }

       match /exercises/{exerciseId} {
         allow read: if request.auth != null;
         allow write: if false;
       }

       match /workouts/{workoutId} {
         allow read, write: if request.auth != null;
         allow create: if request.auth != null;
       }
     }
   }
   ```

3. **Click "Publish"**

## Troubleshooting

### "flutter: command not found"
- Make sure you added Flutter to PATH
- Restart your terminal/command prompt
- Restart your computer if needed

### "No devices found"
- Make sure Android Emulator is running
- Run `flutter devices` to see available devices

### Firebase errors
- Ensure `google-services.json` is in `android/app/` folder
- Run `flutterfire configure` again
- Check that Firebase services are enabled in console

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Video not playing
- The sample video URL should work for testing
- Replace with real exercise videos later
- Ensure device has internet connection

## Next Steps

1. **Add Your Gym Information**
   - Edit `lib/screens/about/about_screen.dart`
   - Update location, phone, email, and hours

2. **Add More Exercises**
   - Add more exercise documents in Firestore
   - Upload exercise videos to Firebase Storage
   - Update video URLs in Firestore

3. **Customize Branding**
   - The app already uses your KAR1 Fitness logo colors
   - Logo is in `assets/images/logo.png`

4. **Build Release Version**
   ```bash
   # Android
   flutter build apk --release

   # The APK will be in: build/app/outputs/flutter-apk/app-release.apk
   ```

## Need Help?

Common commands:
```bash
flutter doctor          # Check setup
flutter devices         # List available devices
flutter clean           # Clean build files
flutter pub get         # Install dependencies
flutter run             # Run app
flutter build apk       # Build Android APK
```

## Video Upload Instructions

To add real exercise videos:

1. **Prepare Videos**
   - Format: MP4 (H.264)
   - Resolution: 720p or 1080p
   - Duration: 30-60 seconds per exercise

2. **Upload to Firebase Storage**
   - Go to Firebase Console → Storage
   - Create folder: `exercise_videos/`
   - Upload your videos
   - For each video, click "…" → "Get download URL"
   - Copy the URL

3. **Update Firestore**
   - Go to Firestore Database
   - Find the exercise document
   - Update the `video_url` field with the download URL

---

**Congratulations!** Your KAR1 Fitness app is now ready! 🎉
