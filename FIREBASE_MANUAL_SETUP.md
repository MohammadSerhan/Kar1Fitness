# Manual Firebase Configuration (Alternative Method)

If `flutterfire configure` doesn't work, follow these steps to manually configure Firebase.

## Step 1: Setup Firebase Console

### Create Firebase Project
1. Go to: https://console.firebase.google.com
2. Click "Add Project"
3. Name: "KAR1 Fitness"
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Enable Services
1. **Authentication:**
   - Build → Authentication → Get Started
   - Click "Email/Password"
   - Enable and Save

2. **Firestore:**
   - Build → Firestore Database → Create Database
   - Start in test mode
   - Select nearest location
   - Enable

3. **Storage:**
   - Build → Storage → Get Started
   - Start in test mode
   - Done

---

## Step 2: Configure Android

### 2.1 Add Android App to Firebase

1. In Firebase Console, click the **Android icon**
2. Enter package name: `com.kar1fitness.app`
3. App nickname (optional): "KAR1 Fitness Android"
4. Click "Register app"
5. **Download `google-services.json`**

### 2.2 Add google-services.json to Project

Copy the downloaded file to:
```
C:\Users\MohammadSerhan\Desktop\Kar1Fitness\android\app\google-services.json
```

### 2.3 Update Android Configuration

The following files are already configured, but verify they exist:

**File:** `android/app/build.gradle`

Make sure this line is at the **bottom** of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

**File:** `android/build.gradle`

Check that this is in the `dependencies` section:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

Both files are already set up correctly in your project!

---

## Step 3: Get Firebase Configuration Values

### 3.1 Android Configuration

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Copy these values:

   - **API Key**: `AIza...`
   - **App ID**: `1:...android`
   - **Messaging Sender ID**: `123456789`
   - **Project ID**: `kar1-fitness-xxxxx`
   - **Storage Bucket**: `kar1-fitness-xxxxx.appspot.com`

### 3.2 iOS Configuration (Optional - if you have a Mac)

1. In Firebase Console, click the **iOS icon**
2. Enter bundle ID: `com.kar1fitness.app`
3. Download `GoogleService-Info.plist`
4. Open Xcode: `open ios/Runner.xcworkspace`
5. Drag the plist file into Runner folder

---

## Step 4: Update firebase_options.dart

Open the file:
```
C:\Users\MohammadSerhan\Desktop\Kar1Fitness\lib\firebase_options.dart
```

Replace the placeholder values with your actual Firebase values from Step 3.1:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',           // Replace this
  appId: 'YOUR_ANDROID_APP_ID',             // Replace this
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // Replace this
  projectId: 'YOUR_PROJECT_ID',             // Replace this
  storageBucket: 'YOUR_STORAGE_BUCKET',     // Replace this
);
```

**Example (with fake data):**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyC1234567890abcdefghijk',
  appId: '1:123456789012:android:abc123def456',
  messagingSenderId: '123456789012',
  projectId: 'kar1-fitness-12345',
  storageBucket: 'kar1-fitness-12345.appspot.com',
);
```

---

## Step 5: Update Firestore Security Rules

1. Go to Firebase Console → Firestore Database → Rules
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // All authenticated users can read exercises
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write
    }

    // Users can only access their own workouts
    match /workouts/{workoutId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

3. Click "Publish"

---

## Step 6: Add Sample Exercise Data

### 6.1 Create Exercises Collection

1. Go to Firebase Console → Firestore Database
2. Click "Start collection"
3. Collection ID: `exercises`
4. Click "Next"

### 6.2 Add First Exercise

Document ID: Click "Auto-ID"

Add these fields (click "Add field" for each):

**Field 1:**
- Field: `name`
- Type: string
- Value: `Bench Press`

**Field 2:**
- Field: `description`
- Type: string
- Value: `A compound exercise that primarily works the chest, shoulders, and triceps. Lie on a bench and lower the barbell to your chest, then press it back up.`

**Field 3:**
- Field: `video_url`
- Type: string
- Value: `https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4`

**Field 4:**
- Field: `thumbnail_url`
- Type: string
- Value: `` (leave empty)

**Field 5:**
- Field: `muscle_groups`
- Type: array
- Click "Add item" three times and add:
  - `Chest`
  - `Arms`
  - `Shoulders`

**Field 6:**
- Field: `equipment`
- Type: array
- Click "Add item" twice and add:
  - `Barbell`
  - `Bench`

Click "Save"

### 6.3 Add More Exercises

Repeat the process for these exercises:

**Exercise 2: Squats**
```
name: "Squats"
description: "Stand with feet shoulder-width apart, lower your body by bending knees and hips, keeping chest up. Push through heels to return to standing."
video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
thumbnail_url: ""
muscle_groups: ["Legs"]
equipment: ["Barbell", "Squat Rack"]
```

**Exercise 3: Pull-ups**
```
name: "Pull-ups"
description: "Hang from a bar with hands slightly wider than shoulders. Pull yourself up until chin is above the bar. Lower with control."
video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
thumbnail_url: ""
muscle_groups: ["Back", "Arms"]
equipment: ["Pull-up Bar"]
```

**Exercise 4: Shoulder Press**
```
name: "Shoulder Press"
description: "Stand with feet shoulder-width apart. Press dumbbells overhead until arms are fully extended. Lower with control."
video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
thumbnail_url: ""
muscle_groups: ["Shoulders", "Arms"]
equipment: ["Dumbbells"]
```

**Exercise 5: Plank**
```
name: "Plank"
description: "Hold a push-up position with forearms on the ground. Keep body straight from head to heels, engaging your core."
video_url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
thumbnail_url: ""
muscle_groups: ["Core"]
equipment: ["None"]
```

---

## Step 7: Run Your App

Now you're ready!

```bash
# Navigate to project
cd C:\Users\MohammadSerhan\Desktop\Kar1Fitness

# Install dependencies
flutter pub get

# Run app
flutter run
```

---

## Verification Checklist

Before running the app, verify:

- [x] `google-services.json` is in `android/app/` folder
- [x] `lib/firebase_options.dart` has your actual Firebase values
- [x] Firebase Authentication is enabled
- [x] Firestore database is created
- [x] Firestore security rules are updated
- [x] At least 3-5 exercises are added to Firestore

---

## Troubleshooting

### Error: "No Firebase App"
- Check that `google-services.json` is in the correct location
- Verify values in `firebase_options.dart` match Firebase Console

### Error: "Permission denied"
- Update Firestore security rules (Step 5)

### Error: "Collection doesn't exist"
- Make sure you created the `exercises` collection
- Add at least one exercise document

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

---

## Need More Help?

If you're still having issues:

1. Run `flutter doctor -v` and share the output
2. Check Firebase Console for any error messages
3. Verify your `google-services.json` file exists in the correct location
4. Make sure all Firebase services are enabled in the console

---

**Once complete, your app will be fully connected to Firebase and ready to use!** 🎉
