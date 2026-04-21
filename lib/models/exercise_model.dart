import 'package:cloud_firestore/cloud_firestore.dart';

/// Phase an exercise belongs to. Stored on Firestore as `type` on the exercise
/// doc. Older docs without the field fall back to [ExerciseType.main].
enum ExerciseType { main, warmup, cooldown }

ExerciseType _exerciseTypeFrom(String? raw) {
  switch (raw) {
    case 'warmup':
      return ExerciseType.warmup;
    case 'cooldown':
      return ExerciseType.cooldown;
    default:
      return ExerciseType.main;
  }
}

String _exerciseTypeString(ExerciseType t) {
  switch (t) {
    case ExerciseType.warmup:
      return 'warmup';
    case ExerciseType.cooldown:
      return 'cooldown';
    case ExerciseType.main:
      return 'main';
  }
}

/// Unit the user enters for each set. Cardio warm-ups use `duration` (minutes);
/// everything else uses `reps`. Stored as `metric` on the exercise doc.
enum ExerciseMetric { reps, duration }

ExerciseMetric _exerciseMetricFrom(String? raw) {
  return raw == 'duration' ? ExerciseMetric.duration : ExerciseMetric.reps;
}

String _exerciseMetricString(ExerciseMetric m) =>
    m == ExerciseMetric.duration ? 'duration' : 'reps';

class ExerciseModel {
  final String exerciseId;
  final String name;
  final String description;
  final String videoUrl;
  final List<String> muscleGroups;
  final List<String> equipment;
  final String? thumbnailUrl;
  final ExerciseType type;
  final ExerciseMetric metric;

  ExerciseModel({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.muscleGroups,
    required this.equipment,
    this.thumbnailUrl,
    this.type = ExerciseType.main,
    this.metric = ExerciseMetric.reps,
  });

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      exerciseId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['video_url'] ?? '',
      muscleGroups: List<String>.from(data['muscle_groups'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      thumbnailUrl: data['thumbnail_url'],
      type: _exerciseTypeFrom(data['type'] as String?),
      metric: _exerciseMetricFrom(data['metric'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'video_url': videoUrl,
      'muscle_groups': muscleGroups,
      'equipment': equipment,
      'thumbnail_url': thumbnailUrl,
      'type': _exerciseTypeString(type),
      'metric': _exerciseMetricString(metric),
    };
  }
}
