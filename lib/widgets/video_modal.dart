import 'package:flutter/material.dart';
import '../models/video.dart';
import '../models/content_item.dart';
import '../screens/channel_screen.dart';

class VideoModal extends StatelessWidget {
  final Video? video;
  final ContentItem? contentItem;
  final VoidCallback? onPlay;
  final VoidCallback? onDownload;
  final bool isDownloaded;

  const VideoModal({
    super.key,
    this.video,
    this.contentItem,
    this.onPlay,
    this.onDownload,
    this.isDownloaded = false,
  }) : assert(video != null || contentItem != null, 'Either video or contentItem must be provided');

  Video? get _video => video ?? contentItem?.video;
  ContentItem? get _contentItem => contentItem;

  String _getThumbnail() {
    if (_video != null) return _video!.thumbnail;
    if (_contentItem != null) return _contentItem!.thumbnail;
    return '';
  }

  String _getTitle() {
    if (_video != null) return _video!.title;
    if (_contentItem != null) return _contentItem!.title;
    return '';
  }

  String _getAuthor() {
    if (_video != null) return _video!.author;
    if (_contentItem != null) return _contentItem!.author;
    return '';
  }

  String _getDescription() {
    if (_video != null) return _video!.description;
    if (_contentItem != null) return _contentItem!.description;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : double.infinity,
          maxHeight: isTablet ? 400 : MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, isTablet),
            
            // Content
            Expanded(
              child: isTablet 
                  ? _buildTabletLayout(context)
                  : _buildMobileLayout(context),
            ),
            
            // Actions
            _buildActions(context, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: Colors.white,
            size: isTablet ? 32 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Track Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Center(
            child: Container(
              width: 256,
              height: 166,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getThumbnail(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 50),
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Author
          Text(
            'by ${_getAuthor()}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details
          _buildDetails(context),
          
          const SizedBox(height: 20),
          
          // Description
          if (_getDescription().isNotEmpty) ...[
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Thumbnail
          Container(
            width: 256,
            height: 144,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _getThumbnail(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note, size: 50),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Right side - Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Author
                Text(
                  'by ${_getAuthor()}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Details
                _buildDetails(context),
                
                const SizedBox(height: 20),
                
                // Description
                if (_getDescription().isNotEmpty) ...[
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDescription(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    if (_video != null) {
      return Column(
        children: [
          _buildDetailRow('Duration', _formatDuration(_video!.lengthSeconds)),
          _buildDetailRow('Views', _formatViews(_video!.viewCount)),
          _buildDetailRow('Published', _video!.publishedText),
        ],
      );
    } else if (_contentItem != null) {
      switch (_contentItem!.type) {
        case ContentType.channel:
          final channel = _contentItem!.channel!;
          return Column(
            children: [
              _buildDetailRow('Subscribers', channel.formattedSubscriberCount),
              _buildDetailRow('Videos', channel.formattedVideoCount),
              if (channel.location != null)
                _buildDetailRow('Location', channel.location!),
            ],
          );
        case ContentType.playlist:
          final playlist = _contentItem!.playlist!;
          return Column(
            children: [
              _buildDetailRow('Videos', playlist.formattedVideoCount),
              _buildDetailRow('Views', playlist.formattedViewCount),
              _buildDetailRow('Uploader', playlist.uploaderName),
            ],
          );
        default:
          return const SizedBox.shrink();
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Primary action button
          Expanded(
                          child: ElevatedButton.icon(
                onPressed: _getPrimaryAction(context),
                icon: Icon(_getPrimaryActionIcon()),
                label: Text(
                  _getPrimaryActionText(),
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Secondary action button
          if (_shouldShowSecondaryAction()) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDownloaded ? null : onDownload,
                icon: Icon(
                  isDownloaded ? Icons.download_done : Icons.download,
                ),
                label: Text(
                  isDownloaded ? 'Downloaded' : 'Download',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _getPrimaryAction(BuildContext context) {
    if (_video != null) return onPlay;
    if (_contentItem != null) {
      switch (_contentItem!.type) {
        case ContentType.channel:
          return () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChannelScreen(channel: _contentItem!.channel!),
              ),
            );
          };
        case ContentType.playlist:
          return () {
            // TODO: Open playlist
            Navigator.of(context).pop();
          };
        default:
          return null;
      }
    }
    return null;
  }

  IconData _getPrimaryActionIcon() {
    if (_video != null) return Icons.play_arrow;
    if (_contentItem != null) {
      switch (_contentItem!.type) {
        case ContentType.channel:
          return Icons.account_circle;
        case ContentType.playlist:
          return Icons.playlist_play;
        default:
          return Icons.info;
      }
    }
    return Icons.info;
  }

  String _getPrimaryActionText() {
    if (_video != null) return 'Play';
    if (_contentItem != null) {
      switch (_contentItem!.type) {
        case ContentType.channel:
          return 'View Channel';
        case ContentType.playlist:
          return 'Open Playlist';
        default:
          return 'View Details';
      }
    }
    return 'View Details';
  }

  bool _shouldShowSecondaryAction() {
    return _video != null; // Only show download for videos
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatViews(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }
}
