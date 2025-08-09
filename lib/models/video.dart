class Video {
  final String id;
  final String title;
  final String author;
  final String authorId;
  final String authorUrl;
  final String thumbnail;
  final String description;
  final int viewCount;
  final int published;
  final String publishedText;
  final int lengthSeconds;
  final String url;
  final List<String> tags;
  final bool isLiveContent;
  final String? uploaderAvatar;

  Video({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    required this.authorUrl,
    required this.thumbnail,
    required this.description,
    required this.viewCount,
    required this.published,
    required this.publishedText,
    required this.lengthSeconds,
    required this.url,
    required this.tags,
    required this.isLiveContent,
    this.uploaderAvatar,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final videoId = _extractVideoId(json['url'] ?? '');
    
    return Video(
      id: videoId,
      title: json['title']?.toString() ?? '',
      author: json['uploaderName']?.toString() ?? '',
      authorId: json['uploaderUrl']?.toString().split('/').last ?? '',
      authorUrl: json['uploaderUrl']?.toString() ?? '',
      thumbnail: _constructThumbnailUrl(videoId, json['thumbnail']),
      description: json['shortDescription']?.toString() ?? '',
      viewCount: _parseInt(json['views']),
      published: _parseInt(json['uploaded']),
      publishedText: json['uploadedDate']?.toString() ?? '',
      lengthSeconds: _parseInt(json['duration']),
      url: json['url']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isLiveContent: json['isShort'] == true,
      uploaderAvatar: json['uploaderAvatar']?.toString(),
    );
  }

  static String _extractVideoId(String url) {
    if (url.isEmpty) return '';
    
    // Handle different URL formats
    if (url.contains('v=')) {
      return url.split('v=').last.split('&').first;
    } else if (url.contains('/watch/')) {
      return url.split('/watch/').last.split('?').first;
    }
    return '';
  }

  static String _constructThumbnailUrl(String videoId, dynamic originalThumbnail) {
    if (videoId.isEmpty) {
      // Fallback to original thumbnail if available
      if (originalThumbnail != null && originalThumbnail.toString().isNotEmpty) {
        return originalThumbnail.toString();
      }
      return '';
    }
    
    // For now, use hqdefault, but you could implement a fallback mechanism
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  String get formattedDuration {
    if (lengthSeconds <= 0) return '0:00';
    final minutes = lengthSeconds ~/ 60;
    final seconds = lengthSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedViewCount {
    if (viewCount <= 0) return '0';
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'authorId': authorId,
      'authorUrl': authorUrl,
      'thumbnail': thumbnail,
      'description': description,
      'viewCount': viewCount,
      'published': published,
      'publishedText': publishedText,
      'lengthSeconds': lengthSeconds,
      'url': url,
      'tags': tags,
      'isLiveContent': isLiveContent,
      'uploaderAvatar': uploaderAvatar,
    };
  }
} 