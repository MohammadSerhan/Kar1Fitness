import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/workout_draft_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/exercise_selection_dialog.dart';

class WorkoutRecordingScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<ExerciseModel>? preloadedExercises;

  const WorkoutRecordingScreen({
    super.key,
    required this.selectedDate,
    this.preloadedExercises,
  });

  @override
  State<WorkoutRecordingScreen> createState() => _WorkoutRecordingScreenState();
}

class _WorkoutRecordingScreenState extends State<WorkoutRecordingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WorkoutDraftService _draftService = WorkoutDraftService();
  final List<ExerciseEntry> _exerciseEntries = [];
  DateTime? _workoutStartTime;
  bool _isRecording = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with recommended exercises if provided
    if (widget.preloadedExercises != null) {
      for (final exercise in widget.preloadedExercises!) {
        _exerciseEntries.add(ExerciseEntry(exercise: exercise));
      }
    }
    _startWorkout();
  }

  void _startWorkout() {
    setState(() {
      _workoutStartTime = DateTime.now();
      _isRecording = true;
    });
  }

  Future<void> _addExercise() async {
    final all = await _firestoreService.getAllExercises();
    // Legacy recording screen only logs main exercises; warm-ups/cool-downs
    // are wired into the home-screen flow.
    final exercises =
        all.where((e) => e.type == ExerciseType.main).toList();

    if (!mounted) return;

    final selectedExercise = await showDialog<ExerciseModel>(
      context: context,
      builder: (context) => ExerciseSelectionDialog(exercises: exercises),
    );

    if (selectedExercise != null) {
      setState(() {
        _exerciseEntries.add(ExerciseEntry(exercise: selectedExercise));
      });
    }
  }

  Future<void> _saveWorkout() async {
    final l10n = AppLocalizations.of(context);
    if (_exerciseEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillSetsReps),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate all entries have data
    for (var entry in _exerciseEntries) {
      if (entry.sets == 0 || entry.reps == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fillSetsReps),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid ?? '';

      final durationMinutes = DateTime.now().difference(_workoutStartTime!).inMinutes;

      final workout = WorkoutModel(
        workoutId: '',
        userId: userId,
        date: widget.selectedDate,
        durationMinutes: durationMinutes,
        exercisesCompleted: _exerciseEntries
            .map((entry) => ExerciseCompleted(
                  exerciseId: entry.exercise.exerciseId,
                  sets: entry.sets,
                  reps: entry.reps,
                  weight: entry.weight,
                ))
            .toList(),
      );

      // Replace any existing workout for this date, then add the new one
      // and clear the local draft of ticked exercises.
      await _firestoreService.deleteUserWorkoutsForDate(
          userId, widget.selectedDate);
      await _firestoreService.addWorkout(workout);
      await _draftService.clear(widget.selectedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).workoutSaved),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getWorkoutDuration() {
    if (_workoutStartTime == null) return '0:00';
    final duration = DateTime.now().difference(_workoutStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMM d, y').format(widget.selectedDate)),
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _getWorkoutDuration(),
                  style: const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fitness_center,
                                color: AppTheme.primaryYellow),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).recordingWorkout,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_exerciseEntries.length} / ${AppLocalizations.of(context).exercisesCompleted}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Exercise List
                Expanded(
                  child: _exerciseEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                size: 64,
                                color: AppTheme.mediumGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context).noExercisesAdded,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).tapToAddExercises,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _exerciseEntries.length,
                          itemBuilder: (context, index) {
                            return _ExerciseEntryCard(
                              entry: _exerciseEntries[index],
                              onRemove: () {
                                setState(() {
                                  _exerciseEntries.removeAt(index);
                                });
                              },
                              onChanged: () {
                                setState(() {});
                              },
                            );
                          },
                        ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGrey,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context).addExercise),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mediumGrey,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _exerciseEntries.isEmpty ? null : _saveWorkout,
                          icon: const Icon(Icons.check),
                          label:
                              Text(AppLocalizations.of(context).completeWorkout),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            foregroundColor: AppTheme.darkBackground,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ExerciseEntry {
  final ExerciseModel exercise;
  int sets;
  int reps;
  double weight;

  ExerciseEntry({
    required this.exercise,
    this.sets = 0,
    this.reps = 0,
    this.weight = 0.0,
  });
}

class _ExerciseEntryCard extends StatefulWidget {
  final ExerciseEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseEntryCard({
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExerciseEntryCard> createState() => _ExerciseEntryCardState();
}

class _ExerciseEntryCardState extends State<_ExerciseEntryCard> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
        text: widget.entry.sets > 0 ? widget.entry.sets.toString() : '');
    _repsController = TextEditingController(
        text: widget.entry.reps > 0 ? widget.entry.reps.toString() : '');
    _weightController = TextEditingController(
        text: widget.entry.weight > 0 ? widget.entry.weight.toString() : '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.entry.exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).sets,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      widget.entry.sets = int.tryParse(value) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).reps,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      widget.entry.reps = int.tryParse(value) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).weightKg,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      widget.entry.weight = double.tryParse(value) ?? 0.0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

