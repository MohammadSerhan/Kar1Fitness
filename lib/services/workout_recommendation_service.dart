import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import 'firestore_service.dart';

class WorkoutRecommendationService {
  final FirestoreService _firestoreService = FirestoreService();

  // Main muscle groups
  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Arms',
    'Core',
  ];

  /// Calculate the next recommended workout based on recent workout history
  /// This analyzes the last 5 workouts to find which muscle groups need training
  Future<Map<String, dynamic>> getNextExercisePlan(String userId) async {
    try {
      // Get last 5 workouts
      List<WorkoutModel> recentWorkouts =
          await _firestoreService.getUserWorkouts(userId, limit: 5);

      if (recentWorkouts.isEmpty) {
        // No workout history - recommend a full body workout
        return await _getDefaultWorkoutPlan();
      }

      // Count which muscle groups have been trained recently
      Map<String, int> muscleGroupCounts = {};
      for (String group in muscleGroups) {
        muscleGroupCounts[group] = 0;
      }

      // Analyze recent workouts
      for (WorkoutModel workout in recentWorkouts) {
        for (ExerciseCompleted exercise in workout.exercisesCompleted) {
          ExerciseModel? exerciseDetails =
              await _firestoreService.getExercise(exercise.exerciseId);
          if (exerciseDetails != null) {
            for (String muscleGroup in exerciseDetails.muscleGroups) {
              if (muscleGroupCounts.containsKey(muscleGroup)) {
                muscleGroupCounts[muscleGroup] =
                    muscleGroupCounts[muscleGroup]! + 1;
              }
            }
          }
        }
      }

      // Find the least trained muscle group
      String leastTrainedMuscleGroup = muscleGroups[0];
      int minCount = muscleGroupCounts[leastTrainedMuscleGroup]!;

      for (String group in muscleGroups) {
        if (muscleGroupCounts[group]! < minCount) {
          minCount = muscleGroupCounts[group]!;
          leastTrainedMuscleGroup = group;
        }
      }

      // Get exercises for the least trained muscle group
      List<ExerciseModel> allExercises =
          await _firestoreService.getAllExercises();
      List<ExerciseModel> recommendedExercises = allExercises
          .where((exercise) =>
              exercise.muscleGroups.contains(leastTrainedMuscleGroup))
          .take(5)
          .toList();

      return {
        'targetMuscleGroup': leastTrainedMuscleGroup,
        'exercises': recommendedExercises,
        'muscleGroupStats': muscleGroupCounts,
      };
    } catch (e) {
      print('Error calculating next exercise plan: $e');
      return await _getDefaultWorkoutPlan();
    }
  }

  /// Get a default workout plan for new users
  Future<Map<String, dynamic>> _getDefaultWorkoutPlan() async {
    List<ExerciseModel> allExercises =
        await _firestoreService.getAllExercises();

    // Get a balanced mix of exercises
    List<ExerciseModel> recommendedExercises = allExercises.take(5).toList();

    return {
      'targetMuscleGroup': 'Full Body',
      'exercises': recommendedExercises,
      'muscleGroupStats': {},
    };
  }

  /// Get today's workout plan
  Future<List<ExerciseModel>> getTodayWorkoutPlan(String userId) async {
    Map<String, dynamic> plan = await getNextExercisePlan(userId);
    return plan['exercises'] as List<ExerciseModel>;
  }

  /// Generate a balanced weekly workout plan
  Future<Map<String, List<ExerciseModel>>> getWeeklyWorkoutPlan() async {
    List<ExerciseModel> allExercises =
        await _firestoreService.getAllExercises();

    Map<String, List<ExerciseModel>> weeklyPlan = {};

    for (String muscleGroup in muscleGroups) {
      List<ExerciseModel> exercises = allExercises
          .where((exercise) => exercise.muscleGroups.contains(muscleGroup))
          .take(4)
          .toList();
      weeklyPlan[muscleGroup] = exercises;
    }

    return weeklyPlan;
  }
}
