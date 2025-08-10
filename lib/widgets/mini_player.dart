import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/full_screen_player.dart';
import '../models/video.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final currentVideo = musicProvider.currentVideo;
        final isPlaying = musicProvider.isPlaying;
        final position = musicProvider.position;
        final duration = musicProvider.duration;
        final isPlayingLocalTrack = musicProvider.isPlayingLocalTrack;

        // Show player if there's a current video OR a local track playing
        if (currentVideo == null && !isPlayingLocalTrack) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            if (currentVideo != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FullScreenPlayer(video: currentVideo),
                ),
              );
            } else if (isPlayingLocalTrack) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FullScreenPlayer(),
                ),
              );
            }
          },
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                height: 80,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: duration.inMilliseconds > 0 
                      ? position.inMilliseconds / duration.inMilliseconds 
                      : 0.0,
                  backgroundColor: context.watch<ThemeProvider>().getShimmerBaseColor(),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 2,
                ),
                
                // Player controls
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Thumbnail with proper aspect ratio handling
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 80,
                            height: 45,
                            child: _buildThumbnailImage(context, currentVideo, musicProvider),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Video info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentVideo?.title ?? musicProvider.currentLocalTrackTitle ?? 'Unknown Track',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentVideo?.author ?? musicProvider.currentLocalTrackAuthor ?? 'Unknown Artist',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Control buttons
                        Row(
                          children: [
                            // Previous button
                            IconButton(
                              onPressed: () {
                                // TODO: Implement previous track
                              },
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            
                            // Play/Pause button
                            IconButton(
                              onPressed: () {
                                if (isPlaying) {
                                  musicProvider.pause();
                                } else {
                                  musicProvider.play();
                                }
                              },
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            
                            // Next button
                            IconButton(
                              onPressed: () {
                                // TODO: Implement next track
                              },
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
            },
          ),
        );
      },
    );
  }

  Widget _buildThumbnailImage(BuildContext context, Video? currentVideo, MusicProvider musicProvider) {
    if (currentVideo != null) {
      return Image.network(
        currentVideo.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: context.watch<ThemeProvider>().getShimmerBaseColor(),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      );
    } else if (musicProvider.currentLocalTrackThumbnail != null) {
      final thumbnailPath = musicProvider.currentLocalTrackThumbnail!;
      if (!thumbnailPath.startsWith('http')) {
        return Image.file(
          File(thumbnailPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: context.watch<ThemeProvider>().getShimmerBaseColor(),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            );
          },
        );
      }
    }
    
    return Container(
      color: context.watch<ThemeProvider>().getShimmerBaseColor(),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 24,
      ),
    );
  }
} 