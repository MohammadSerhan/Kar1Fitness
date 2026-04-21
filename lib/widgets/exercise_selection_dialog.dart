import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Searchable picker over the full exercise library. Pops with the chosen
/// [ExerciseModel], or with `null` if the user dismisses the dialog.
class ExerciseSelectionDialog extends StatefulWidget {
  final List<ExerciseModel> exercises;

  const ExerciseSelectionDialog({super.key, required this.exercises});

  @override
  State<ExerciseSelectionDialog> createState() =>
      _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises
        .where((exercise) =>
            exercise.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context).selectExercise,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchExercises,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredExercises.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noExercisesFound,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(
                            exercise.muscleGroups.join(', '),
                            style: const TextStyle(color: AppTheme.lightGrey),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(exercise);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
