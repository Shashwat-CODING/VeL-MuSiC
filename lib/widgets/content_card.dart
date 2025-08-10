import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/content_item.dart';
import '../providers/theme_provider.dart';
import 'themed_popup_menu.dart';

class ContentCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback? onTap;
  final bool isPlaying;
  final VoidCallback? onDownload;
  final bool isDownloaded;
  final VoidCallback? onShowDetails;

  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.isPlaying = false,
    this.onDownload,
    this.isDownloaded = false,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 600;
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                isSingleColumn ? _buildSingleColumnLayout(context) : _buildMultiColumnLayout(context),
                // 3-dot menu
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ThemedPopupMenu(
                      child: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 20,
                      ),
                      items: [
                        ThemedPopupMenuItem(
                          label: 'Details',
                          icon: Icons.info_outline,
                          onTap: onShowDetails,
                        ),
                        if (content.type == ContentType.video)
                          ThemedPopupMenuItem(
                            label: isDownloaded ? 'Downloaded' : 'Download',
                            icon: isDownloaded ? Icons.download_done : Icons.download,
                            onTap: onDownload,
                          ),
                        // Removed Share option
                        ThemedPopupMenuItem(
                          label: 'Add to Favorites',
                          icon: Icons.favorite_border,
                          onTap: () {
                            // TODO: Implement favorite functionality
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleColumnLayout(BuildContext context) {
    return Row(
      children: [
        // Thumbnail - edge to edge on right side
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: Stack(
            children: [
              Container(
                height: 90,
                width: 160,
                child: CachedNetworkImage(
                  imageUrl: content.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.watch<ThemeProvider>().getPlaceholderColor(),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.watch<ThemeProvider>().getPlaceholderColor(),
                    child: Icon(
                      _getContentIcon(),
                      color: context.watch<ThemeProvider>().getErrorIconColor(),
                    ),
                  ),
                ),
              ),
              if (content.type == ContentType.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      content.video!.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isPlaying && content.type == ContentType.video)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.watch<ThemeProvider>().accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSubtitleText(),
                  style: TextStyle(
                    color: context.watch<ThemeProvider>().getTertiaryTextColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: content.thumbnail,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.watch<ThemeProvider>().getPlaceholderColor(),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => FittedBox(
                    fit: BoxFit.cover,
                    child: Container(
                      color: context.watch<ThemeProvider>().getPlaceholderColor(),
                      child: Icon(
                        _getContentIcon(),
                        color: context.watch<ThemeProvider>().getErrorIconColor(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (content.type == ContentType.video)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    content.video!.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (isPlaying && content.type == ContentType.video)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                      color: context.watch<ThemeProvider>().accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getSubtitleText(),
                style: TextStyle(
                  color: context.watch<ThemeProvider>().getTertiaryTextColor(),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getContentIcon() {
    switch (content.type) {
      case ContentType.video:
        return Icons.play_circle_outline;
      case ContentType.channel:
        return Icons.account_circle;
      case ContentType.playlist:
        return Icons.playlist_play;
    }
  }

  String _getSubtitleText() {
    switch (content.type) {
      case ContentType.video:
        return '${content.video!.formattedViewCount} views';
      case ContentType.channel:
        return '${content.channel!.formattedSubscriberCount} subscribers • ${content.channel!.formattedVideoCount} videos';
      case ContentType.playlist:
        return '${content.playlist!.formattedVideoCount} • ${content.playlist!.formattedViewCount} views';
    }
  }
}
