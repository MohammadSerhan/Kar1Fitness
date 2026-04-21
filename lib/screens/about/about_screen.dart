import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_card.dart';
import '../../l10n/app_localizations.dart';
import '../exercise/exercise_detail_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseModel> _allExercises = [];
  List<ExerciseModel> _filteredExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    final all = await _firestoreService.getAllExercises();
    // The library surfaces main exercises only — warm-ups and cool-downs
    // are used by the active-workout flow and would be noise here.
    _allExercises =
        all.where((e) => e.type == ExerciseType.main).toList();
    _filteredExercises = _allExercises;
    setState(() => _isLoading = false);
  }

  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        _filteredExercises = _allExercises
            .where((exercise) =>
                exercise.name.toLowerCase().contains(query.toLowerCase()) ||
                exercise.muscleGroups
                    .any((group) => group.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.about),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gym Information
            _buildGymInfo(),
            const SizedBox(height: 24),

            // Exercise Library Section
            Text(
              l10n.exerciseLibrary,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchExercises,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterExercises('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterExercises,
            ),
            const SizedBox(height: 16),

            // Exercise List
            _buildExerciseList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGymInfo() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 16),

            // Gym Name (brand — keep as-is in all languages)
            Text(
              'KAR1 FITNESS',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryYellow,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              l10n.gymDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Contact Info
            _buildInfoRow(
                Icons.location_on, l10n.location, l10n.locationValue),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, l10n.phone, '+972 (053) 277-6433'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, l10n.email, 'kar1fitness@gmail.com'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, l10n.hours, l10n.hoursValue),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryYellow, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.mediumGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? AppLocalizations.of(context).noExercisesYet
                    : AppLocalizations.of(context).noExercisesFound,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        return ExerciseCard(
          exercise: exercise,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            );
          },
        );
      },
    );
  }
}
