import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../models/video.dart';
import '../providers/music_provider.dart';
import '../providers/download_provider.dart';
import '../services/piped_api.dart';
import '../widgets/video_card.dart';
import '../widgets/video_modal.dart';
import '../widgets/mini_player.dart';
import '../providers/theme_provider.dart';

class ChannelScreen extends StatefulWidget {
  final Channel channel;

  const ChannelScreen({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final PipedApiService _apiService = PipedApiService();
  List<Video> _channelVideos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  String? _nextPage;
  Channel? _channelInfo;

  @override
  void initState() {
    super.initState();
    _loadChannelVideos();
  }

  Future<void> _loadChannelVideos({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final result = await _apiService.getChannelVideos(
        widget.channel.id,
        nextPage: loadMore ? _nextPage : null,
      );
      
      setState(() {
        if (loadMore) {
          _channelVideos.addAll(result['videos'] as List<Video>);
          _isLoadingMore = false;
        } else {
          _channelVideos = result['videos'] as List<Video>;
          _isLoading = false;
        }
        _nextPage = result['nextPage'] as String?;
        _channelInfo = result['channel'] as Channel?;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_nextPage != null && !_isLoadingMore) {
      await _loadChannelVideos(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.channel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [],
      ),
      body: Column(
        children: [
          // Channel Header
          _buildChannelHeader(),
          
          // Videos Section
          Expanded(
            child: _buildVideosSection(),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 0 && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              // Navigation to other tabs is intentionally no-op here to avoid deep dependency cycles
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).primaryColor,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Channel Avatar and Info
          Row(
            children: [
                             // Channel Avatar
               Container(
                 width: 80,
                 height: 80,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(40),
                   border: Border.all(
                     color: Theme.of(context).dividerColor.withOpacity(0.3),
                     width: 2,
                   ),
                 ),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(38),
                   child: CachedNetworkImage(
                     imageUrl: _channelInfo?.avatarUrl ?? widget.channel.avatarUrl,
                     fit: BoxFit.cover,
                     placeholder: (context, url) => Container(
                       color: Theme.of(context).cardColor,
                       child: Icon(
                         Icons.account_circle,
                         size: 40,
                         color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                       ),
                     ),
                     errorWidget: (context, url, error) => Container(
                       color: Theme.of(context).cardColor,
                       child: Icon(
                         Icons.account_circle,
                         size: 40,
                         color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                       ),
                     ),
                   ),
                 ),
               ),
              
              const SizedBox(width: 16),
              
              // Channel Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.channel.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.channel.verified)
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                                         Text(
                       '${_channelInfo?.formattedSubscriberCount ?? widget.channel.formattedSubscriberCount} subscribers',
                       style: TextStyle(
                         color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                         fontSize: 14,
                       ),
                     ),
                     const SizedBox(height: 2),
                     Text(
                       '${_channelInfo?.formattedVideoCount ?? widget.channel.formattedVideoCount} videos',
                       style: TextStyle(
                         color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                         fontSize: 14,
                       ),
                     ),
                     if (_channelInfo?.location != null || widget.channel.location != null) ...[
                       const SizedBox(height: 2),
                       Text(
                         _channelInfo?.location ?? widget.channel.location!,
                         style: TextStyle(
                           color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                           fontSize: 14,
                         ),
                       ),
                     ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Channel Description
          if ((_channelInfo?.description?.isNotEmpty ?? false) || widget.channel.description.isNotEmpty) ...[
            Text(
              _channelInfo?.description ?? widget.channel.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          
          // Removed Subscribe button as requested
        ],
      ),
    );
  }

  Widget _buildVideosSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.watch<ThemeProvider>().getErrorIconColor(),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading videos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.watch<ThemeProvider>().getErrorTitleColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.watch<ThemeProvider>().getErrorTextColor(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChannelVideos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_channelVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: context.watch<ThemeProvider>().getErrorIconColor(),
            ),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.watch<ThemeProvider>().getErrorTitleColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This channel doesn\'t have any videos yet',
              style: TextStyle(
                color: context.watch<ThemeProvider>().getErrorTextColor(),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreVideos();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _channelVideos.length + (_nextPage != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _channelVideos.length) {
            // Loading more indicator
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final video = _channelVideos[index];
          return Consumer<MusicProvider>(
            builder: (context, musicProvider, child) {
              final isPlaying = musicProvider.currentVideo?.id == video.id;

              return Consumer<DownloadProvider>(
                builder: (context, downloadProvider, child) {
                  final isDownloading = downloadProvider.isDownloading(video.id);
                  final isDownloaded = downloadProvider.isDownloaded(video.id);
                  
                  return VideoCard(
                    video: video,
                    isPlaying: isPlaying,
                    onTap: () {
                      musicProvider.playVideo(video);
                    },
                    onDownload: () {
                      if (!isDownloading && !isDownloaded) {
                        downloadProvider.startDownload(video, context);
                      }
                    },
                    isDownloaded: isDownloaded,
                    onShowDetails: () {
                      showDialog(
                        context: context,
                        builder: (context) => VideoModal(
                          video: video,
                          onPlay: () {
                            Navigator.of(context).pop();
                            musicProvider.playVideo(video);
                          },
                          onDownload: () {
                            Navigator.of(context).pop();
                            if (!isDownloading && !isDownloaded) {
                              downloadProvider.startDownload(video, context);
                            }
                          },
                          isDownloaded: isDownloaded,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
