import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/downloaded_track_card.dart';
import '../models/downloaded_track.dart';
import '../screens/full_screen_player.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadDownloads();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh downloads when the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadDownloads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.watch<ThemeProvider>().getProminentBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.watch<ThemeProvider>().primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Downloads'),
            Tab(text: 'Playlists'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadsTab(),
          _buildPlaylistsTab(),
          _buildFavoritesTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadsTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        if (libraryProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: context.watch<ThemeProvider>().getShimmerBaseColor(),
            ),
          );
        }

        if (libraryProvider.downloadedTracks.isEmpty) {
          return _buildEmptyDownloads();
        }
        
        // Add refresh button
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        libraryProvider.refreshDownloads();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Downloads'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Download settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: libraryProvider.isResumableDownloadsEnabled,
                          onChanged: (value) {
                            libraryProvider.setResumableDownloads(value ?? true);
                          },
                        ),
                        const Text('Resumable Downloads'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Show download status
            if (libraryProvider.hasActiveDownloads)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Downloading...',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Active downloads: ${libraryProvider.activeDownloadCount}/${libraryProvider.maxConcurrentDownloads}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Show individual download progress
                    if (libraryProvider.downloadProgress.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...libraryProvider.downloadProgress.entries.map((entry) {
                        final videoId = entry.key;
                        final progress = entry.value;
                        final status = libraryProvider.getDownloadStatus(videoId);
                        return Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: context.watch<ThemeProvider>().getShimmerBaseColor(),
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      libraryProvider.cancelDownload(videoId);
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.grey[600]!,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              if (status.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: Container(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: libraryProvider.downloadedTracks.length,
                  itemBuilder: (context, index) {
                    final track = libraryProvider.downloadedTracks[index];
                    return DownloadedTrackCard(
                      track: track,
                      onTap: () {
                        libraryProvider.playDownloadedTrack(track);
                        // Navigate to fullscreen player
                        Future.delayed(const Duration(milliseconds: 500), () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FullScreenPlayer(downloadedTrack: track),
                            ),
                          );
                        });
                      },
                      onDelete: () {
                        _showDeleteDialog(context, track, libraryProvider);
                      },
                                              onShare: null,
                    );
                  },
                ),
              ),
            ),
          ],
        );


      },
    );
  }

  Widget _buildEmptyDownloads() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: context.watch<ThemeProvider>().getSecondaryTextColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().getErrorTitleColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download your favorite songs to listen offline',
            style: TextStyle(
              color: context.watch<ThemeProvider>().getErrorTextColor(),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        if (libraryProvider.playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 64,
                  color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                ),
                const SizedBox(height: 16),
                Text(
                  'No playlists yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().getErrorTitleColor(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first playlist',
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getErrorTextColor(),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: libraryProvider.playlists.length,
          itemBuilder: (context, index) {
            final playlist = libraryProvider.playlists[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.watch<ThemeProvider>().getShimmerBaseColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_play),
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.tracks.length} tracks'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: Text('Play'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    // TODO: Handle playlist actions
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        if (libraryProvider.favoriteTracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: 64,
                  color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().getErrorTitleColor(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Like songs to see them here',
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getErrorTextColor(),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: libraryProvider.favoriteTracks.length,
          itemBuilder: (context, index) {
            final track = libraryProvider.favoriteTracks[index];
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    child: Image.network(
                      track.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.watch<ThemeProvider>().getShimmerBaseColor(),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                title: Text(track.title),
                subtitle: Text(track.author),
                trailing: IconButton(
                  icon: Icon(Icons.favorite, color: Colors.grey[600]!),
                  onPressed: () {
                    libraryProvider.removeFromFavorites(track);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, DownloadedTrack track, LibraryProvider libraryProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Download'),
          content: Text('Are you sure you want to delete "${track.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                libraryProvider.deleteDownload(track);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
