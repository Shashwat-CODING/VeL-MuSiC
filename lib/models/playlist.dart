import 'video.dart';

class Playlist {
  final String id;
  final String name;
  final List<Video> tracks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Playlist({
    required this.id,
    required this.name,
    required this.tracks,
    required this.createdAt,
    this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((track) => Video.fromJson(track))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get trackCount {
    return '${tracks.length} track${tracks.length == 1 ? '' : 's'}';
  }
}
