import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Methods
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Exercise Methods
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('exercises').get();
      return querySnapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      return [];
    }
  }

  Stream<List<ExerciseModel>> getExercisesStream() {
    return _firestore.collection('exercises').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList(),
        );
  }

  Future<ExerciseModel?> getExercise(String exerciseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('exercises').doc(exerciseId).get();
      if (doc.exists) {
        return ExerciseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting exercise: $e');
      return null;
    }
  }

  Future<List<ExerciseModel>> searchExercises(String query) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('exercises')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return querySnapshot.docs
          .map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }

  // Workout Methods
  Future<void> addWorkout(WorkoutModel workout) async {
    await _firestore.collection('workouts').add(workout.toFirestore());
  }

  Future<List<WorkoutModel>> getUserWorkouts(String userId,
      {int limit = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('workouts')
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs
          .map((doc) => WorkoutModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user workouts: $e');
      return [];
    }
  }

  Stream<List<WorkoutModel>> getUserWorkoutsStream(String userId) {
    return _firestore
        .collection('workouts')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => WorkoutModel.fromFirestore(doc)).toList(),
        );
  }

  // Get workouts for a specific date range
  Future<List<WorkoutModel>> getUserWorkoutsByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('workouts')
          .where('user_id', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => WorkoutModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting workouts by date range: $e');
      return [];
    }
  }

  // Get total workout statistics
  Future<Map<String, int>> getUserWorkoutStats(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('workouts')
          .where('user_id', isEqualTo: userId)
          .get();

      int totalWorkouts = querySnapshot.docs.length;
      int totalExercises = 0;

      for (var doc in querySnapshot.docs) {
        WorkoutModel workout = WorkoutModel.fromFirestore(doc);
        totalExercises += workout.exercisesCompleted.length;
      }

      return {
        'totalWorkouts': totalWorkouts,
        'totalExercises': totalExercises,
      };
    } catch (e) {
      print('Error getting workout stats: $e');
      return {'totalWorkouts': 0, 'totalExercises': 0};
    }
  }

  // Get workout for a specific date
  Future<WorkoutModel?> getUserWorkoutForDate(
      String userId, DateTime date) async {
    try {
      // Set time to start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await _firestore
          .collection('workouts')
          .where('user_id', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return WorkoutModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting workout for date: $e');
      return null;
    }
  }

  // Stream workout for a specific date
  Stream<WorkoutModel?> getUserWorkoutForDateStream(
      String userId, DateTime date) {
    // Set time to start and end of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('workouts')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? WorkoutModel.fromFirestore(snapshot.docs.first)
            : null);
  }
}
