import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/music_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/filter_selector.dart';
import '../widgets/video_modal.dart';
import '../widgets/mini_player.dart';
import '../screens/channel_screen.dart';

import '../models/content_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => LibraryProvider()),
        ChangeNotifierProvider(create: (context) => DownloadProvider()),
      ],
      child: Scaffold(
        extendBody: true, // Show mini player in search
        appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for content...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          onSubmitted: (query) {
            context.read<MusicProvider>().searchContent(query);
          },
        ),
                  backgroundColor: context.watch<ThemeProvider>().primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              context.read<MusicProvider>().searchContent('');
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter selector
          Consumer<MusicProvider>(
            builder: (context, musicProvider, child) {
              final availableFilters = musicProvider.searchFilters;
              final currentFilter = musicProvider.currentFilter;

              return FilterSelector(
                currentFilter: currentFilter,
                availableFilters: availableFilters,
                onFilterChanged: (filter) {
                  context.read<MusicProvider>().searchContent(
                        musicProvider.searchQuery,
                        filter: filter,
                      );
                },
                isSearchMode: true,
              );
            },
          ),

          // Content
          Expanded(
            child: Consumer<MusicProvider>(
              builder: (context, musicProvider, child) {
                if (musicProvider.isLoading) {
                  return _buildShimmerLoading();
                }

                if (musicProvider.error.isNotEmpty) {
                  return _buildErrorWidget(musicProvider.error);
                }

                final contentItems = musicProvider.searchResults;

                if (contentItems.isEmpty && musicProvider.searchQuery.isNotEmpty) {
                  return _buildEmptyWidget();
                }

                if (contentItems.isEmpty) {
                  return _buildInitialState();
                }

                return _buildContentGrid(contentItems, musicProvider);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return BottomNavigationBar(
                currentIndex: 0, // Search is not part of main navigation, so we show home as active
                onTap: (index) {
                  // Navigate back to main navigation
                  Navigator.of(context).pop();
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: themeProvider.primaryColor,
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
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: context.watch<ThemeProvider>().getErrorIconColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for music',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().getErrorTitleColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your favorite songs, artists, and playlists',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.watch<ThemeProvider>().getErrorTextColor(),
            ),
          ),
        ],
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
              final query = _searchController.text;
              if (query.isNotEmpty) {
                context.read<MusicProvider>().searchContent(query);
              }
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
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().getErrorTitleColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else or change the filter',
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
