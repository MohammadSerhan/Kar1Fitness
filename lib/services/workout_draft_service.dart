import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single exercise the user has checked off for a given date, together with
/// the numbers they entered in the tick sheet (sets / reps / weight, or
/// duration for cardio warm-ups).
class ExerciseDraftEntry {
  final String exerciseId;
  final int sets;
  final int reps;
  final double weight;
  final int durationMinutes;

  const ExerciseDraftEntry({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
    this.durationMinutes = 0,
  });

  ExerciseDraftEntry copyWith({
    int? sets,
    int? reps,
    double? weight,
    int? durationMinutes,
  }) =>
      ExerciseDraftEntry(
        exerciseId: exerciseId,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'durationMinutes': durationMinutes,
      };

  factory ExerciseDraftEntry.fromJson(Map<String, dynamic> json) =>
      ExerciseDraftEntry(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as num?)?.toInt() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      );
}

/// Phase of a workout an entry belongs to. The main list is the user's chosen
/// exercises; warmup is required (soft), cooldown is optional.
enum WorkoutPhase { warmup, main, cooldown }

/// Tracks which recommended exercises the user has checked off for a given
/// date, together with the sets/reps/weight they entered, and the time the
/// first exercise was marked done (used to compute workout duration).
/// Persisted locally; one draft per date; device-local, not synced. Stored
/// per-phase so warm-up and cool-down don't collide with the main log.
class WorkoutDraftService {
  static String _entriesKey(DateTime date, WorkoutPhase phase) =>
      'workout_draft_${_phaseSlug(phase)}${_dateSlug(date)}';
  static String _startedAtKey(DateTime date) =>
      'workout_draft_started_${_dateSlug(date)}';

  static String _dateSlug(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// The main phase uses the historical key prefix (no phase slug) so drafts
  /// from before warm-up/cool-down existed still load correctly.
  static String _phaseSlug(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.warmup:
        return 'warmup_';
      case WorkoutPhase.cooldown:
        return 'cooldown_';
      case WorkoutPhase.main:
        return '';
    }
  }

  Future<Map<String, ExerciseDraftEntry>> getEntries(
      DateTime date, WorkoutPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    // getString returns null if the value exists but is a different type
    // (e.g. a leftover StringList from the pre-JSON format) — treat as empty.
    final raw = prefs.getString(_entriesKey(date, phase));
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
    DateTime date,
    WorkoutPhase phase,
    Map<String, ExerciseDraftEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _entriesKey(date, phase);
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

  /// Clears the draft for the given date, across all phases.
  Future<void> clear(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    for (final phase in WorkoutPhase.values) {
      await prefs.remove(_entriesKey(date, phase));
    }
    await prefs.remove(_startedAtKey(date));
  }
}
