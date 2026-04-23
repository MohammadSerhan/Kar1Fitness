import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Searchable picker over the full exercise library. Pops with the chosen
/// [ExerciseModel], or with `null` if the user dismisses the dialog.
///
/// Exercises are grouped by their primary muscle group (first entry in
/// [ExerciseModel.muscleGroups]). When [priorityMuscleGroup] is given, that
/// group is pinned to the top and expanded by default — handy for nudging
/// the user toward their current recommended focus. When the user types in
/// the search field, grouping is bypassed and results show flat.
class ExerciseSelectionDialog extends StatefulWidget {
  final List<ExerciseModel> exercises;

  /// Group to surface first and auto-expand. Matches against English muscle
  /// group strings (the raw values stored on [ExerciseModel.muscleGroups]).
  final String? priorityMuscleGroup;

  const ExerciseSelectionDialog({
    super.key,
    required this.exercises,
    this.priorityMuscleGroup,
  });

  @override
  State<ExerciseSelectionDialog> createState() =>
      _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  static const List<String> _canonicalOrder = [
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Arms',
    'Core',
    'Full Body',
  ];
  static const String _otherGroup = 'Other';

  String _searchQuery = '';
  late final List<String> _orderedGroups;
  late final Map<String, List<ExerciseModel>> _byGroup;
  final Set<String> _openGroups = {};

  @override
  void initState() {
    super.initState();
    _byGroup = _bucketByPrimaryMuscle(widget.exercises);
    _orderedGroups = _orderGroups(_byGroup.keys, widget.priorityMuscleGroup);

    // Priority group opens by default; all others collapsed. If the priority
    // wasn't present, fall back to opening the first group so the dialog
    // isn't a wall of closed rows.
    final priority = widget.priorityMuscleGroup;
    if (priority != null && _byGroup.containsKey(priority)) {
      _openGroups.add(priority);
    } else if (_orderedGroups.isNotEmpty) {
      _openGroups.add(_orderedGroups.first);
    }
  }

  static Map<String, List<ExerciseModel>> _bucketByPrimaryMuscle(
      List<ExerciseModel> exercises) {
    final map = <String, List<ExerciseModel>>{};
    for (final ex in exercises) {
      final group =
          ex.muscleGroups.isNotEmpty ? ex.muscleGroups.first : _otherGroup;
      map.putIfAbsent(group, () => []).add(ex);
    }
    for (final list in map.values) {
      list.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  }

  static List<String> _orderGroups(
      Iterable<String> groups, String? priority) {
    final remaining = Set<String>.from(groups);
    final ordered = <String>[];
    if (priority != null && remaining.remove(priority)) {
      ordered.add(priority);
    }
    for (final g in _canonicalOrder) {
      if (remaining.remove(g)) ordered.add(g);
    }
    final leftovers = remaining.toList()..sort();
    ordered.addAll(leftovers);
    return ordered;
  }

  void _toggleGroup(String group) {
    setState(() {
      if (!_openGroups.remove(group)) _openGroups.add(group);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _searchQuery.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;

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
                    l10n.selectExercise,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchExercises,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: hasQuery
                  ? _buildFlatResults(query, l10n)
                  : _buildGroupedList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatResults(String query, AppLocalizations l10n) {
    final matches = <ExerciseModel>[];
    for (final group in _orderedGroups) {
      for (final ex in _byGroup[group]!) {
        if (ex.name.toLowerCase().contains(query)) matches.add(ex);
      }
    }
    if (matches.isEmpty) {
      return Center(
        child: Text(
          l10n.noExercisesFound,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) => _buildExerciseTile(matches[index]),
    );
  }

  Widget _buildGroupedList(AppLocalizations l10n) {
    if (_orderedGroups.isEmpty) {
      return Center(
        child: Text(
          l10n.noExercisesFound,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: _orderedGroups.length,
      itemBuilder: (context, index) {
        final group = _orderedGroups[index];
        final exercises = _byGroup[group]!;
        final isOpen = _openGroups.contains(group);
        final isPriority = group == widget.priorityMuscleGroup;
        return _buildGroupSection(
          group: group,
          exercises: exercises,
          isOpen: isOpen,
          isPriority: isPriority,
          l10n: l10n,
        );
      },
    );
  }

  Widget _buildGroupSection({
    required String group,
    required List<ExerciseModel> exercises,
    required bool isOpen,
    required bool isPriority,
    required AppLocalizations l10n,
  }) {
    final label = group == _otherGroup
        ? group
        : l10n.translateMuscleGroup(group);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _toggleGroup(group),
          child: Container(
            color: isPriority
                ? AppTheme.primaryYellow.withValues(alpha: 0.08)
                : null,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: isPriority
                                    ? AppTheme.primaryYellow
                                    : null,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${exercises.length}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.lightGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.mediumGrey,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          ...exercises.map(_buildExerciseTile),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildExerciseTile(ExerciseModel exercise) {
    return ListTile(
      title: Text(exercise.name),
      subtitle: Text(
        exercise.muscleGroups.join(', '),
        style: const TextStyle(color: AppTheme.lightGrey),
      ),
      onTap: () => Navigator.of(context).pop(exercise),
    );
  }
}
