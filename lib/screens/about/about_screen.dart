import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_card.dart';
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
    _allExercises = await _firestoreService.getAllExercises();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
              'Exercise Library',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
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

            // Gym Name
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
              'Your premier fitness destination for achieving your health and wellness goals. '
              'We provide state-of-the-art equipment, expert guidance, and a supportive community '
              'to help you on your fitness journey.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Contact Info
            _buildInfoRow(Icons.location_on, 'Location', 'Mjd El Kurum'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', '+972 (053) 277-6433'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'Email', 'kar1fitness@gmail.com'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Hours', 'Sun-Thu: 7AM-10:30PM, Fri-Sat: 8AM-7PM'),
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
                    ? 'No exercises available yet'
                    : 'No exercises found',
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
