import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class YouTubePlayerWidget extends StatelessWidget {
  const YouTubePlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final controller = musicProvider.youtubeController;
        final currentVideo = musicProvider.currentVideo;

        if (controller == null || currentVideo == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.grey[600]!,
              progressColors: ProgressBarColors(
                playedColor: Colors.grey[600]!,
                handleColor: Colors.grey[400]!,
              ),
              onReady: () {
                print('YouTube player is ready');
              },
              onEnded: (YoutubeMetaData metaData) {
                print('Video ended');
                musicProvider.stop();
              },
            ),
          ),
        );
      },
    );
  }
} 