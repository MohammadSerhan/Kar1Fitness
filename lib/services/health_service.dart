import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  // Define the types of health data to access
  static final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.WORKOUT,
  ];

  // Request authorization to access health data.
  // On Android this opens Health Connect — the actual permission result is
  // detected later via hasPermissions() when the app resumes.
  Future<void> requestAuthorization() async {
    try {
      await _health.configure();

      // Request activity recognition permission first (Android)
      final activityStatus = await Permission.activityRecognition.request();

      if (!activityStatus.isGranted) {
        print('Activity recognition permission denied');
        return;
      }

      // Opens Health Connect permission UI on Android
      final permissions = types.map((type) => HealthDataAccess.READ_WRITE).toList();
      await _health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      print('Error requesting health authorization: $e');
    }
  }

  // Get today's health data
  Future<Map<String, dynamic>> getTodayHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Get steps
      final steps = await _getHealthDataSum(
        HealthDataType.STEPS,
        startOfDay,
        endOfDay,
      );

      // Get calories
      final calories = await _getHealthDataSum(
        HealthDataType.ACTIVE_ENERGY_BURNED,
        startOfDay,
        endOfDay,
      );

      // Get distance (in meters, convert to km)
      final distanceMeters = await _getHealthDataSum(
        HealthDataType.DISTANCE_DELTA,
        startOfDay,
        endOfDay,
      );

      // Calculate active minutes (approximate from steps - 100 steps per minute)
      final activeMinutes = steps > 0 ? (steps / 100).round() : 0;

      return {
        'steps': steps.round(),
        'calories': calories.round(),
        'distance_km': (distanceMeters / 1000).toStringAsFixed(2),
        'active_minutes': activeMinutes,
        'date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting today\'s health data: $e');
      return {
        'steps': 0,
        'calories': 0,
        'distance_km': '0.00',
        'active_minutes': 0,
        'date': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get health data for a specific date range (used for past dates)
  Future<Map<String, dynamic>> getHealthDataForDate(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    try {
      await _health.configure();

      final steps = await _getHealthDataSum(
        HealthDataType.STEPS,
        startOfDay,
        endOfDay,
      );

      final calories = await _getHealthDataSum(
        HealthDataType.ACTIVE_ENERGY_BURNED,
        startOfDay,
        endOfDay,
      );

      final distanceMeters = await _getHealthDataSum(
        HealthDataType.DISTANCE_DELTA,
        startOfDay,
        endOfDay,
      );

      final activeMinutes = steps > 0 ? (steps / 100).round() : 0;

      return {
        'steps': steps.round(),
        'calories': calories.round(),
        'distance_km': (distanceMeters / 1000).toStringAsFixed(2),
        'active_minutes': activeMinutes,
      };
    } catch (e) {
      print('Error getting health data for date: $e');
      return {
        'steps': 0,
        'calories': 0,
        'distance_km': '0.00',
        'active_minutes': 0,
      };
    }
  }

  // Get health data for a date range
  Future<List<HealthDataPoint>> getHealthDataForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate,
        types: types,
      );

      return healthData;
    } catch (e) {
      print('Error getting health data for range: $e');
      return [];
    }
  }

  // Get steps for the last 7 days
  Future<Map<String, int>> getLast7DaysSteps() async {
    try {
      final now = DateTime.now();
      final Map<String, int> dailySteps = {};

      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

        final steps = await _getHealthDataSum(
          HealthDataType.STEPS,
          startOfDay,
          endOfDay,
        );

        final dayKey = '${day.month}/${day.day}';
        dailySteps[dayKey] = steps.round();
      }

      return dailySteps;
    } catch (e) {
      print('Error getting last 7 days steps: $e');
      return {};
    }
  }

  // Get heart rate data
  Future<int?> getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (healthData.isNotEmpty) {
        final latestHR = healthData.last;
        return (latestHR.value as NumericHealthValue).numericValue.round();
      }

      return null;
    } catch (e) {
      print('Error getting heart rate: $e');
      return null;
    }
  }

  // Get weight
  Future<double?> getLatestWeight() async {
    try {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));

      final healthData = await _health.getHealthDataFromTypes(
        startTime: lastMonth,
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );

      if (healthData.isNotEmpty) {
        final latestWeight = healthData.last;
        return (latestWeight.value as NumericHealthValue).numericValue.toDouble();
      }

      return null;
    } catch (e) {
      print('Error getting weight: $e');
      return null;
    }
  }

  // Write health data (e.g., after a workout)
  Future<bool> writeWorkoutData({
    required DateTime startTime,
    required DateTime endTime,
    required int calories,
    String? workoutType,
  }) async {
    try {
      final success = await _health.writeHealthData(
        value: calories.toDouble(),
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: startTime,
        endTime: endTime,
      );

      if (success) {
        print('Workout data written successfully');
      } else {
        print('Failed to write workout data');
      }

      return success;
    } catch (e) {
      print('Error writing workout data: $e');
      return false;
    }
  }

  // Check if health data is available by attempting to read steps.
  // hasPermissions() is unreliable on Android Health Connect (returns false
  // even when permissions are granted), so we verify by reading real data.
  Future<bool> isHealthDataAvailable() async {
    try {
      await _health.configure();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      // If the call succeeds without throwing, we have permission.
      // An empty list just means no steps recorded yet, not a permission issue.
      print('Health permission verified (steps data points: ${data.length})');
      return true;
    } catch (e) {
      print('Health data not available: $e');
      return false;
    }
  }

  // Sync health data to Firestore
  Future<Map<String, dynamic>> syncHealthData() async {
    final isAvailable = await isHealthDataAvailable();

    if (!isAvailable) {
      return {
        'steps': 0,
        'calories': 0,
        'distance_km': '0.00',
        'active_minutes': 0,
        'date': DateTime.now().toIso8601String(),
      };
    }

    return await getTodayHealthData();
  }

  // Private helper method to sum health data values
  Future<double> _getHealthDataSum(
    HealthDataType type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate,
        types: [type],
      );

      if (healthData.isEmpty) {
        return 0.0;
      }

      double sum = 0.0;
      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          sum += (data.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      return sum;
    } catch (e) {
      print('Error getting health data sum for $type: $e');
      return 0.0;
    }
  }
}
