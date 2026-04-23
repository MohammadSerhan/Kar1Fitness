import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/workout_template_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'exercise_selection_dialog.dart';

/// Result returned from [LogCustomWorkoutSheet]. Carries both the resolved
/// list of exercises and (when applicable) the name of the template the user
/// picked, so the home screen can label the session on the card.
class LogCustomWorkoutSelection {
  final List<ExerciseModel> exercises;

  /// Name of the template the user picked, or `null` when they bypassed
  /// templates and picked an individual exercise.
  final String? templateName;

  const LogCustomWorkoutSelection({
    required this.exercises,
    this.templateName,
  });
}

/// Bottom sheet shown by the home screen's "Log Custom Workout" button.
/// Lists available [WorkoutTemplateModel]s as tappable cards and offers a
/// fallback "pick an individual exercise" button that opens the existing
/// [ExerciseSelectionDialog]. Pops with a [LogCustomWorkoutSelection] for
/// the caller to append to the draft, or `null` if dismissed.
class LogCustomWorkoutSheet extends StatelessWidget {
  final List<WorkoutTemplateModel> templates;
  final List<ExerciseModel> allExercises;

  /// If set, the individual-exercise picker opens with this muscle group
  /// pinned to the top and expanded.
  final String? priorityMuscleGroup;

  const LogCustomWorkoutSheet({
    super.key,
    required this.templates,
    required this.allExercises,
    this.priorityMuscleGroup,
  });

  void _pickTemplate(BuildContext context, WorkoutTemplateModel template) {
    // Resolve the template's exercise ids against the full library. Drop
    // anything that no longer exists in Firestore so we don't render ghost
    // tiles for deleted exercises.
    final byId = {for (final e in allExercises) e.exerciseId: e};
    final resolved = <ExerciseModel>[];
    for (final id in template.exerciseIds) {
      final model = byId[id];
      if (model != null) resolved.add(model);
    }
    Navigator.of(context).pop(LogCustomWorkoutSelection(
      exercises: resolved,
      templateName: template.name,
    ));
  }

  Future<void> _pickIndividualExercise(BuildContext context) async {
    final selected = await showDialog<ExerciseModel>(
      context: context,
      builder: (context) => ExerciseSelectionDialog(
        exercises:
            allExercises.where((e) => e.type == ExerciseType.main).toList(),
        priorityMuscleGroup: priorityMuscleGroup,
      ),
    );
    if (!context.mounted) return;
    if (selected == null) return;
    Navigator.of(context).pop(LogCustomWorkoutSelection(
      exercises: <ExerciseModel>[selected],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.logCustomWorkout,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  l10n.noTemplatesYet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else ...[
              Text(
                l10n.templates,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryYellow,
                    ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _TemplateCard(
                    template: templates[index],
                    onTap: () => _pickTemplate(context, templates[index]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.orLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () => _pickIndividualExercise(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.pickIndividualExercise),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryYellow,
                side: const BorderSide(color: AppTheme.primaryYellow),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WorkoutTemplateModel template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muscles = template.targetMuscleGroups
        .map((m) => l10n.translateMuscleGroup(m))
        .join(', ');
    final difficulty = _difficultyLabel(template.difficulty, l10n);
    final exerciseCount = template.exerciseIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mediumGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (muscles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                muscles,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryYellow,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (template.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _metaChip(
                  context,
                  icon: Icons.bar_chart,
                  label: difficulty,
                ),
                if (template.estimatedDurationMinutes > 0)
                  _metaChip(
                    context,
                    icon: Icons.timer_outlined,
                    label:
                        '~${template.estimatedDurationMinutes} ${l10n.minutesShort}',
                  ),
                _metaChip(
                  context,
                  icon: Icons.fitness_center,
                  label: '$exerciseCount ${l10n.exercisesShort}',
                ),
                if (template.equipment.isNotEmpty)
                  _metaChip(
                    context,
                    icon: Icons.build,
                    label: template.equipment.join(', '),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context,
      {required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.lightGrey),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.lightGrey,
              ),
        ),
      ],
    );
  }

  String _difficultyLabel(
      WorkoutDifficulty difficulty, AppLocalizations l10n) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return l10n.difficultyBeginner;
      case WorkoutDifficulty.intermediate:
        return l10n.difficultyIntermediate;
      case WorkoutDifficulty.advanced:
        return l10n.difficultyAdvanced;
    }
  }
}
