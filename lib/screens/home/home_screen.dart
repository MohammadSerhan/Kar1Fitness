import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/health_service.dart';
import '../../services/workout_recommendation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/date_timeline_selector.dart';
import '../../widgets/health_data_card.dart';
import '../exercise/exercise_detail_screen.dart';
import '../workout/workout_recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WorkoutRecommendationService _recommendationService =
      WorkoutRecommendationService();
  DateTime _selectedDate = DateTime.now();
  bool _hasPreloaded = false;

  /// Pre-cache today's recommended exercise videos in the background.
  /// Each video is initialized (triggering the cache download) then disposed.
  Future<void> _preloadRecommendedVideos(String userId) async {
    if (_hasPreloaded) return;
    _hasPreloaded = true;

    try {
      final plan = await _recommendationService.getNextExercisePlan(userId);
      final exercises = plan['exercises'] as List<ExerciseModel>;

      for (final exercise in exercises) {
        if (exercise.videoUrl.isEmpty) continue;
        try {
          final player = CachedVideoPlayerPlus.networkUrl(
            Uri.parse(exercise.videoUrl),
          );
          await player.initialize();
          player.dispose();
        } catch (_) {
          // Skip videos that fail to preload
        }
      }
    } catch (_) {
      // Non-critical — don't block anything
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _firestoreService.getUserStream(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            // Pre-cache today's recommended exercise videos in the background
            _preloadRecommendedVideos(userId);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(user),
                    const SizedBox(height: 16),

                    // Date Timeline Selector
                    DateTimelineSelector(
                      initialDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      daysToShow: 30,
                    ),
                    const SizedBox(height: 20),

                    // Content changes based on selected date
                    ..._buildContentForDate(userId),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          user.name,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryYellow,
              ),
        ),
      ],
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Builds different content depending on whether today or a past date is selected.
  List<Widget> _buildContentForDate(String userId) {
    if (_isToday) {
      return [
        // 1. Recommended Focus
        _buildRecommendedFocus(userId),
        const SizedBox(height: 20),

        // 2. Today's Activity (Health Data)
        const HealthDataCard(),
        const SizedBox(height: 20),

        // Show today's completed workout if one exists
        _buildTodayWorkoutIfExists(userId),

        // 3. Log Workout
        _buildLogWorkoutButton(userId),
      ];
    }

    // Past date — show workout for that date + past health data
    return [
      _buildPastDateWorkout(userId),
      const SizedBox(height: 20),
      _buildPastDateHealthData(),
    ];
  }

  /// Shows today's completed workout only if one was already recorded.
  Widget _buildTodayWorkoutIfExists(String userId) {
    return StreamBuilder<WorkoutModel?>(
      stream:
          _firestoreService.getUserWorkoutForDateStream(userId, _selectedDate),
      builder: (context, snapshot) {
        final workout = snapshot.data;
        if (workout == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildWorkoutCard(workout),
        );
      },
    );
  }

  /// Shows the workout recorded on a past date, or a "no workout" message.
  Widget _buildPastDateWorkout(String userId) {
    return StreamBuilder<WorkoutModel?>(
      stream:
          _firestoreService.getUserWorkoutForDateStream(userId, _selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workout = snapshot.data;

        if (workout != null) {
          return _buildWorkoutCard(workout);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppTheme.mediumGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  'No workout on this day',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows health data for a past date, or a "not available" message.
  Widget _buildPastDateHealthData() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getHealthDataForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data;
        final hasData = data != null &&
            (((data['steps'] as int?) ?? 0) > 0 ||
            ((data['calories'] as int?) ?? 0) > 0);

        if (!hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    size: 48,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No health data available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, y').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.directions_walk,
                        label: 'Steps',
                        value: data!['steps']?.toString() ?? '0',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: data['calories']?.toString() ?? '0',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.route,
                        label: 'Distance (km)',
                        value: data['distance_km']?.toString() ?? '0.0',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.timer,
                        label: 'Active Min',
                        value: data['active_minutes']?.toString() ?? '0',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getHealthDataForDate(DateTime date) async {
    try {
      final healthService = HealthService();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final data = await healthService.getHealthDataForDate(startOfDay, endOfDay);
      return data;
    } catch (e) {
      return null;
    }
  }

  Widget _buildRecommendedFocus(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recommendationService.getNextExercisePlan(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final plan = snapshot.data!;
        final targetMuscleGroup = plan['targetMuscleGroup'] as String;
        final exercises = plan['exercises'] as List<ExerciseModel>;

        if (exercises.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: AppTheme.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppTheme.primaryYellow),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended Focus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryYellow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          color: AppTheme.primaryYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetMuscleGroup,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Based on your recent workouts',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Show the recommended exercises
                ...exercises.map((exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ExerciseCard(
                        exercise: exercise,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        },
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogWorkoutButton(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recommendationService.getNextExercisePlan(userId),
      builder: (context, snapshot) {
        final plan = snapshot.data;

        return ElevatedButton.icon(
          onPressed: () {
            _showLogWorkoutOptions(plan);
          },
          icon: const Icon(Icons.add),
          label: const Text('Log Workout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryYellow,
            foregroundColor: AppTheme.darkBackground,
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showLogWorkoutOptions(Map<String, dynamic>? plan) {
    final exercises =
        plan != null ? plan['exercises'] as List<ExerciseModel> : <ExerciseModel>[];
    final targetGroup =
        plan != null ? plan['targetMuscleGroup'] as String : 'Full Body';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Start a Workout',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                // Option 1: Recommended workout
                if (exercises.isNotEmpty)
                  _buildWorkoutOption(
                    icon: Icons.lightbulb,
                    title: 'Recommended: $targetGroup',
                    subtitle:
                        '${exercises.length} exercises based on your history',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutRecordingScreen(
                            selectedDate: _selectedDate,
                            preloadedExercises: exercises,
                          ),
                        ),
                      );
                    },
                  ),

                if (exercises.isNotEmpty) const SizedBox(height: 12),

                // Option 2: Manual / custom workout
                _buildWorkoutOption(
                  icon: Icons.edit_note,
                  title: 'Custom Workout',
                  subtitle: 'Pick your own exercises',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutRecordingScreen(
                          selectedDate: _selectedDate,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mediumGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryYellow),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.lightGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryYellow),
                    const SizedBox(width: 8),
                    Text(
                      'Workout Completed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Text(
                  '${workout.durationMinutes} min',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryYellow,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${workout.exercisesCompleted.length} exercises completed',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...workout.exercisesCompleted
                .map((exercise) => _buildExerciseCompletedItem(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCompletedItem(ExerciseCompleted exercise) {
    return FutureBuilder<ExerciseModel?>(
      future: _firestoreService.getExercise(exercise.exerciseId),
      builder: (context, snapshot) {
        final exerciseName = snapshot.data?.name ?? 'Exercise';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  size: 8, color: AppTheme.primaryYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${exercise.sets} x ${exercise.reps} @ ${exercise.weight}kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightGrey,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
