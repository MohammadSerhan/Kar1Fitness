import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/exercise_model.dart';
import '../theme/app_theme.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: exercise.thumbnailUrl != null &&
                        exercise.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: exercise.thumbnailUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.darkGrey,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.darkGrey,
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.darkGrey,
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppTheme.primaryYellow,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Exercise Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroups.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryYellow,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.build,
                          size: 14,
                          color: AppTheme.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exercise.equipment.join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.mediumGrey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
