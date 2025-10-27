import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final Map<String, dynamic>? healthData;
  final Map<String, dynamic>? nextExercisePlan;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    this.healthData,
    this.nextExercisePlan,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse created_at safely
    DateTime createdAtDate;
    if (data['created_at'] != null) {
      if (data['created_at'] is Timestamp) {
        createdAtDate = (data['created_at'] as Timestamp).toDate();
      } else {
        createdAtDate = DateTime.now();
      }
    } else {
      createdAtDate = DateTime.now();
    }

    // Parse health_data safely
    Map<String, dynamic>? healthDataMap;
    if (data['health_data'] != null && data['health_data'] is Map) {
      healthDataMap = Map<String, dynamic>.from(data['health_data']);
    }

    // Parse next_exercise_plan safely
    Map<String, dynamic>? nextExercisePlanMap;
    if (data['next_exercise_plan'] != null && data['next_exercise_plan'] is Map) {
      nextExercisePlanMap = Map<String, dynamic>.from(data['next_exercise_plan']);
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profilePictureUrl: data['profile_picture_url'],
      healthData: healthDataMap,
      nextExercisePlan: nextExercisePlanMap,
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'profile_picture_url': profilePictureUrl,
      'health_data': healthData,
      'next_exercise_plan': nextExercisePlan,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePictureUrl,
    Map<String, dynamic>? healthData,
    Map<String, dynamic>? nextExercisePlan,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      healthData: healthData ?? this.healthData,
      nextExercisePlan: nextExercisePlan ?? this.nextExercisePlan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
