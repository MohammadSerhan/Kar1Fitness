import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String exerciseId;
  final String name;
  final String description;
  final String videoUrl;
  final List<String> muscleGroups;
  final List<String> equipment;
  final String? thumbnailUrl;

  ExerciseModel({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.muscleGroups,
    required this.equipment,
    this.thumbnailUrl,
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
    };
  }
}
