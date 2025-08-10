import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../models/downloaded_track.dart';
import '../screens/full_screen_player.dart';
import '../providers/theme_provider.dart';

class DownloadProgressScreen extends StatelessWidget {
  const DownloadProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, downloadProvider, child) {
          if (downloadProvider.downloads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: 64,
                    color: context.watch<ThemeProvider>().getErrorIconColor(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.watch<ThemeProvider>().getErrorTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your downloads will appear here',
                    style: TextStyle(
                      color: context.watch<ThemeProvider>().getErrorTextColor(),
                    ),
                  ),
                ],
              ),
            );
          }

                return FutureBuilder<List<DownloadedTrack>>(
        future: downloadProvider.getDownloadedTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final tracks = snapshot.data ?? [];
          
          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: 64,
                    color: context.watch<ThemeProvider>().getErrorIconColor(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.watch<ThemeProvider>().getErrorTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your downloads will appear here',
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
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _buildDownloadCard(context, track);
            },
          );
        },
      );
        },
      ),
    );
  }

  Widget _buildDownloadCard(BuildContext context, DownloadedTrack track) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(track.thumbnail),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.author,
              style: TextStyle(
                color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.download_done,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Downloaded',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  track.formattedFileSize,
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Text('Play'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'play':
                // TODO: Play downloaded track
                break;
              case 'delete':
                // TODO: Delete downloaded track
                break;
            }
          },
        ),
      ),
    );
  }
}
