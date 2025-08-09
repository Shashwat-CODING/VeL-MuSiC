class Channel {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String bannerUrl;
  final int subscriberCount;
  final int videoCount;
  final bool verified;
  final String url;
  final List<String> tags;
  final String? location;
  final String? joinedDate;

  Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.subscriberCount,
    required this.videoCount,
    required this.verified,
    required this.url,
    required this.tags,
    this.location,
    this.joinedDate,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: _extractChannelId(json['url'] ?? json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      avatarUrl: _constructAvatarUrl(json['thumbnail'] ?? json['avatarUrl'], json['id']),
      bannerUrl: json['bannerUrl']?.toString() ?? '',
      subscriberCount: _parseInt(json['subscribers'] ?? json['subscriberCount']),
      videoCount: _parseInt(json['videos'] ?? json['videoCount']),
      verified: json['verified'] == true,
      url: json['url']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location']?.toString(),
      joinedDate: json['joinedDate']?.toString(),
    );
  }

  static String _extractChannelId(String url) {
    if (url.startsWith('/channel/')) {
      return url.replaceFirst('/channel/', '');
    }
    return url;
  }

  static String _constructAvatarUrl(dynamic originalAvatarUrl, dynamic channelId) {
    // If we have a valid avatar URL from the response, use it
    if (originalAvatarUrl != null && originalAvatarUrl.toString().isNotEmpty) {
      final url = originalAvatarUrl.toString();
      // Check if it's a valid URL
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    
    // Fallback to default avatar if we have a channel ID
    if (channelId != null && channelId.toString().isNotEmpty) {
      return 'https://img.youtube.com/vi/$channelId/default.jpg';
    }
    
    // Final fallback to a generic avatar
    return 'https://via.placeholder.com/150/cccccc/666666?text=Channel';
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

  String get formattedSubscriberCount {
    if (subscriberCount <= 0) return '0';
    if (subscriberCount >= 1000000) {
      return '${(subscriberCount / 1000000).toStringAsFixed(1)}M';
    } else if (subscriberCount >= 1000) {
      return '${(subscriberCount / 1000).toStringAsFixed(1)}K';
    }
    return subscriberCount.toString();
  }

  String get formattedVideoCount {
    if (videoCount <= 0) return '0';
    if (videoCount >= 1000000) {
      return '${(videoCount / 1000000).toStringAsFixed(1)}M';
    } else if (videoCount >= 1000) {
      return '${(videoCount / 1000).toStringAsFixed(1)}K';
    }
    return videoCount.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'subscriberCount': subscriberCount,
      'videoCount': videoCount,
      'verified': verified,
      'url': url,
      'tags': tags,
      'location': location,
      'joinedDate': joinedDate,
    };
  }
}
