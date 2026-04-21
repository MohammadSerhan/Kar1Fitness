import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseCompleted {
  final String exerciseId;
  final int sets;
  final int reps;
  final double weight;
  final int durationMinutes;

  ExerciseCompleted({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
    this.durationMinutes = 0,
  });

  factory ExerciseCompleted.fromMap(Map<String, dynamic> map) {
    return ExerciseCompleted(
      exerciseId: map['exercise_id'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0).toDouble(),
      durationMinutes: map['duration_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'duration_minutes': durationMinutes,
    };
  }
}

class WorkoutModel {
  final String workoutId;
  final String userId;
  final DateTime date;
  final int durationMinutes;
  final List<ExerciseCompleted> exercisesCompleted;
  final List<ExerciseCompleted> warmupCompleted;
  final List<ExerciseCompleted> cooldownCompleted;

  WorkoutModel({
    required this.workoutId,
    required this.userId,
    required this.date,
    required this.durationMinutes,
    required this.exercisesCompleted,
    this.warmupCompleted = const [],
    this.cooldownCompleted = const [],
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<ExerciseCompleted> parseList(String key) {
      final raw = data[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ExerciseCompleted.fromMap)
          .toList();
    }

    return WorkoutModel(
      workoutId: doc.id,
      userId: data['user_id'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      durationMinutes: data['duration_minutes'] ?? 0,
      exercisesCompleted: parseList('exercises_completed'),
      warmupCompleted: parseList('warmup_completed'),
      cooldownCompleted: parseList('cooldown_completed'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'date': Timestamp.fromDate(date),
      'duration_minutes': durationMinutes,
      'exercises_completed':
          exercisesCompleted.map((e) => e.toMap()).toList(),
      'warmup_completed': warmupCompleted.map((e) => e.toMap()).toList(),
      'cooldown_completed':
          cooldownCompleted.map((e) => e.toMap()).toList(),
    };
  }
}
