import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/music_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/content_card.dart';

import '../widgets/video_modal.dart';
import '../screens/channel_screen.dart';
import '../screens/search_screen.dart';
import '../models/content_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadTrendingMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.watch<ThemeProvider>().getProminentBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          'VeL-MuSiC',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.watch<ThemeProvider>().primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          if (musicProvider.isLoading) {
            return _buildShimmerLoading();
          }

          if (musicProvider.error.isNotEmpty) {
            return _buildErrorWidget(musicProvider.error);
          }

          final contentItems = musicProvider.trendingVideos
              .map((video) => ContentItem(type: ContentType.video, video: video))
              .toList();

          if (contentItems.isEmpty) {
            return _buildEmptyWidget();
          }

          return _buildContentGrid(contentItems, musicProvider);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: context.watch<ThemeProvider>().getShimmerBaseColor(),
          highlightColor: context.watch<ThemeProvider>().getShimmerHighlightColor(),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
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
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().getErrorTitleColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.watch<ThemeProvider>().getErrorTextColor(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MusicProvider>().loadTrendingMusic();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: context.watch<ThemeProvider>().getErrorIconColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No content found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().getErrorTitleColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No trending content available at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.watch<ThemeProvider>().getErrorTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(List<ContentItem> contentItems, MusicProvider musicProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 1 ? 3.0 : 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          padding: const EdgeInsets.all(8),
          itemCount: contentItems.length,
          itemBuilder: (context, index) {
            final content = contentItems[index];
            final isPlaying = content.type == ContentType.video &&
                musicProvider.currentVideo?.id == content.video?.id;

            return Consumer<DownloadProvider>(
              builder: (context, downloadProvider, child) {
                final isDownloading = content.type == ContentType.video
                    ? downloadProvider.isDownloading(content.video!.id)
                    : false;
                final isDownloaded = content.type == ContentType.video
                    ? downloadProvider.isDownloaded(content.video!.id)
                    : false;

                return ContentCard(
                  content: content,
                  isPlaying: isPlaying,
                  onTap: () {
                    if (content.type == ContentType.video) {
                      musicProvider.playVideo(content.video!);
                    } else if (content.type == ContentType.channel) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChannelScreen(channel: content.channel!),
                        ),
                      );
                    } else {
                      _showContentDetails(content);
                    }
                  },
                  onDownload: content.type == ContentType.video
                      ? () {
                          if (!isDownloading && !isDownloaded) {
                            downloadProvider.startDownload(content.video!, context);
                          }
                        }
                      : null,
                  isDownloaded: isDownloaded,
                  onShowDetails: () => _showContentDetails(content),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showContentDetails(ContentItem content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoModal(
        video: content.type == ContentType.video ? content.video! : null,
        contentItem: content,
      ),
    );
  }
}
