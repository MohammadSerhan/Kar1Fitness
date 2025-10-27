# KAR1 Fitness Mobile App

A comprehensive gym application for the KAR1 Fitness facility, built with Flutter for both Android and iOS platforms.

## Features

- **User Authentication**: Secure login and signup with Firebase Authentication
- **Personalized Dashboard**: Welcome message, health stats, and personalized workout recommendations
- **Smart Workout Recommendations**: AI-powered algorithm that analyzes your recent workouts to suggest balanced muscle group training
- **Today's Workout Plan**: Daily exercise recommendations with detailed information
- **Exercise Library**: Comprehensive searchable library of all exercises with video demonstrations
- **Exercise Details**: Detailed exercise information including target muscles, equipment, and video tutorials
- **User Profile**: Track your progress with workout statistics and frequency charts
- **Health Data Integration**: Sync with phone's fitness app (iOS Health, Android Health Connect)
- **Modern UI**: Dark theme with KAR1 Fitness branding (yellow and dark gray color scheme)

## Screenshots

*(Add screenshots of your app here after running it)*

## Technology Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **Video Playback**: video_player, chewie
- **Charts**: fl_chart
- **UI Components**: Material Design 3

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Follow the installation guide for your operating system

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio

3. **Xcode** (for iOS development - Mac only)
   - Download from Mac App Store

4. **Firebase Project**
   - Create a project at: https://console.firebase.google.com

## Installation

### 1. Clone or Download the Project

The project is already set up in: `C:\Users\MohammadSerhan\Desktop\Kar1Fitness`

### 2. Install Flutter Dependencies

Open a terminal in the project directory and run:

```bash
flutter pub get
```

### 3. Firebase Setup

#### Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project" and follow the wizard
3. Enable Google Analytics (optional)

#### Configure Firebase for Android

1. In Firebase Console, click on Android icon
2. Enter package name: `com.kar1fitness.app`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`
5. Add the following to `android/app/build.gradle` at the bottom:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### Configure Firebase for iOS

1. In Firebase Console, click on iOS icon
2. Enter bundle ID: `com.kar1fitness.app`
3. Download `GoogleService-Info.plist`
4. Open Xcode: `open ios/Runner.xcworkspace`
5. Drag `GoogleService-Info.plist` into the Runner folder in Xcode

#### Enable Firebase Services

In Firebase Console, enable:
1. **Authentication** → Email/Password
2. **Cloud Firestore** → Create database (start in test mode)
3. **Storage** → Create storage bucket

#### Update Firebase Options

Run the FlutterFire CLI to automatically configure Firebase:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically update `lib/firebase_options.dart` with your Firebase project credentials.

### 4. Set Up Firestore Database

#### Create Collections

In Firebase Console → Firestore Database, you'll need to create these collections:

1. **users** - Will be auto-created when users sign up
2. **exercises** - Manually create and add sample exercises
3. **workouts** - Will be auto-created when users log workouts

#### Sample Exercise Document Structure

```json
{
  "name": "Bench Press",
  "description": "A compound exercise that primarily works the chest, shoulders, and triceps. Lie on a bench and lower the barbell to your chest, then press it back up.",
  "video_url": "https://example.com/videos/bench-press.mp4",
  "thumbnail_url": "https://example.com/thumbnails/bench-press.jpg",
  "muscle_groups": ["Chest", "Shoulders", "Arms"],
  "equipment": ["Barbell", "Bench"]
}
```

#### Firestore Security Rules

Update your Firestore rules:

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
      allow write: if false; // Only admins can write (manage via Firebase Console)
    }

    // Users can only access their own workouts
    match /workouts/{workoutId} {
      allow read, write: if request.auth != null &&
                           resource.data.user_id == request.auth.uid;
    }
  }
}
```

## Running the App

### Check Flutter Setup

```bash
flutter doctor
```

Ensure all checks pass (except for optional ones like Chrome for web).

### Run on Android

1. Connect an Android device or start an emulator
2. Run:
```bash
flutter run
```

### Run on iOS (Mac only)

1. Open iOS Simulator or connect an iOS device
2. Run:
```bash
flutter run
```

### Build Release Version

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

#### iOS (Mac only)
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   ├── exercise_model.dart
│   └── workout_model.dart
├── services/                 # Business logic & Firebase services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── workout_recommendation_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── about/
│   │   └── about_screen.dart
│   ├── exercise/
│   │   └── exercise_detail_screen.dart
│   └── main_screen.dart      # Bottom navigation
├── widgets/                  # Reusable widgets
│   └── exercise_card.dart
└── theme/                    # App theming
    └── app_theme.dart
```

## Key Features Explanation

### 1. Smart Workout Recommendations

The app analyzes your last 5 workouts to determine which muscle groups you've been training. It then recommends exercises targeting the least-trained muscle groups for a balanced fitness routine.

**Algorithm** (in `workout_recommendation_service.dart`):
- Tracks 6 main muscle groups: Chest, Back, Shoulders, Legs, Arms, Core
- Counts exercises per muscle group from recent workouts
- Recommends exercises for the least-trained group

### 2. Health Data Integration

The app uses the `health` package to sync with:
- **iOS**: Apple Health
- **Android**: Health Connect (Android 14+) or Google Fit

### 3. Video Player

Exercise videos are played using the `chewie` package (wrapper around `video_player`), providing:
- Play/pause controls
- Fullscreen mode
- Progress bar
- Volume controls

## Customization

### Change App Colors

Edit `lib/theme/app_theme.dart`:

```dart
static const Color primaryYellow = Color(0xFFFDD835);
static const Color darkBackground = Color(0xFF1A1A1A);
```

### Modify Muscle Groups

Edit `lib/services/workout_recommendation_service.dart`:

```dart
static const List<String> muscleGroups = [
  'Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Core',
];
```

## Troubleshooting

### Common Issues

1. **Flutter command not found**
   - Add Flutter to your PATH environment variable
   - Restart terminal/IDE

2. **Firebase initialization error**
   - Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
   - Run `flutterfire configure` again

3. **Build errors**
   - Run `flutter clean` then `flutter pub get`
   - Check that you have the correct SDK versions

4. **Video not playing**
   - Ensure video URLs are valid and accessible
   - Check internet connection
   - Videos must be in a supported format (MP4 recommended)

## Future Enhancements

- [ ] Add workout logging functionality
- [ ] Implement social features (share workouts)
- [ ] Add push notifications for workout reminders
- [ ] Integrate wearable device data
- [ ] Add meal planning and nutrition tracking
- [ ] Implement gym check-in feature with QR codes
- [ ] Add personal trainer messaging
- [ ] Create workout programs and challenges

## Contributing

This is a private gym application. For internal development:

1. Create a feature branch
2. Make your changes
3. Test thoroughly on both Android and iOS
4. Submit a pull request

## License

Proprietary - KAR1 Fitness

## Support

For issues or questions:
- Email: info@kar1fitness.com
- Phone: +1 (555) 123-4567

## Credits

Developed for KAR1 Fitness
- Design based on KAR1 Fitness branding
- Logo and branding © KAR1 Fitness

---

**Version**: 1.0.0
**Last Updated**: 2025
