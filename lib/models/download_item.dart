import 'video.dart';

enum DownloadStatus { downloading, completed, failed }

class DownloadItem {
  final String id;
  final Video video;
  final DownloadStatus status;
  final double progress;
  final DateTime? startedAt;
  final DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.video,
    required this.status,
    required this.progress,
    this.startedAt,
    this.completedAt,
  });

  DownloadItem copyWith({
    String? id,
    Video? video,
    DownloadStatus? status,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      video: video ?? this.video,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] ?? '',
      video: Video.fromJson(json['video']),
      status: DownloadStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => DownloadStatus.downloading,
      ),
      progress: (json['progress'] ?? 0.0).toDouble(),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video': video.toJson(),
      'status': status.toString(),
      'progress': progress,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
