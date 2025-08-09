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
  bool _isShuffle = false;
  bool _isRepeat = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeProvider.primaryColor.withOpacity(0.8),
                  themeProvider.primaryColor.withOpacity(0.6),
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                ],
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Column(
                    children: [
                      // App Bar
                      _buildAppBar(context),
                      
                      // Album Art
                      Expanded(
                        child: _buildAlbumArt(currentVideo, musicProvider),
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

  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    
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

  Widget _buildAlbumArt(Video? video, MusicProvider musicProvider) {
    // Determine aspect ratio based on content type
    final double aspectRatio = _getAspectRatio(video, musicProvider);
    
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.watch<ThemeProvider>().accentColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildThumbnailImage(video, musicProvider),
        ),
      ),
    );
  }

  double _getAspectRatio(Video? video, MusicProvider musicProvider) {
    // If it's a video, use 16:9 aspect ratio
    if (video != null) {
      return 16.0 / 9.0;
    }
    
    // If it's a local track or downloaded track, use 1:1 aspect ratio for music
    if (musicProvider.isPlayingLocalTrack || widget.downloadedTrack != null) {
      return 16.0 / 9.0;
    }
    
    // Default to 1:1 for music thumbnails
    return 1.0;
  }

  Widget _buildThumbnailImage(Video? video, MusicProvider musicProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBgColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final fallbackIconColor = isDark ? Colors.white : Colors.black;
    
    Widget buildFallbackContainer() {
      return Container(
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
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => buildFallbackContainer(),
      );
    } else if (musicProvider.isPlayingLocalTrack) {
      final thumbnailPath = musicProvider.currentLocalTrackThumbnail;
      if (thumbnailPath != null && !thumbnailPath.startsWith('http')) {
        return Image.file(
          io.File(thumbnailPath),
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => buildFallbackContainer(),
        );
      }
    } else if (widget.downloadedTrack != null) {
      final thumbnailPath = widget.downloadedTrack!.thumbnail;
      if (!thumbnailPath.startsWith('http')) {
        return Image.file(
          io.File(thumbnailPath),
          fit: BoxFit.fill,
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
          
          // Main Controls
          _buildMainControls(musicProvider),
          
          const SizedBox(height: 24),
          
          // Secondary Controls
          _buildSecondaryControls(musicProvider),
        ],
      ),
    );
  }

  Widget _buildSongInfo(MusicProvider musicProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
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
  }

  Widget _buildProgressBar(MusicProvider musicProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final inactiveSliderColor = isDark ? Colors.grey[600] : Colors.grey[400];
    
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
          activeColor: context.watch<ThemeProvider>().accentColor,
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
  }

  Widget _buildMainControls(MusicProvider musicProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            // TODO: Previous track
          },
          icon: Icon(Icons.skip_previous, color: iconColor, size: 40),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().accentColor,
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
        IconButton(
          onPressed: () {
            // TODO: Next track
          },
          icon: Icon(Icons.skip_next, color: iconColor, size: 40),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(MusicProvider musicProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _isShuffle = !_isShuffle;
            });
          },
          icon: Icon(
            Icons.shuffle,
            color: _isShuffle ? context.watch<ThemeProvider>().accentColor : iconColor,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Add to favorites
          },
          icon: Icon(Icons.favorite_border, color: iconColor, size: 24),
        ),
        Consumer<DownloadProvider>(
          builder: (context, downloadProvider, child) {
            final currentVideo = musicProvider.currentVideo ?? widget.video;
            if (currentVideo == null) return const SizedBox.shrink();
            
            final isDownloaded = downloadProvider.isDownloaded(currentVideo.id);
            final isDownloading = downloadProvider.isDownloading(currentVideo.id);
            
            return IconButton(
              onPressed: isDownloaded || isDownloading 
                  ? null 
                  : () {
                      downloadProvider.startDownload(currentVideo, context);
                    },
              icon: Icon(
                isDownloaded ? Icons.download_done : Icons.download,
                color: isDownloaded ? Colors.green : iconColor,
                size: 24,
              ),
            );
          },
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isRepeat = !_isRepeat;
            });
          },
          icon: Icon(
            Icons.repeat,
            color: _isRepeat ? context.watch<ThemeProvider>().accentColor : iconColor,
            size: 24,
          ),
        ),
      ],
    );
  }



  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
