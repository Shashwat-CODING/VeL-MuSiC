import 'dart:io';
import 'package:flutter/material.dart';
import '../models/downloaded_track.dart';

import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DownloadedTrackCard extends StatelessWidget {
  final DownloadedTrack track;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  const DownloadedTrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.onDelete,
    this.onShare,
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
            child: _buildThumbnailImage(context, track),
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
                color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.download_done,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${track.formattedDuration} • ${track.formattedFileSize}',
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getTertiaryTextColor(),
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

            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.grey[600]!),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.grey[600]!)),
                ],
              ),
            ),
          ],
                      onSelected: (value) {
              switch (value) {
                case 'play':
                  onTap?.call();
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

  Widget _buildThumbnailImage(BuildContext context, DownloadedTrack track) {
    if (track.thumbnail.startsWith('http')) {
      // Network image - this should not happen for downloaded tracks
      // Fallback to music icon
      return Container(
        color: context.watch<ThemeProvider>().getPlaceholderColor(),
        child: Icon(
          Icons.music_note,
          color: context.watch<ThemeProvider>().getSecondaryTextColor(),
        ),
      );
    } else {
      // Local file image
      final file = File(track.thumbnail);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: context.watch<ThemeProvider>().getPlaceholderColor(),
              child: Icon(
                Icons.music_note,
                color: context.watch<ThemeProvider>().getSecondaryTextColor(),
              ),
            );
          },
        );
      } else {
        // File doesn't exist, show music icon
        return Container(
          color: context.watch<ThemeProvider>().getPlaceholderColor(),
          child: Icon(
            Icons.music_note,
            color: context.watch<ThemeProvider>().getSecondaryTextColor(),
          ),
        );
      }
    }
  }
}
