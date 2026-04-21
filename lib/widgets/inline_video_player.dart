import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Muted, looping video player for embedding inside list tiles — used in the
/// recommended-exercise tiles during an active workout. Starts playing as
/// soon as it's initialized; disposes cleanly when removed from the tree.
class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;

  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = true,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  CachedVideoPlayerPlus? _cachedPlayer;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _initialize();
    } else {
      _hasError = true;
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _cachedPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _cachedPlayer =
          CachedVideoPlayerPlus.networkUrl(Uri.parse(widget.videoUrl));
      await _cachedPlayer!.initialize();
      final controller = _cachedPlayer!.controller;
      await controller.setVolume(0);

      if (!mounted) {
        _cachedPlayer?.dispose();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: false,
        looping: false,
        allowMuting: false,
        placeholder: _thumbnail(),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryYellow,
          handleColor: AppTheme.primaryYellow,
          backgroundColor: AppTheme.darkGrey,
          bufferedColor: AppTheme.mediumGrey,
        ),
      );

      setState(() => _isInitialized = true);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Widget _thumbnail() {
    final url = widget.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(color: AppTheme.cardBackground),
        errorWidget: (context, _, __) => Container(
          color: AppTheme.cardBackground,
          child: const Center(
            child: Icon(Icons.play_circle_outline,
                size: 48, color: AppTheme.mediumGrey),
          ),
        ),
      );
    }
    return Container(
      color: AppTheme.cardBackground,
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            size: 48, color: AppTheme.mediumGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppTheme.cardBackground,
          child: Center(
            child: Text(
              AppLocalizations.of(context).unableToLoadVideo,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _thumbnail(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _cachedPlayer!.controller.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
