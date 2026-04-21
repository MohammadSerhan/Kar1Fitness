import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/exercise_model.dart';
import '../services/workout_draft_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'inline_video_player.dart';

bool _isDurationExercise(ExerciseModel e) =>
    e.metric == ExerciseMetric.duration;

/// Inline expandable tile shown in the home-screen "Recommended Focus" card
/// during an active workout. Collapses to a compact row; when tapped,
/// expands in place to show the exercise video plus sets/reps/weight fields
/// and a Mark Done button. One tile is expanded at a time — the parent
/// owns that state via [expanded] + [onRequestExpand].
class RecommendedExerciseTile extends StatefulWidget {
  final ExerciseModel exercise;
  final ExerciseDraftEntry? entry;
  final bool expanded;
  final VoidCallback onRequestExpand;
  final VoidCallback onRequestCollapse;
  final void Function(ExerciseDraftEntry entry) onMarkDone;
  final VoidCallback onRemove;

  const RecommendedExerciseTile({
    super.key,
    required this.exercise,
    required this.entry,
    required this.expanded,
    required this.onRequestExpand,
    required this.onRequestCollapse,
    required this.onMarkDone,
    required this.onRemove,
  });

  @override
  State<RecommendedExerciseTile> createState() =>
      _RecommendedExerciseTileState();
}

class _RecommendedExerciseTileState extends State<RecommendedExerciseTile> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _durationController = TextEditingController();
    _syncControllersFromEntry();
  }

  @override
  void didUpdateWidget(covariant RecommendedExerciseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the tile expands (or the underlying entry changed), reset the
    // input fields to reflect the current draft so the user sees the
    // previously-entered values.
    if (!oldWidget.expanded && widget.expanded ||
        oldWidget.entry != widget.entry) {
      _syncControllersFromEntry();
    }
  }

  void _syncControllersFromEntry() {
    final e = widget.entry;
    _setsController.text = (e == null || e.sets == 0) ? '' : e.sets.toString();
    _repsController.text = (e == null || e.reps == 0) ? '' : e.reps.toString();
    _weightController.text =
        (e == null || e.weight == 0.0) ? '' : _formatWeight(e.weight);
    _durationController.text = (e == null || e.durationMinutes == 0)
        ? ''
        : e.durationMinutes.toString();
  }

  String _formatWeight(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toString();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleMarkDone() {
    if (_isDurationExercise(widget.exercise)) {
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;
      if (duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).fillDurationMinutes),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      widget.onMarkDone(ExerciseDraftEntry(
        exerciseId: widget.exercise.exerciseId,
        sets: 0,
        reps: 0,
        weight: 0,
        durationMinutes: duration,
      ));
      return;
    }

    final sets = int.tryParse(_setsController.text.trim()) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    if (sets <= 0 || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).fillSetsReps),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    widget.onMarkDone(ExerciseDraftEntry(
      exerciseId: widget.exercise.exerciseId,
      sets: sets,
      reps: reps,
      weight: weight,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.entry != null;
    final borderColor =
        done ? AppTheme.primaryYellow : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: done ? 1.5 : 0),
      ),
      child: Column(
        children: [
          _buildHeader(done),
          if (widget.expanded) _buildExpandedBody(done),
        ],
      ),
    );
  }

  Widget _buildHeader(bool done) {
    return InkWell(
      onTap:
          widget.expanded ? widget.onRequestCollapse : widget.onRequestExpand,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _thumbnail(),
            const SizedBox(width: 12),
            Expanded(child: _headerText(done)),
            _trailingIcon(done),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final url = widget.exercise.thumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                width: 80,
                height: 80,
                color: AppTheme.darkGrey,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, _, __) => Container(
                width: 80,
                height: 80,
                color: AppTheme.darkGrey,
                child: const Icon(Icons.fitness_center,
                    color: AppTheme.mediumGrey),
              ),
            )
          : Container(
              width: 80,
              height: 80,
              color: AppTheme.darkGrey,
              child: const Icon(Icons.fitness_center,
                  color: AppTheme.primaryYellow, size: 32),
            ),
    );
  }

  Widget _headerText(bool done) {
    final e = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.exercise.name,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (done && !widget.expanded && e != null)
          Text(
            _summary(e),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else ...[
          Text(
            widget.exercise.muscleGroups.join(', '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryYellow,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.build,
                  size: 14, color: AppTheme.mediumGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.exercise.equipment.join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _summary(ExerciseDraftEntry e) {
    if (_isDurationExercise(widget.exercise)) {
      final minLabel = AppLocalizations.of(context).minutesShort;
      return '${e.durationMinutes} $minLabel';
    }
    final weight =
        e.weight > 0 ? ' @ ${_formatWeight(e.weight)}kg' : '';
    return '${e.sets} × ${e.reps}$weight';
  }

  Widget _trailingIcon(bool done) {
    if (done) {
      return const Icon(Icons.check_circle,
          color: AppTheme.primaryYellow, size: 28);
    }
    if (widget.expanded) {
      return const Icon(Icons.expand_less,
          color: AppTheme.mediumGrey, size: 28);
    }
    return const Icon(Icons.radio_button_unchecked,
        color: AppTheme.mediumGrey, size: 28);
  }

  Widget _buildExpandedBody(bool done) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InlineVideoPlayer(
            videoUrl: widget.exercise.videoUrl,
            thumbnailUrl: widget.exercise.thumbnailUrl,
          ),
          const SizedBox(height: 12),
          if (_isDurationExercise(widget.exercise))
            _numberField(_durationController, l10n.durationMinutes)
          else
            Row(
              children: [
                Expanded(child: _numberField(_setsController, l10n.sets)),
                const SizedBox(width: 8),
                Expanded(child: _numberField(_repsController, l10n.reps)),
                const SizedBox(width: 8),
                Expanded(
                    child: _numberField(_weightController, l10n.weightKg,
                        allowDecimal: true)),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleMarkDone,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.markDone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.darkBackground,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              if (done) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.remove),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController c, String label,
      {bool allowDecimal = false}) {
    return TextField(
      controller: c,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
