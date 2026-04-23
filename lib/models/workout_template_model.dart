import 'package:cloud_firestore/cloud_firestore.dart';

/// Difficulty level a user can expect from a template. Stored as a lowercase
/// string on the Firestore doc.
enum WorkoutDifficulty { beginner, intermediate, advanced }

WorkoutDifficulty _difficultyFrom(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'beginner':
      return WorkoutDifficulty.beginner;
    case 'advanced':
      return WorkoutDifficulty.advanced;
    case 'intermediate':
    default:
      return WorkoutDifficulty.intermediate;
  }
}

String _difficultyString(WorkoutDifficulty d) {
  switch (d) {
    case WorkoutDifficulty.beginner:
      return 'beginner';
    case WorkoutDifficulty.intermediate:
      return 'intermediate';
    case WorkoutDifficulty.advanced:
      return 'advanced';
  }
}

/// A pre-defined workout the user can pick as a starting point, e.g.
/// "Chest Day" or "Full Body Beginner". Lives in the `workout_templates`
/// Firestore collection, read-only for authenticated users.
class WorkoutTemplateModel {
  final String templateId;
  final String name;
  final String description;
  final List<String> targetMuscleGroups;
  final List<String> exerciseIds;
  final WorkoutDifficulty difficulty;
  final int estimatedDurationMinutes;
  final List<String> equipment;

  WorkoutTemplateModel({
    required this.templateId,
    required this.name,
    required this.description,
    required this.targetMuscleGroups,
    required this.exerciseIds,
    required this.difficulty,
    required this.estimatedDurationMinutes,
    required this.equipment,
  });

  factory WorkoutTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplateModel(
      templateId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      targetMuscleGroups:
          List<String>.from(data['target_muscle_groups'] ?? const []),
      exerciseIds: List<String>.from(data['exercise_ids'] ?? const []),
      difficulty: _difficultyFrom(data['difficulty'] as String?),
      estimatedDurationMinutes:
          (data['estimated_duration_minutes'] as num?)?.toInt() ?? 0,
      equipment: List<String>.from(data['equipment'] ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'target_muscle_groups': targetMuscleGroups,
        'exercise_ids': exerciseIds,
        'difficulty': _difficultyString(difficulty),
        'estimated_duration_minutes': estimatedDurationMinutes,
        'equipment': equipment,
      };
}
