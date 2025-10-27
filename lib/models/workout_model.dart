import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseCompleted {
  final String exerciseId;
  final int sets;
  final int reps;
  final double weight;

  ExerciseCompleted({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  factory ExerciseCompleted.fromMap(Map<String, dynamic> map) {
    return ExerciseCompleted(
      exerciseId: map['exercise_id'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }
}

class WorkoutModel {
  final String workoutId;
  final String userId;
  final DateTime date;
  final int durationMinutes;
  final List<ExerciseCompleted> exercisesCompleted;

  WorkoutModel({
    required this.workoutId,
    required this.userId,
    required this.date,
    required this.durationMinutes,
    required this.exercisesCompleted,
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      workoutId: doc.id,
      userId: data['user_id'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      durationMinutes: data['duration_minutes'] ?? 0,
      exercisesCompleted: (data['exercises_completed'] as List<dynamic>)
          .map((e) => ExerciseCompleted.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'date': Timestamp.fromDate(date),
      'duration_minutes': durationMinutes,
      'exercises_completed':
          exercisesCompleted.map((e) => e.toMap()).toList(),
    };
  }
}
