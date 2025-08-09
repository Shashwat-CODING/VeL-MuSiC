import 'dart:io';
import 'package:flutter/material.dart';
import '../models/downloaded_track.dart';
import '../screens/full_screen_player.dart';

class DownloadedTrackCard extends StatelessWidget {
  final DownloadedTrack track;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInFileManager;

  const DownloadedTrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.onOpenInFileManager,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 80,
            height: 45,
            child: _buildThumbnailImage(track),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.download_done,
                  size: 12,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${track.formattedDuration} • ${track.formattedFileSize}',
                  style: TextStyle(
                    color: Colors.grey[500],
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
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
            ),
            // Removed Share menu item
            PopupMenuItem(
              value: 'file_manager',
              child: Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 8),
                  Text('Open in File Manager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
                      onSelected: (value) {
              switch (value) {
                case 'play':
                  onTap?.call();
                  break;
                // Share removed
                case 'file_manager':
                  onOpenInFileManager?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThumbnailImage(DownloadedTrack track) {
    if (track.thumbnail.startsWith('http')) {
      return Image.network(
        track.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.music_note,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(track.thumbnail),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.music_note,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }
}
