import 'video.dart';
import 'channel.dart';
import 'piped_playlist.dart';

enum ContentType { video, channel, playlist }

class ContentItem {
  final ContentType type;
  final Video? video;
  final Channel? channel;
  final PipedPlaylist? playlist;

  ContentItem({
    required this.type,
    this.video,
    this.channel,
    this.playlist,
  }) : assert(
         (type == ContentType.video && video != null) ||
         (type == ContentType.channel && channel != null) ||
         (type == ContentType.playlist && playlist != null),
         'Content type must match the provided data'
       );

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    
    switch (type) {
      case 'stream':
        return ContentItem(
          type: ContentType.video,
          video: Video.fromJson(json),
        );
      case 'channel':
        return ContentItem(
          type: ContentType.channel,
          channel: Channel.fromJson(json),
        );
      case 'playlist':
        return ContentItem(
          type: ContentType.playlist,
          playlist: PipedPlaylist.fromJson(json),
        );
      default:
        throw Exception('Unknown content type: $type');
    }
  }

  String get title {
    switch (type) {
      case ContentType.video:
        return video!.title;
      case ContentType.channel:
        return channel!.name;
      case ContentType.playlist:
        return playlist!.name;
    }
  }

  String get thumbnail {
    switch (type) {
      case ContentType.video:
        return video!.thumbnail;
      case ContentType.channel:
        return channel!.avatarUrl;
      case ContentType.playlist:
        return playlist!.thumbnail;
    }
  }

  String get author {
    switch (type) {
      case ContentType.video:
        return video!.author;
      case ContentType.channel:
        return channel!.name;
      case ContentType.playlist:
        return playlist!.uploaderName;
    }
  }

  String get id {
    switch (type) {
      case ContentType.video:
        return video!.id;
      case ContentType.channel:
        return channel!.id;
      case ContentType.playlist:
        return playlist!.id;
    }
  }

  String get url {
    switch (type) {
      case ContentType.video:
        return video!.url;
      case ContentType.channel:
        return channel!.url;
      case ContentType.playlist:
        return playlist!.url;
    }
  }

  String get description {
    switch (type) {
      case ContentType.video:
        return video!.description;
      case ContentType.channel:
        return channel!.description;
      case ContentType.playlist:
        return playlist!.description;
    }
  }

  Map<String, dynamic> toJson() {
    switch (type) {
      case ContentType.video:
        return video!.toJson();
      case ContentType.channel:
        return channel!.toJson();
      case ContentType.playlist:
        return playlist!.toJson();
    }
  }
}
