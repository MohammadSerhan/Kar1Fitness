import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single exercise the user has checked off for a given date, together with
/// the numbers they entered in the tick sheet (sets / reps / weight).
class ExerciseDraftEntry {
  final String exerciseId;
  final int sets;
  final int reps;
  final double weight;

  const ExerciseDraftEntry({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  ExerciseDraftEntry copyWith({int? sets, int? reps, double? weight}) =>
      ExerciseDraftEntry(
        exerciseId: exerciseId,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };

  factory ExerciseDraftEntry.fromJson(Map<String, dynamic> json) =>
      ExerciseDraftEntry(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as num?)?.toInt() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Tracks which recommended exercises the user has checked off for a given
/// date, together with the sets/reps/weight they entered, and the time the
/// first exercise was marked done (used to compute workout duration).
/// Persisted locally; one draft per date; device-local, not synced.
class WorkoutDraftService {
  static String _entriesKey(DateTime date) =>
      'workout_draft_${_dateSlug(date)}';
  static String _startedAtKey(DateTime date) =>
      'workout_draft_started_${_dateSlug(date)}';

  static String _dateSlug(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, ExerciseDraftEntry>> getEntries(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // getString returns null if the value exists but is a different type
    // (e.g. a leftover StringList from the pre-JSON format) — treat as empty.
    final raw = prefs.getString(_entriesKey(date));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      final result = <String, ExerciseDraftEntry>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final entry = ExerciseDraftEntry.fromJson(item);
          result[entry.exerciseId] = entry;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> setEntries(
      DateTime date, Map<String, ExerciseDraftEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _entriesKey(date);
    if (entries.isEmpty) {
      await prefs.remove(key);
    } else {
      final list = entries.values.map((e) => e.toJson()).toList();
      await prefs.setString(key, jsonEncode(list));
    }
  }

  Future<DateTime?> getStartedAt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_startedAtKey(date));
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setStartedAt(DateTime date, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _startedAtKey(date), value.millisecondsSinceEpoch);
  }

  Future<void> clear(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey(date));
    await prefs.remove(_startedAtKey(date));
  }
}
