import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../models/video.dart';
import '../models/downloaded_track.dart';

class FullScreenPlayer extends StatefulWidget {
  final Video? video;
  final DownloadedTrack? downloadedTrack;
  
  const FullScreenPlayer({super.key, this.video, this.downloadedTrack});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeProvider.getGradientColors(),
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                final currentVideo = musicProvider.currentVideo ?? widget.video;
                final isPlayingLocal = musicProvider.isPlayingLocalTrack;
                
                // Handle both online videos and downloaded tracks
                if (currentVideo == null && !isPlayingLocal && widget.downloadedTrack == null) {
                  return Center(
                    child: Text(
                      'No track playing',
                      style: TextStyle(
                        color: themeProvider.getTextColor(),
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Column(
                    children: [
                      // App Bar
                      _buildAppBar(context, themeProvider),
                      
                      // Album Art
                      Expanded(
                        child: _buildAlbumArt(currentVideo, musicProvider, themeProvider),
                      ),
                      
                      // Controls
                      _buildControls(context, musicProvider),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    final iconColor = themeProvider.getTextColor();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 30),
          ),
          Expanded(
            child: Text(
              'Now Playing',
              style: TextStyle(
                color: iconColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show more options
            },
            icon: Icon(Icons.more_vert, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Video? video, MusicProvider musicProvider, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          width: 320,
          height: 180, // 16:9 ratio (320/180 = 1.78)
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: themeProvider.accentColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _buildThumbnailImage(video, musicProvider, themeProvider),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(Video? video, MusicProvider musicProvider, ThemeProvider themeProvider) {
    final fallbackBgColor = themeProvider.getSurfaceColor();
    final fallbackIconColor = themeProvider.getTextColor();
    
    Widget buildFallbackContainer() {
      return Container(
        width: double.infinity,
        height: 250,
        color: fallbackBgColor,
        child: Icon(
          Icons.music_note,
          color: fallbackIconColor,
          size: 100,
        ),
      );
    }
    
    if (video != null) {
      return Image.network(
        video.thumbnail,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallbackContainer(),
      );
    } else if (musicProvider.isPlayingLocalTrack) {
      final thumbnailPath = musicProvider.currentLocalTrackThumbnail;
      if (thumbnailPath != null && !thumbnailPath.startsWith('http')) {
        return Image.file(
          io.File(thumbnailPath),
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => buildFallbackContainer(),
        );
      }
    } else if (widget.downloadedTrack != null) {
      final thumbnailPath = widget.downloadedTrack!.thumbnail;
      if (!thumbnailPath.startsWith('http')) {
        return Image.file(
          io.File(thumbnailPath),
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => buildFallbackContainer(),
        );
      }
    }
    
    return buildFallbackContainer();
  }

  Widget _buildControls(BuildContext context, MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Song Info
          _buildSongInfo(musicProvider),
          
          const SizedBox(height: 24),
          
          // Progress Bar
          _buildProgressBar(musicProvider),
          
          const SizedBox(height: 24),
          
          // Main Controls with Skip Buttons
          _buildMainControls(musicProvider),
          
          const SizedBox(height: 24),
          
          // Secondary Controls
          _buildSecondaryControls(musicProvider),
        ],
      ),
    );
  }

  Widget _buildSongInfo(MusicProvider musicProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final titleColor = themeProvider.getTextColor();
        final subtitleColor = themeProvider.getSecondaryTextColor();
        
        String title = 'Unknown Track';
        String author = 'Unknown Artist';
        
        if (musicProvider.currentVideo != null) {
          title = musicProvider.currentVideo!.title;
          author = musicProvider.currentVideo!.author;
        } else if (musicProvider.isPlayingLocalTrack) {
          title = musicProvider.currentLocalTrackTitle ?? 'Unknown Track';
          author = musicProvider.currentLocalTrackAuthor ?? 'Unknown Artist';
        } else if (widget.downloadedTrack != null) {
          title = widget.downloadedTrack!.title;
          author = widget.downloadedTrack!.author;
        }
        
        return Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              author,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(MusicProvider musicProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final timeColor = themeProvider.getSecondaryTextColor();
        final inactiveSliderColor = themeProvider.getShimmerBaseColor();
        
        final position = musicProvider.position;
        final duration = musicProvider.duration;
        
        return Column(
          children: [
            Slider(
              value: duration.inMilliseconds > 0 
                  ? position.inMilliseconds / duration.inMilliseconds 
                  : 0.0,
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                musicProvider.seekTo(newPosition);
              },
              activeColor: themeProvider.accentColor,
              inactiveColor: inactiveSliderColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(color: timeColor),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(color: timeColor),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildMainControls(MusicProvider musicProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final iconColor = themeProvider.getTextColor();
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 10 Second Back Button
            IconButton(
              onPressed: () {
                final newPosition = musicProvider.position - const Duration(seconds: 10);
                if (newPosition.inMilliseconds >= 0) {
                  musicProvider.seekTo(newPosition);
                }
              },
              icon: Icon(Icons.replay_10, color: iconColor, size: 32),
            ),
            
            // Play/Pause Button
            Container(
              decoration: BoxDecoration(
                color: themeProvider.accentColor,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                onPressed: () {
                  if (musicProvider.isPlaying) {
                    musicProvider.pause();
                  } else {
                    musicProvider.play();
                  }
                },
                icon: Icon(
                  musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            
            // 10 Second Forward Button
            IconButton(
              onPressed: () {
                final newPosition = musicProvider.position + const Duration(seconds: 10);
                if (newPosition.inMilliseconds <= musicProvider.duration.inMilliseconds) {
                  musicProvider.seekTo(newPosition);
                }
              },
              icon: Icon(Icons.forward_10, color: iconColor, size: 32),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryControls(MusicProvider musicProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final iconColor = themeProvider.getTextColor();
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Repeat Button
            Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                return IconButton(
                  onPressed: () {
                    // Toggle repeat mode
                    musicProvider.toggleRepeat();
                  },
                  icon: Icon(
                    _getRepeatIcon(musicProvider.repeatMode),
                    color: musicProvider.repeatMode != RepeatMode.none 
                        ? themeProvider.accentColor 
                        : iconColor,
                    size: 24,
                  ),
                );
              },
            ),
            
            // Download Button - Always visible
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, child) {
                final currentVideo = musicProvider.currentVideo ?? widget.video;
                if (currentVideo == null) return const SizedBox.shrink();
                
                final isDownloaded = downloadProvider.isDownloaded(currentVideo.id);
                final isDownloading = downloadProvider.isDownloading(currentVideo.id);
                
                return IconButton(
                  onPressed: isDownloading 
                      ? null 
                      : () {
                          if (isDownloaded) {
                            // Show already downloaded message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${currentVideo.title} is already downloaded'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            // Start download
                            downloadProvider.startDownload(currentVideo, context);
                          }
                        },
                  icon: Icon(
                    isDownloaded ? Icons.download_done : Icons.download,
                    color: isDownloaded ? Colors.green : iconColor,
                    size: 24,
                  ),
                );
              },
            ),
            
            // Shuffle Button
            Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                return IconButton(
                  onPressed: () {
                    // Toggle shuffle mode
                    musicProvider.toggleShuffle();
                  },
                  icon: Icon(
                    Icons.shuffle,
                    color: musicProvider.isShuffling ? themeProvider.accentColor : iconColor,
                    size: 24,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getRepeatIcon(RepeatMode repeatMode) {
    switch (repeatMode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}