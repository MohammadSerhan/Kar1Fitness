import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/exercise_model.dart';
import '../../theme/app_theme.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  CachedVideoPlayerPlus? _cachedPlayer;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.videoUrl.isNotEmpty) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _cachedPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _cachedPlayer = CachedVideoPlayerPlus.networkUrl(
        Uri.parse(widget.exercise.videoUrl),
      );

      await _cachedPlayer!.initialize();

      final controller = _cachedPlayer!.controller;
      await controller.setVolume(0);

      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: false,
        looping: true,
        allowMuting: false,
        placeholder: _buildThumbnailPlaceholder(),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryYellow,
          handleColor: AppTheme.primaryYellow,
          backgroundColor: AppTheme.darkGrey,
          bufferedColor: AppTheme.mediumGrey,
        ),
      );

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      setState(() {
        _videoError = 'Unable to load video';
      });
    }
  }

  Widget _buildThumbnailPlaceholder() {
    final thumbnailUrl = widget.exercise.thumbnailUrl;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.cardBackground,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.cardBackground,
          child: const Center(
            child: Icon(Icons.play_circle_outline,
                size: 64, color: AppTheme.mediumGrey),
          ),
        ),
      );
    }
    return Container(
      color: AppTheme.cardBackground,
      child: const Center(
        child:
            Icon(Icons.play_circle_outline, size: 64, color: AppTheme.mediumGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            _buildVideoPlayer(),

            // Exercise Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  Text(
                    widget.exercise.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),

                  // Muscle Groups
                  _buildInfoSection(
                    'Target Muscles',
                    Icons.fitness_center,
                    widget.exercise.muscleGroups,
                  ),
                  const SizedBox(height: 16),

                  // Equipment
                  _buildInfoSection(
                    'Equipment',
                    Icons.build,
                    widget.exercise.equipment,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildDescriptionSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoError != null) {
      return Container(
        height: 250,
        color: AppTheme.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.mediumGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _videoError!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized) {
      return Container(
        height: 250,
        color: AppTheme.cardBackground,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _cachedPlayer!.controller.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryYellow),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => _buildChip(item)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.primaryYellow),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryYellow,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryYellow),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.exercise.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
