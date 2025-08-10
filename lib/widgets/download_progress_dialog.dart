import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String title;
  final String author;
  final Function()? onCancel;
  final Function()? onMinimize;

  const DownloadProgressDialog({
    super.key,
    required this.title,
    required this.author,
    this.onCancel,
    this.onMinimize,
  });

  @override
  State<DownloadProgressDialog> createState() => DownloadProgressDialogState();
}

class DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Preparing download...';
  bool _isMinimized = false;

  void updateProgress(double progress, String status) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _status = status;
      });
    }
  }

  void toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.cardColor,
      child: Container(
        padding: _isMinimized ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with minimize button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.download,
                    color: theme.primaryColor,
                    size: _isMinimized ? 16 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading',
                        style: TextStyle(
                          fontSize: _isMinimized ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      if (!_isMinimized)
                        Text(
                          _status,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_isMinimized ? Icons.expand_less : Icons.expand_more),
                  onPressed: toggleMinimized,
                  tooltip: _isMinimized ? 'Expand' : 'Minimize',
                ),
              ],
            ),
            
            if (!_isMinimized) ...[
              const SizedBox(height: 24),
              
              // Track Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.watch<ThemeProvider>().getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: context.watch<ThemeProvider>().getPlaceholderColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: context.watch<ThemeProvider>().getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.author,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 8),
            ],
            
            // Progress Bar
            Column(
              children: [
                if (!_isMinimized)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                if (!_isMinimized) const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  minHeight: _isMinimized ? 4 : 8,
                ),
                if (_isMinimized) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            
            if (!_isMinimized) ...[
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
