import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../services/health_service.dart';
import '../theme/app_theme.dart';

class HealthDataCard extends StatefulWidget {
  const HealthDataCard({super.key});

  @override
  State<HealthDataCard> createState() => _HealthDataCardState();
}

class _HealthDataCardState extends State<HealthDataCard>
    with WidgetsBindingObserver {
  final HealthService _healthService = HealthService();
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _waitingForPermission = false;
  Map<String, dynamic> _healthData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHealthData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state: $state, waitingForPermission: $_waitingForPermission');
    // When the app resumes after Health Connect closes, re-check permissions
    if (state == AppLifecycleState.resumed && _waitingForPermission) {
      _waitingForPermission = false;
      _loadHealthData();
    }
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);

    try {
      final hasPermission = await _healthService.isHealthDataAvailable();

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _healthService.getTodayHealthData();

      if (mounted) {
        setState(() {
          _healthData = data;
          _hasPermission = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health data: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    // Mark that we're waiting so didChangeAppLifecycleState re-checks on resume
    _waitingForPermission = true;

    // This opens Health Connect — don't rely on its return value
    await _healthService.requestAuthorization();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading health data...'),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 48,
                color: AppTheme.primaryYellow,
              ),
              const SizedBox(height: 8),
              Text(
                'Health Data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect your wearable device to track steps, calories, and more!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Grant Permission'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHealthData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: _healthData['steps']?.toString() ?? '0',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthMetric(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: _healthData['calories']?.toString() ?? '0',
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
                    label: 'Distance (km)',
                    value: _healthData['distance_km']?.toString() ?? '0.0',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHealthMetric(
                    icon: Icons.timer,
                    label: 'Active Min',
                    value: _healthData['active_minutes']?.toString() ?? '0',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
}
