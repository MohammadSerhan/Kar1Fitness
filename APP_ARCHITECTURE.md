# KAR1 Fitness App - Architecture Overview

## Application Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      App Launch (main.dart)                  │
│                  Initialize Firebase & Providers             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
         ┌────────────────────────────┐
         │      AuthWrapper           │
         │  Check Authentication      │
         └─────┬──────────────────┬───┘
               │                  │
         Not Logged In      Logged In
               │                  │
               ▼                  ▼
    ┌──────────────────┐   ┌──────────────────┐
    │  Login Screen    │   │   Main Screen    │
    │                  │   │ (Bottom Nav)     │
    │  - Login Form    │   └────────┬─────────┘
    │  - Sign Up       │            │
    │  - Forgot Pass   │    ┌───────┼────────┐
    └──────────────────┘    │       │        │
                            ▼       ▼        ▼
                    ┌────────┐ ┌────────┐ ┌────────┐
                    │  Home  │ │ About  │ │Profile │
                    └────────┘ └────────┘ └────────┘
```

## Screen Hierarchy

```
Main Screen (Bottom Navigation)
│
├── Home Screen
│   ├── Welcome Header
│   ├── Health Stats Card
│   ├── Recommended Focus
│   └── Today's Workout List
│       └── Exercise Card → Exercise Detail Screen
│
├── About Screen
│   ├── Gym Information Card
│   └── Exercise Library
│       ├── Search Bar
│       └── Exercise List
│           └── Exercise Card → Exercise Detail Screen
│
└── Profile Screen
    ├── User Info Card
    ├── Statistics Cards
    └── Workout Frequency Chart
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Login   │  │   Home   │  │  About   │  │ Profile  │   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │   │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘   │
└────────┼─────────────┼─────────────┼─────────────┼─────────┘
         │             │             │             │
         └─────────────┴─────────────┴─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │     State Management      │
         │      (Provider)           │
         └─────────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         │      Service Layer        │
         │  ┌──────────────────────┐ │
         │  │   Auth Service       │ │
         │  │   Firestore Service  │ │
         │  │   Health Service     │ │
         │  │   Recommendation     │ │
         │  │   Service            │ │
         │  └──────────┬───────────┘ │
         └─────────────┼─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │     Backend (Firebase)    │
         │  ┌──────────────────────┐ │
         │  │   Authentication     │ │
         │  │   Cloud Firestore    │ │
         │  │   Storage            │ │
         │  └──────────────────────┘ │
         └───────────────────────────┘
```

## Service Layer Architecture

```
┌────────────────────────────────────────────────────────┐
│                   Services (Business Logic)            │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │           AuthService                           │  │
│  │  - signInWithEmailAndPassword()                 │  │
│  │  - signUpWithEmailAndPassword()                 │  │
│  │  - signOut()                                    │  │
│  │  - resetPassword()                              │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │         FirestoreService                        │  │
│  │  - getUser()                                    │  │
│  │  - getUserStream()                              │  │
│  │  - updateUser()                                 │  │
│  │  - getAllExercises()                            │  │
│  │  - getExercise()                                │  │
│  │  - addWorkout()                                 │  │
│  │  - getUserWorkouts()                            │  │
│  │  - getUserWorkoutStats()                        │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │    WorkoutRecommendationService                 │  │
│  │  - getNextExercisePlan()                        │  │
│  │  - getTodayWorkoutPlan()                        │  │
│  │  - getWeeklyWorkoutPlan()                       │  │
│  │  - Analyzes workout history                     │  │
│  │  - Recommends muscle groups                     │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
│  ┌─────────────────────────────────────────────────┐  │
│  │          HealthService                          │  │
│  │  - requestAuthorization()                       │  │
│  │  - getTodayHealthData()                         │  │
│  │  - getHealthDataForRange()                      │  │
│  │  - syncHealthData()                             │  │
│  └─────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Database Schema (Firestore)

```
Cloud Firestore
│
├── users (collection)
│   └── {userId} (document)
│       ├── email: string
│       ├── name: string
│       ├── profile_picture_url: string
│       ├── health_data: map
│       │   ├── steps: number
│       │   ├── calories: number
│       │   └── active_minutes: number
│       ├── next_exercise_plan: map
│       │   ├── targetMuscleGroup: string
│       │   └── exercises: array
│       └── created_at: timestamp
│
├── exercises (collection)
│   └── {exerciseId} (document)
│       ├── name: string
│       ├── description: string
│       ├── video_url: string
│       ├── thumbnail_url: string
│       ├── muscle_groups: array<string>
│       └── equipment: array<string>
│
└── workouts (collection)
    └── {workoutId} (document)
        ├── user_id: string
        ├── date: timestamp
        ├── duration_minutes: number
        └── exercises_completed: array<map>
            └── {
                exercise_id: string,
                sets: number,
                reps: number,
                weight: number
            }
```

## Key Design Patterns

### 1. **Repository Pattern**
Services act as repositories, abstracting data access:
```
Screen → Service → Firebase
```

### 2. **Provider Pattern (State Management)**
```dart
Provider<AuthService>
    └── Provides authentication state to all widgets
```

### 3. **Stream Builder Pattern**
Real-time data updates:
```dart
StreamBuilder<UserModel>(
  stream: firestoreService.getUserStream(userId),
  builder: (context, snapshot) { ... }
)
```

### 4. **Future Builder Pattern**
Async data loading:
```dart
FutureBuilder<List<ExerciseModel>>(
  future: recommendationService.getTodayWorkoutPlan(userId),
  builder: (context, snapshot) { ... }
)
```

## Smart Recommendation Algorithm

```
┌─────────────────────────────────────────────────────┐
│       Workout Recommendation Algorithm              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. Fetch Last 5 Workouts                          │
│     └── Query: workouts collection                  │
│                                                     │
│  2. Initialize Muscle Group Counters               │
│     └── {Chest: 0, Back: 0, Shoulders: 0,         │
│         Legs: 0, Arms: 0, Core: 0}                 │
│                                                     │
│  3. Analyze Each Workout                           │
│     ├── Get exercise details                       │
│     ├── Extract muscle groups                      │
│     └── Increment counters                         │
│                                                     │
│  4. Find Least Trained Muscle Group                │
│     └── min(muscle_group_counts)                   │
│                                                     │
│  5. Get Exercises for Target Group                 │
│     └── Filter exercises by muscle_groups          │
│                                                     │
│  6. Return Recommendation                          │
│     ├── targetMuscleGroup                          │
│     ├── exercises (list)                           │
│     └── muscleGroupStats                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Component Reusability

```
Reusable Widgets
│
├── ExerciseCard
│   ├── Used in: Home Screen
│   ├── Used in: About Screen
│   └── Props:
│       ├── exercise: ExerciseModel
│       └── onTap: Function
│
└── (Future widgets can go here)
```

## Theme Architecture

```
AppTheme (lib/theme/app_theme.dart)
│
├── Colors
│   ├── primaryYellow: #FDD835
│   ├── darkBackground: #1A1A1A
│   ├── white: #FFFFFF
│   ├── cardBackground: #2A2A2A
│   └── grey shades...
│
├── Component Themes
│   ├── AppBarTheme
│   ├── CardTheme
│   ├── ElevatedButtonTheme
│   ├── OutlinedButtonTheme
│   ├── InputDecorationTheme
│   ├── TextTheme
│   └── BottomNavigationBarTheme
│
└── Applied globally via MaterialApp
```

## Navigation Structure

```
Navigation Stack
│
├── Initial Route: AuthWrapper
│   │
│   ├── If Not Authenticated
│   │   └── LoginScreen
│   │       ├── Push → SignUpScreen
│   │       └── Push → ForgotPasswordScreen
│   │
│   └── If Authenticated
│       └── MainScreen (Bottom Navigation)
│           ├── Tab 0: HomeScreen
│           │   └── Push → ExerciseDetailScreen
│           ├── Tab 1: AboutScreen
│           │   └── Push → ExerciseDetailScreen
│           └── Tab 2: ProfileScreen
│               └── Action → Logout → LoginScreen
```

## Error Handling Strategy

```
Error Handling Flow
│
├── Try-Catch Blocks
│   └── Catch Firebase exceptions
│
├── User-Friendly Messages
│   └── Show SnackBar with error
│
├── Fallback UI
│   ├── Loading states (CircularProgressIndicator)
│   ├── Empty states (No data messages)
│   └── Error states (Error icons + messages)
│
└── Logging
    └── print() statements for debugging
```

## Security Model

```
Security Layers
│
├── Firebase Authentication
│   └── Email/Password authentication
│
├── Firestore Security Rules
│   ├── Users can only access own data
│   ├── All users can read exercises
│   └── Only authenticated users can create workouts
│
└── Client-side Validation
    ├── Form validation
    ├── Email format checking
    └── Password strength requirements
```

## Performance Optimizations

```
Performance Features
│
├── Lazy Loading
│   └── Exercise lists load on scroll
│
├── Image Caching
│   └── cached_network_image package
│
├── Video Caching
│   └── video_player package
│
├── Stream-based Updates
│   └── Real-time data without polling
│
└── Efficient Queries
    ├── Limit queries (e.g., last 30 workouts)
    └── Index-based filtering
```

## Development Workflow

```
Development Process
│
├── 1. Model Definition
│   └── Define data structures
│
├── 2. Service Layer
│   └── Implement business logic
│
├── 3. UI Implementation
│   └── Build screens and widgets
│
├── 4. Integration
│   └── Connect UI to services
│
└── 5. Testing
    ├── Manual testing
    └── User acceptance testing
```

## Deployment Architecture

```
Deployment Flow
│
├── Development
│   └── Local testing with emulators
│
├── Staging (Firebase Test Mode)
│   └── Test with real Firebase
│
└── Production
    ├── Android
    │   ├── flutter build apk
    │   └── flutter build appbundle
    │
    └── iOS
        └── flutter build ios
```

---

## Key Architectural Decisions

### Why Flutter?
- Cross-platform (one codebase for iOS and Android)
- Fast development with hot reload
- Beautiful UI with Material Design
- Strong community and packages

### Why Firebase?
- Quick backend setup
- Real-time database
- Built-in authentication
- Scalable infrastructure
- No server management

### Why Provider?
- Simple state management
- Built into Flutter
- Easy to understand
- Sufficient for app complexity

### Why Firestore over Realtime Database?
- Better querying capabilities
- Offline support
- Better structure for complex data
- Scales better for large apps

---

This architecture provides:
✅ **Scalability** - Easy to add new features
✅ **Maintainability** - Clear separation of concerns
✅ **Testability** - Services can be tested independently
✅ **Performance** - Optimized data loading and caching
✅ **Security** - Proper authentication and authorization
