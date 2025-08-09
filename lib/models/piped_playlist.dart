import 'video.dart';

class PipedPlaylist {
  final String id;
  final String name;
  final String description;
  final String thumbnail;
  final String uploaderName;
  final String uploaderUrl;
  final String uploaderAvatar;
  final int videoCount;
  final int viewCount;
  final String url;
  final List<Video> videos;
  final bool isPublic;
  final String? nextPage;

  PipedPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnail,
    required this.uploaderName,
    required this.uploaderUrl,
    required this.uploaderAvatar,
    required this.videoCount,
    required this.viewCount,
    required this.url,
    required this.videos,
    required this.isPublic,
    this.nextPage,
  });

  factory PipedPlaylist.fromJson(Map<String, dynamic> json) {
    return PipedPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      uploaderName: json['uploaderName']?.toString() ?? '',
      uploaderUrl: json['uploaderUrl']?.toString() ?? '',
      uploaderAvatar: json['uploaderAvatar']?.toString() ?? '',
      videoCount: _parseInt(json['videoCount']),
      viewCount: _parseInt(json['viewCount']),
      url: json['url']?.toString() ?? '',
      videos: json['videos'] is List
          ? (json['videos'] as List)
              .whereType<Map<String, dynamic>>()
              .map((video) => Video.fromJson(video))
              .toList()
          : [],
      isPublic: json['isPublic'] == true,
      nextPage: json['nextpage']?.toString(),
    );
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

  String get formattedViewCount {
    if (viewCount <= 0) return '0';
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  String get formattedVideoCount {
    return '$videoCount video${videoCount == 1 ? '' : 's'}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnail': thumbnail,
      'uploaderName': uploaderName,
      'uploaderUrl': uploaderUrl,
      'uploaderAvatar': uploaderAvatar,
      'videoCount': videoCount,
      'viewCount': viewCount,
      'url': url,
      'videos': videos.map((video) => video.toJson()).toList(),
      'isPublic': isPublic,
      'nextpage': nextPage,
    };
  }
}
