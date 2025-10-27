// Temporarily disabled due to compatibility issue
// import 'package:health/health.dart';

class HealthService {
  // final Health _health = Health();

  // Define the types of health data to access
  // static final types = [
  //   HealthDataType.STEPS,
  //   HealthDataType.ACTIVE_ENERGY_BURNED,
  //   HealthDataType.WORKOUT,
  // ];

  // Request authorization to access health data
  Future<bool> requestAuthorization() async {
    // Temporarily disabled - return false
    return false;
  }

  // Get today's health data
  Future<Map<String, dynamic>> getTodayHealthData() async {
    // Temporarily disabled - return default values
    return {
      'steps': 0,
      'calories': 0,
      'active_minutes': 0,
    };
  }

  // Get health data for a date range
  Future<List<dynamic>> getHealthDataForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Temporarily disabled - return empty list
    return [];
  }

  // Check if health data is available on this device
  Future<bool> isHealthDataAvailable() async {
    // Temporarily disabled - return false
    return false;
  }

  // Sync health data to Firestore (to be called from the app)
  Future<Map<String, dynamic>> syncHealthData() async {
    return await getTodayHealthData();
  }
}
