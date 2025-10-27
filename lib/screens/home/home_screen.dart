import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/workout_recommendation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/date_timeline_selector.dart';
import '../exercise/exercise_detail_screen.dart';
import '../workout/workout_recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WorkoutRecommendationService _recommendationService =
      WorkoutRecommendationService();
  DateTime _selectedDate = DateTime.now();

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
                    const SizedBox(height: 16),

                    // Workout for Selected Date
                    _buildWorkoutSection(userId),
                    const SizedBox(height: 24),

                    // Health Data Card
                    _buildHealthDataCard(user),
                    const SizedBox(height: 24),

                    // Next Exercise Plan
                    _buildNextExercisePlan(userId),
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

  Widget _buildHealthDataCard(UserModel user) {
    final healthData = user.healthData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: AppTheme.primaryYellow),
                const SizedBox(width: 8),
                Text(
                  'Health Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthStat(
                  'Steps',
                  healthData?['steps']?.toString() ?? '0',
                  Icons.directions_walk,
                ),
                _buildHealthStat(
                  'Calories',
                  healthData?['calories']?.toString() ?? '0',
                  Icons.local_fire_department,
                ),
                _buildHealthStat(
                  'Active Min',
                  healthData?['active_minutes']?.toString() ?? '0',
                  Icons.timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryYellow, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildNextExercisePlan(String userId) {
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
                    Icon(Icons.lightbulb_outline, color: AppTheme.primaryYellow),
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
                      Icon(Icons.fitness_center, color: AppTheme.primaryYellow),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutSection(String userId) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isToday
                  ? "Today's Workout"
                  : DateFormat('MMM d, y').format(_selectedDate),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<WorkoutModel?>(
          stream: _firestoreService.getUserWorkoutForDateStream(
              userId, _selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final workout = snapshot.data;

            // If workout is already recorded, show it
            if (workout != null) {
              return _buildWorkoutCard(workout);
            }

            // If today and no workout recorded, show exercise plan
            if (isToday) {
              return _buildTodayExercisePlan(userId);
            }

            // For past dates with no workout
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: AppTheme.mediumGrey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No workout on this date',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodayExercisePlan(String userId) {
    return FutureBuilder<List<ExerciseModel>>(
      future: _recommendationService.getTodayWorkoutPlan(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Unable to load workout plan',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final exercises = snapshot.data!;

        if (exercises.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No exercises available yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutRecordingScreen(
                            selectedDate: _selectedDate,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Start Custom Workout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.darkBackground,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Card(
              color: AppTheme.primaryYellow.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppTheme.primaryYellow),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended exercises for today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryYellow,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ExerciseCard(
                  exercise: exercise,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ExerciseDetailScreen(exercise: exercise),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutRecordingScreen(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.darkBackground,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        );
      },
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
                    Icon(Icons.check_circle, color: AppTheme.primaryYellow),
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
            ...workout.exercisesCompleted.map((exercise) =>
                _buildExerciseCompletedItem(exercise)),
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
              Icon(Icons.fiber_manual_record,
                  size: 8, color: AppTheme.primaryYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${exercise.sets} × ${exercise.reps} @ ${exercise.weight}kg',
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
