class DownloadedTrack {
  final String id;
  final String title;
  final String author;
  final String thumbnail;
  final String filePath;
  final int fileSize;
  final DateTime downloadedAt;
  final int duration;

  DownloadedTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnail,
    required this.filePath,
    required this.fileSize,
    required this.downloadedAt,
    required this.duration,
  });

  factory DownloadedTrack.fromJson(String jsonString) {
    try {
      final json = Map<String, dynamic>.fromEntries(
        jsonString.split(',').map((e) {
          final parts = e.split(':');
          if (parts.length >= 2) {
            return MapEntry(parts[0], parts[1]);
          }
          return MapEntry('', '');
        })
      );
      
      return DownloadedTrack(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        author: json['author'] ?? '',
        thumbnail: json['thumbnail'] ?? '',
        filePath: json['filePath'] ?? '',
        fileSize: int.tryParse(json['fileSize'] ?? '0') ?? 0,
        downloadedAt: json['downloadedAt'] != null 
            ? DateTime.tryParse(json['downloadedAt']) ?? DateTime.now()
            : DateTime.now(),
        duration: int.tryParse(json['duration'] ?? '0') ?? 0,
      );
    } catch (e) {
      print('Error parsing DownloadedTrack from JSON: $e');
      return DownloadedTrack(
        id: '',
        title: '',
        author: '',
        thumbnail: '',
        filePath: '',
        fileSize: 0,
        downloadedAt: DateTime.now(),
        duration: 0,
      );
    }
  }

  String toJson() {
    return 'id:$id,title:$title,author:$author,thumbnail:$thumbnail,'
           'filePath:$filePath,fileSize:$fileSize,downloadedAt:${downloadedAt.toIso8601String()},duration:$duration';
  }

  String get formattedDuration {
    if (duration <= 0) return '0:00';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize <= 0) return '0 B';
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSize >= 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }
}
