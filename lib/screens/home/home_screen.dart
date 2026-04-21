import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/health_service.dart';
import '../../services/workout_draft_service.dart';
import '../../services/workout_recommendation_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/exercise_selection_dialog.dart';
import '../../widgets/recommended_exercise_tile.dart';
import '../../widgets/date_timeline_selector.dart';
import '../../widgets/health_data_card.dart';
import '../exercise/exercise_detail_screen.dart';
import '../workout/workout_recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WorkoutRecommendationService _recommendationService =
      WorkoutRecommendationService();
  final WorkoutDraftService _draftService = WorkoutDraftService();
  DateTime _selectedDate = DateTime.now();

  // Recommended-exercise plan is memoized per user so repeated rebuilds
  // (e.g. from toggling a tick) don't re-run the query.
  Future<Map<String, dynamic>>? _planFuture;
  String? _planUserId;

  // Firestore streams are memoized so setState rebuilds don't reconstruct
  // them — otherwise StreamBuilder resubscribes, briefly shows its waiting
  // state, and the UI flashes when the user ticks an exercise.
  Stream<UserModel?>? _userStream;
  String? _userStreamUid;
  Stream<WorkoutModel?>? _workoutStream;
  String? _workoutStreamUid;
  DateTime? _workoutStreamDate;

  // Ticked exercises for the current date, keyed by exerciseId, per phase.
  // `_draftEntries` is the main workout; `_warmupDraft` / `_cooldownDraft`
  // are the warm-up and optional cool-down. Loaded from SharedPreferences.
  Map<String, ExerciseDraftEntry> _draftEntries = {};
  Map<String, ExerciseDraftEntry> _warmupDraft = {};
  Map<String, ExerciseDraftEntry> _cooldownDraft = {};
  DateTime? _draftStartedAt;

  // At most one recommended tile is expanded at a time; its exerciseId lives
  // here so the parent can collapse whichever tile was previously open.
  String? _expandedExerciseId;

  // Exercises the user added on top of the recommended plan during this
  // session. Held in memory only: if an entry in the draft has an id that
  // isn't in the recommended plan, it's reconciled back into this list on
  // load so customs ticked before an app kill keep showing up. Customs that
  // were added but never marked done are lost on kill (intentional).
  final List<ExerciseModel> _customExercises = [];

  // Warm-up and cool-down exercise catalogs from Firestore. Memoized — these
  // are small lists and don't change between reloads of this screen.
  Future<List<ExerciseModel>>? _warmupLibraryFuture;
  Future<List<ExerciseModel>>? _cooldownLibraryFuture;

  bool _isSavingWorkout = false;
  bool _isPickingExercise = false;

  // Warm-up and cool-down sections collapse by default to keep the home
  // screen short. The main recommended focus starts expanded — it's the
  // primary action — but users can collapse it too. Tapping the header toggles.
  bool _warmupCardExpanded = false;
  bool _cooldownCardExpanded = false;
  bool _mainCardExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final date = _selectedDate;
    final main =
        await _draftService.getEntries(date, WorkoutPhase.main);
    final warmup =
        await _draftService.getEntries(date, WorkoutPhase.warmup);
    final cooldown =
        await _draftService.getEntries(date, WorkoutPhase.cooldown);
    final startedAt = await _draftService.getStartedAt(date);
    if (!mounted || !_isSameDay(_selectedDate, date)) return;
    setState(() {
      _draftEntries = main;
      _warmupDraft = warmup;
      _cooldownDraft = cooldown;
      _draftStartedAt = startedAt;
      _customExercises.clear();
    });
    // Fetch exercise models for any draft entries that aren't part of the
    // recommended plan — these were custom-added in a prior session.
    unawaited(_reconcileCustomExercises());
  }

  /// Any draft entry whose id isn't in the current recommended plan is a
  /// custom exercise from a previous session — fetch its model so it renders
  /// as an inline tile like the recommended ones.
  Future<void> _reconcileCustomExercises() async {
    final userId = _planUserId;
    final planFuture = _planFuture;
    if (userId == null || planFuture == null) return;

    late final Map<String, dynamic> plan;
    try {
      plan = await planFuture;
    } catch (_) {
      return;
    }
    if (!mounted) return;

    final recommendedIds = (plan['exercises'] as List<ExerciseModel>? ?? const [])
        .map((e) => e.exerciseId)
        .toSet();
    final knownCustomIds =
        _customExercises.map((e) => e.exerciseId).toSet();
    final missingIds = _draftEntries.keys
        .where((id) =>
            !recommendedIds.contains(id) && !knownCustomIds.contains(id))
        .toList();

    for (final id in missingIds) {
      final model = await _firestoreService.getExercise(id);
      if (!mounted) return;
      if (model == null) continue;
      setState(() {
        if (!_customExercises.any((e) => e.exerciseId == model.exerciseId)) {
          _customExercises.add(model);
        }
      });
    }
  }

  Future<void> _addCustomExercise() async {
    if (_isPickingExercise) return;
    setState(() => _isPickingExercise = true);
    try {
      final exercises = await _firestoreService.getAllExercises();
      if (!mounted) return;

      final plan = _planFuture == null ? null : await _planFuture;
      if (!mounted) return;

      final recommendedIds =
          (plan?['exercises'] as List<ExerciseModel>? ?? const [])
              .map((e) => e.exerciseId)
              .toSet();
      final customIds = _customExercises.map((e) => e.exerciseId).toSet();
      // Don't offer exercises that are already on-screen, and limit the main
      // picker to main exercises only — warm-ups / cool-downs live in their
      // own sections.
      final candidates = exercises
          .where((e) =>
              e.type == ExerciseType.main &&
              !recommendedIds.contains(e.exerciseId) &&
              !customIds.contains(e.exerciseId))
          .toList();

      final selected = await showDialog<ExerciseModel>(
        context: context,
        builder: (context) => ExerciseSelectionDialog(exercises: candidates),
      );
      if (!mounted || selected == null) return;

      setState(() {
        _customExercises.add(selected);
        _expandedExerciseId = selected.exerciseId;
      });
    } finally {
      if (mounted) setState(() => _isPickingExercise = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<Map<String, dynamic>> _ensurePlanFuture(String userId) {
    if (_planFuture == null || _planUserId != userId) {
      _planUserId = userId;
      _planFuture = _recommendationService.getNextExercisePlan(userId);
      // After the plan resolves, reconcile any draft entries that aren't
      // part of it — those are customs from a previous session that need
      // tiles. Safe to chain here; completes silently on error.
      _planFuture!.then((_) {
        if (mounted) _reconcileCustomExercises();
      }).catchError((_) {});
    }
    return _planFuture!;
  }

  Future<List<ExerciseModel>> _ensureWarmupLibrary() {
    _warmupLibraryFuture ??=
        _firestoreService.getExercisesByType(ExerciseType.warmup);
    return _warmupLibraryFuture!;
  }

  Future<List<ExerciseModel>> _ensureCooldownLibrary() {
    _cooldownLibraryFuture ??=
        _firestoreService.getExercisesByType(ExerciseType.cooldown);
    return _cooldownLibraryFuture!;
  }

  /// Caches the user stream so rebuilds don't resubscribe. StreamBuilder
  /// would otherwise flash its waiting state and the screen would flicker.
  Stream<UserModel?> _ensureUserStream(String userId) {
    if (_userStream == null || _userStreamUid != userId) {
      _userStreamUid = userId;
      _userStream = _firestoreService.getUserStream(userId);
    }
    return _userStream!;
  }

  Stream<WorkoutModel?> _ensureWorkoutStream(String userId, DateTime date) {
    if (_workoutStream == null ||
        _workoutStreamUid != userId ||
        _workoutStreamDate == null ||
        !_isSameDay(_workoutStreamDate!, date)) {
      _workoutStreamUid = userId;
      _workoutStreamDate = date;
      _workoutStream =
          _firestoreService.getUserWorkoutForDateStream(userId, date);
    }
    return _workoutStream!;
  }

  Future<void> _handleRequestExpand(String exerciseId) async {
    setState(() => _expandedExerciseId = exerciseId);
    // The workout duration starts here — the moment the user first opens a
    // tile. Counting from first mark-done misses the time spent watching
    // the video and actually doing the exercise before ticking it off.
    if (_draftStartedAt == null) {
      final now = DateTime.now();
      if (mounted) setState(() => _draftStartedAt = now);
      await _draftService.setStartedAt(_selectedDate, now);
    }
  }

  void _handleRequestCollapse() {
    setState(() => _expandedExerciseId = null);
  }

  Map<String, ExerciseDraftEntry> _draftForPhase(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.warmup:
        return _warmupDraft;
      case WorkoutPhase.cooldown:
        return _cooldownDraft;
      case WorkoutPhase.main:
        return _draftEntries;
    }
  }

  void _assignDraftForPhase(
      WorkoutPhase phase, Map<String, ExerciseDraftEntry> next) {
    switch (phase) {
      case WorkoutPhase.warmup:
        _warmupDraft = next;
        break;
      case WorkoutPhase.cooldown:
        _cooldownDraft = next;
        break;
      case WorkoutPhase.main:
        _draftEntries = next;
        break;
    }
  }

  Future<void> _handleMarkDone(
      WorkoutPhase phase, ExerciseDraftEntry entry) async {
    final next =
        Map<String, ExerciseDraftEntry>.from(_draftForPhase(phase));
    next[entry.exerciseId] = entry;
    setState(() {
      _assignDraftForPhase(phase, next);
      _expandedExerciseId = null;
    });
    await _draftService.setEntries(_selectedDate, phase, next);
  }

  Future<void> _handleRemoveEntry(
      WorkoutPhase phase, String exerciseId) async {
    final next =
        Map<String, ExerciseDraftEntry>.from(_draftForPhase(phase));
    next.remove(exerciseId);
    setState(() {
      _assignDraftForPhase(phase, next);
      _expandedExerciseId = null;
      // If it was a custom-added main exercise, remove the tile too —
      // otherwise the card would hang around empty. Warm-up / cool-down
      // don't support customs, so skip.
      if (phase == WorkoutPhase.main) {
        _customExercises
            .removeWhere((e) => e.exerciseId == exerciseId);
      }
    });
    await _draftService.setEntries(_selectedDate, phase, next);
  }

  Future<void> _saveWorkoutFromDraft() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null || userId.isEmpty) return;
    if (_draftEntries.isEmpty || _isSavingWorkout) return;

    // Soft enforcement: nudge, don't block. If the user somehow logged main
    // exercises without any warm-up, ask to confirm — they can still finish.
    if (_warmupDraft.isEmpty) {
      final proceed = await _confirmSkipWarmup();
      if (proceed != true) return;
    }

    setState(() => _isSavingWorkout = true);

    final startedAt = _draftStartedAt ?? DateTime.now();
    final durationMinutes =
        DateTime.now().difference(startedAt).inMinutes.clamp(0, 24 * 60);

    ExerciseCompleted toCompleted(ExerciseDraftEntry e) => ExerciseCompleted(
          exerciseId: e.exerciseId,
          sets: e.sets,
          reps: e.reps,
          weight: e.weight,
          durationMinutes: e.durationMinutes,
        );

    final workout = WorkoutModel(
      workoutId: '',
      userId: userId,
      date: _selectedDate,
      durationMinutes: durationMinutes,
      exercisesCompleted:
          _draftEntries.values.map(toCompleted).toList(),
      warmupCompleted: _warmupDraft.values.map(toCompleted).toList(),
      cooldownCompleted:
          _cooldownDraft.values.map(toCompleted).toList(),
    );

    try {
      await _firestoreService.deleteUserWorkoutsForDate(
          userId, _selectedDate);
      await _firestoreService.addWorkout(workout);
      await _draftService.clear(_selectedDate);
      if (!mounted) return;
      setState(() {
        _draftEntries = {};
        _warmupDraft = {};
        _cooldownDraft = {};
        _draftStartedAt = null;
        _expandedExerciseId = null;
        _isSavingWorkout = false;
        _customExercises.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workoutSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingWorkout = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _confirmSkipWarmup() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noWarmupTitle),
        content: Text(l10n.noWarmupMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: AppTheme.darkBackground,
            ),
            child: Text(l10n.continueAnyway),
          ),
        ],
      ),
    );
  }

  Future<void> _pushRecording(List<ExerciseModel>? preloaded) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutRecordingScreen(
          selectedDate: _selectedDate,
          preloadedExercises: preloaded,
        ),
      ),
    );
    // On return, draft may have been cleared by a successful save.
    _loadDraft();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _ensureUserStream(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data;
            if (user == null) {
              return Center(
                  child: Text(AppLocalizations.of(context).userNotFound));
            }

            // Ensure plan future is created before any builder below uses it.
            _ensurePlanFuture(userId);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(user),
                    const SizedBox(height: 16),

                    // Date Timeline Selector
                    DateTimelineSelector(
                      initialDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                        _loadDraft();
                      },
                      daysToShow: 30,
                    ),
                    const SizedBox(height: 20),

                    // Content changes based on selected date
                    ..._buildContentForDate(userId),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).welcomeBackComma,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          user.name,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryYellow,
              ),
        ),
      ],
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _hasAnyDraftActivity =>
      _draftEntries.isNotEmpty ||
      _warmupDraft.isNotEmpty ||
      _cooldownDraft.isNotEmpty ||
      _customExercises.isNotEmpty;

  /// Builds different content depending on whether today or a past date is selected.
  List<Widget> _buildContentForDate(String userId) {
    if (_isToday) {
      return [
        // 1. Warm-up (required, soft-gated — user can still skip at save)
        _buildPhaseSection(userId, WorkoutPhase.warmup),
        const SizedBox(height: 20),

        // 2. Recommended Focus (main workout)
        _buildRecommendedFocus(userId),
        const SizedBox(height: 20),

        // 3. Cool-down (optional)
        _buildPhaseSection(userId, WorkoutPhase.cooldown),
        const SizedBox(height: 20),

        // 4. Today's Activity (Health Data)
        const HealthDataCard(),
        const SizedBox(height: 20),

        // Show today's completed workout if one exists
        _buildTodayWorkoutIfExists(userId),

        // 5. Log Workout
        _buildLogWorkoutButton(userId),
      ];
    }

    // Past date — show workout for that date + past health data
    return [
      _buildPastDateWorkout(userId),
      const SizedBox(height: 20),
      _buildPastDateHealthData(),
    ];
  }

  /// Shows today's completed workout only if one was already recorded — and
  /// only if the user isn't actively ticking a new draft, since finishing the
  /// draft will replace whatever is currently logged for today.
  ///
  /// The draft-state check lives *inside* the builder rather than gating the
  /// StreamBuilder itself — otherwise the subscription unmounts during an
  /// active session and we miss the Firestore emission that fires when the
  /// save completes (broadcast streams don't replay to new subscribers).
  Widget _buildTodayWorkoutIfExists(String userId) {
    return StreamBuilder<WorkoutModel?>(
      stream: _ensureWorkoutStream(userId, _selectedDate),
      builder: (context, snapshot) {
        if (_hasAnyDraftActivity) return const SizedBox.shrink();
        final workout = snapshot.data;
        if (workout == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildWorkoutCard(workout),
        );
      },
    );
  }

  /// Shows the workout recorded on a past date, or a "no workout" message.
  Widget _buildPastDateWorkout(String userId) {
    return StreamBuilder<WorkoutModel?>(
      stream: _ensureWorkoutStream(userId, _selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workout = snapshot.data;

        if (workout != null) {
          return _buildWorkoutCard(workout);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppTheme.mediumGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).noWorkoutOnThisDay,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows health data for a past date, or a "not available" message.
  Widget _buildPastDateHealthData() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getHealthDataForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data;
        final hasData = data != null &&
            (((data['steps'] as int?) ?? 0) > 0 ||
            ((data['calories'] as int?) ?? 0) > 0);

        if (!hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    size: 48,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).noHealthData,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, y').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).activity,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.directions_walk,
                        label: AppLocalizations.of(context).steps,
                        value: data!['steps']?.toString() ?? '0',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.local_fire_department,
                        label: AppLocalizations.of(context).calories,
                        value: data['calories']?.toString() ?? '0',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.route,
                        label: AppLocalizations.of(context).distanceKm,
                        value: data['distance_km']?.toString() ?? '0.0',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHealthMetric(
                        icon: Icons.timer,
                        label: AppLocalizations.of(context).activeMin,
                        value: data['active_minutes']?.toString() ?? '0',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getHealthDataForDate(DateTime date) async {
    try {
      final healthService = HealthService();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final data = await healthService.getHealthDataForDate(startOfDay, endOfDay);
      return data;
    } catch (e) {
      return null;
    }
  }

  Widget _buildRecommendedFocus(String userId) {
    // Today: hide the whole card if a workout is already logged and the
    // user has nothing in progress (one training per day rule).
    if (_isToday) {
      return StreamBuilder<WorkoutModel?>(
        stream: _ensureWorkoutStream(userId, _selectedDate),
        builder: (context, snapshot) {
          final hasWorkout = snapshot.data != null;
          if (hasWorkout && !_hasAnyDraftActivity) {
            return const SizedBox.shrink();
          }
          return _buildRecommendedFocusCard(userId);
        },
      );
    }
    return _buildRecommendedFocusCard(userId);
  }

  /// Warm-up or cool-down card. Only rendered for today. Same visibility rule
  /// as the main recommended card: hide once a workout exists for the day and
  /// there's no active draft.
  Widget _buildPhaseSection(String userId, WorkoutPhase phase) {
    assert(phase != WorkoutPhase.main);
    return StreamBuilder<WorkoutModel?>(
      stream: _ensureWorkoutStream(userId, _selectedDate),
      builder: (context, snapshot) {
        final hasWorkout = snapshot.data != null;
        if (hasWorkout && !_hasAnyDraftActivity) {
          return const SizedBox.shrink();
        }
        return _buildPhaseSectionCard(phase);
      },
    );
  }

  Widget _buildPhaseSectionCard(WorkoutPhase phase) {
    final libraryFuture = phase == WorkoutPhase.warmup
        ? _ensureWarmupLibrary()
        : _ensureCooldownLibrary();
    return FutureBuilder<List<ExerciseModel>>(
      future: libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final library = snapshot.data ?? const <ExerciseModel>[];
        return _buildPhaseCardBody(phase, library);
      },
    );
  }

  Widget _buildPhaseCardBody(
      WorkoutPhase phase, List<ExerciseModel> library) {
    final l10n = AppLocalizations.of(context);
    final isWarmup = phase == WorkoutPhase.warmup;
    final title = isWarmup ? l10n.warmup : l10n.cooldown;
    final notice = isWarmup ? l10n.warmupNotice : l10n.cooldownNotice;
    final badge = isWarmup ? l10n.required : l10n.optional;
    final icon = isWarmup ? Icons.whatshot : Icons.self_improvement;
    final badgeColor =
        isWarmup ? AppTheme.primaryYellow : AppTheme.lightGrey;
    final draft = _draftForPhase(phase);
    final expanded =
        isWarmup ? _warmupCardExpanded : _cooldownCardExpanded;
    final doneCount = draft.length;

    return Card(
      color: AppTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isWarmup) {
                _warmupCardExpanded = !_warmupCardExpanded;
              } else {
                _cooldownCardExpanded = !_cooldownCardExpanded;
              }
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.primaryYellow),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      badge,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const Spacer(),
                  if (doneCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$doneCount ✓',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.mediumGrey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppTheme.mediumGrey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...library.map((exercise) => RecommendedExerciseTile(
                        key: ValueKey(
                            '${_phaseKeyPrefix(phase)}-lib-${exercise.exerciseId}'),
                        exercise: exercise,
                        entry: draft[exercise.exerciseId],
                        expanded:
                            _expandedExerciseId == exercise.exerciseId,
                        onRequestExpand: () =>
                            _handleRequestExpand(exercise.exerciseId),
                        onRequestCollapse: _handleRequestCollapse,
                        onMarkDone: (entry) =>
                            _handleMarkDone(phase, entry),
                        onRemove: () => _handleRemoveEntry(
                            phase, exercise.exerciseId),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _phaseKeyPrefix(WorkoutPhase phase) {
    switch (phase) {
      case WorkoutPhase.warmup:
        return 'warmup';
      case WorkoutPhase.cooldown:
        return 'cooldown';
      case WorkoutPhase.main:
        return 'main';
    }
  }

  Widget _buildRecommendedFocusCard(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ensurePlanFuture(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final plan = snapshot.data!;
        final targetMuscleGroup = plan['targetMuscleGroup'] as String;
        final exercises = plan['exercises'] as List<ExerciseModel>;

        if (exercises.isEmpty && _customExercises.isEmpty) {
          return const SizedBox.shrink();
        }

        final doneCount = _isToday ? _draftEntries.length : 0;
        final l10n = AppLocalizations.of(context);

        return Card(
          color: AppTheme.cardBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(
                    () => _mainCardExpanded = !_mainCardExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppTheme.primaryYellow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.recommendedFocus,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (doneCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '$doneCount ✓',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      Icon(
                        _mainCardExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppTheme.mediumGrey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_mainCardExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppTheme.primaryYellow),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fitness_center,
                                color: AppTheme.primaryYellow),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.translateMuscleGroup(
                                        targetMuscleGroup),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryYellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    l10n.basedOnRecentWorkouts,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isToday)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.markExercisesHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      // Today: inline expandable tiles capture sets/reps/weight
                      // with a playable video. Past dates: plain link cards.
                      ...exercises.map((exercise) => _isToday
                          ? RecommendedExerciseTile(
                              key:
                                  ValueKey('rec-${exercise.exerciseId}'),
                              exercise: exercise,
                              entry: _draftEntries[exercise.exerciseId],
                              expanded: _expandedExerciseId ==
                                  exercise.exerciseId,
                              onRequestExpand: () =>
                                  _handleRequestExpand(
                                      exercise.exerciseId),
                              onRequestCollapse: _handleRequestCollapse,
                              onMarkDone: (entry) => _handleMarkDone(
                                  WorkoutPhase.main, entry),
                              onRemove: () => _handleRemoveEntry(
                                  WorkoutPhase.main,
                                  exercise.exerciseId),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ExerciseCard(
                                exercise: exercise,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExerciseDetailScreen(
                                              exercise: exercise),
                                    ),
                                  );
                                },
                              ),
                            )),
                      // Custom exercises the user added on top of the
                      // recommended plan — same tile widget, keyed
                      // separately so Flutter doesn't confuse them with
                      // reordered recommended items.
                      if (_isToday)
                        ..._customExercises.map((exercise) =>
                            RecommendedExerciseTile(
                              key: ValueKey(
                                  'custom-${exercise.exerciseId}'),
                              exercise: exercise,
                              entry: _draftEntries[exercise.exerciseId],
                              expanded: _expandedExerciseId ==
                                  exercise.exerciseId,
                              onRequestExpand: () =>
                                  _handleRequestExpand(
                                      exercise.exerciseId),
                              onRequestCollapse: _handleRequestCollapse,
                              onMarkDone: (entry) => _handleMarkDone(
                                  WorkoutPhase.main, entry),
                              onRemove: () => _handleRemoveEntry(
                                  WorkoutPhase.main,
                                  exercise.exerciseId),
                            )),
                      if (_isToday) ...[
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: _isPickingExercise
                              ? null
                              : _addCustomExercise,
                          icon: _isPickingExercise
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: Text(l10n.addExercise),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryYellow,
                            side: const BorderSide(
                                color: AppTheme.primaryYellow),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogWorkoutButton(String userId) {
    // Hide the button when a workout already exists for today and the user
    // hasn't started a new draft — one training per day.
    return StreamBuilder<WorkoutModel?>(
      stream: _ensureWorkoutStream(userId, _selectedDate),
      builder: (context, workoutSnap) {
        final hasWorkout = workoutSnap.data != null;
        if (hasWorkout && !_hasAnyDraftActivity) {
          return const SizedBox.shrink();
        }
        return _buildLogWorkoutButtonInner(userId);
      },
    );
  }

  Widget _buildLogWorkoutButtonInner(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ensurePlanFuture(userId),
      builder: (context, snapshot) {
        final plan = snapshot.data;
        final hasDraft = _draftEntries.isNotEmpty;
        final l10n = AppLocalizations.of(context);

        return ElevatedButton.icon(
          onPressed: _isSavingWorkout
              ? null
              : () {
                  if (hasDraft) {
                    _saveWorkoutFromDraft();
                  } else {
                    _showLogWorkoutOptions(plan);
                  }
                },
          icon: _isSavingWorkout
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.darkBackground),
                )
              : Icon(hasDraft ? Icons.check : Icons.add),
          label: Text(
            hasDraft
                ? '${l10n.finishWorkout} (${_draftEntries.length})'
                : l10n.logWorkout,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryYellow,
            foregroundColor: AppTheme.darkBackground,
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showLogWorkoutOptions(Map<String, dynamic>? plan) {
    final exercises =
        plan != null ? plan['exercises'] as List<ExerciseModel> : <ExerciseModel>[];
    final targetGroup =
        plan != null ? plan['targetMuscleGroup'] as String : 'Full Body';
    final l10n = AppLocalizations.of(context);
    final translatedGroup = l10n.translateMuscleGroup(targetGroup);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 20),
                Text(
                  l10n.startWorkout,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                // Option 1: Recommended workout
                if (exercises.isNotEmpty)
                  _buildWorkoutOption(
                    icon: Icons.lightbulb,
                    title: '${l10n.recommendedPrefix}: $translatedGroup',
                    subtitle:
                        '${exercises.length} ${l10n.exercisesCount}',
                    onTap: () {
                      Navigator.of(context).pop();
                      _pushRecording(exercises);
                    },
                  ),

                if (exercises.isNotEmpty) const SizedBox(height: 12),

                // Option 2: Manual / custom workout
                _buildWorkoutOption(
                  icon: Icons.edit_note,
                  title: l10n.customWorkout,
                  subtitle: l10n.pickYourOwnExercises,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pushRecording(null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mediumGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryYellow),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.lightGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.primaryYellow),
                    const SizedBox(width: 8),
                    Text(
                      l10n.workoutCompleted,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Text(
                  '${workout.durationMinutes} ${l10n.minutesShort}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryYellow,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (workout.warmupCompleted.isNotEmpty) ...[
              _buildPhaseHeader(l10n.warmup, Icons.whatshot),
              ...workout.warmupCompleted
                  .map((e) => _buildExerciseCompletedItem(e)),
              const SizedBox(height: 12),
            ],
            Text(
              '${workout.exercisesCompleted.length} ${l10n.exercisesCompleted}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            ...workout.exercisesCompleted
                .map((exercise) => _buildExerciseCompletedItem(exercise)),
            if (workout.cooldownCompleted.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPhaseHeader(l10n.cooldown, Icons.self_improvement),
              ...workout.cooldownCompleted
                  .map((e) => _buildExerciseCompletedItem(e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryYellow, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryYellow,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCompletedItem(ExerciseCompleted exercise) {
    return FutureBuilder<ExerciseModel?>(
      future: _firestoreService.getExercise(exercise.exerciseId),
      builder: (context, snapshot) {
        final exerciseName = snapshot.data?.name ?? 'Exercise';
        final l10n = AppLocalizations.of(context);
        // Cardio warm-ups / cool-downs log a duration; the rest log sets × reps @ weight.
        final trailing = exercise.durationMinutes > 0
            ? '${exercise.durationMinutes} ${l10n.minutesShort}'
            : '${exercise.sets} x ${exercise.reps} @ ${exercise.weight}kg';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  size: 8, color: AppTheme.primaryYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                trailing,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightGrey,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
