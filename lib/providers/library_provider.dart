import 'package:flutter/foundation.dart';
import '../models/downloaded_track.dart';
import '../models/playlist.dart';
import '../models/video.dart';
import '../services/download_service.dart';
import '../services/audio_player_service.dart';
import '../providers/music_provider.dart';

class LibraryProvider with ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final AudioPlayerService _audioService = AudioPlayerService();
  MusicProvider? _musicProvider;
  
  LibraryProvider() {
    _setupDownloadCallbacks();
  }
  
  void _setupDownloadCallbacks() {
    _downloadService.onDownloadComplete = (DownloadedTrack track) {
      // Add the new track to the list and notify UI
      _downloadedTracks.add(track);
      _isDownloading = false;
      notifyListeners();
      print('Download completed: ${track.title} - UI updated automatically');
    };
    
    _downloadService.onDownloadFailed = (String videoId) {
      _isDownloading = false;
      notifyListeners();
      print('Download failed for video: $videoId');
      // Optionally show error notification or update UI
    };
  }

  List<DownloadedTrack> _downloadedTracks = [];
  List<Playlist> _playlists = [];
  List<Video> _favoriteTracks = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  
  // Track download progress for individual videos
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};

  List<DownloadedTrack> get downloadedTracks => _downloadedTracks;
  List<Playlist> get playlists => _playlists;
  List<Video> get favoriteTracks => _favoriteTracks;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  
  // Get download progress for a specific video
  double getDownloadProgress(String videoId) => _downloadProgress[videoId] ?? 0.0;
  
  // Get download status for a specific video
  String getDownloadStatus(String videoId) => _downloadStatus[videoId] ?? '';
  
  // Get all download progress
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  
  // Get download info for a specific video
  Map<String, dynamic>? getDownloadInfo(String videoId) {
    if (_downloadProgress.containsKey(videoId)) {
      return {
        'progress': _downloadProgress[videoId] ?? 0.0,
        'status': _downloadStatus[videoId] ?? '',
        'isActive': true,
      };
    }
    return null;
  }
  
  // Get download progress from service for a specific video
  Map<String, dynamic>? getServiceDownloadProgress(String videoId) {
    return _downloadService.getDownloadProgress(videoId);
  }
  
  // Check if a specific video is being downloaded
  bool isVideoDownloading(String videoId) => _downloadProgress.containsKey(videoId);
  
  // Get total number of active downloads
  int get activeDownloadCount => _downloadProgress.length;
  
  // Get max concurrent downloads
  int get maxConcurrentDownloads => _downloadService.maxConcurrentDownloads;

  Future<void> loadDownloads() async {
    _setLoading(true);
    try {
      _downloadedTracks = await _downloadService.getDownloadedTracks();
      
      // Fix existing thumbnails for tracks that still have network URLs
      await _downloadService.fixExistingThumbnails();
      
      // Reload tracks after fixing thumbnails
      _downloadedTracks = await _downloadService.getDownloadedTracks();
      
      notifyListeners();
    } catch (e) {
      print('Error loading downloads: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Method to manually fix thumbnails for existing downloads
  Future<void> fixThumbnails() async {
    try {
      await _downloadService.fixExistingThumbnails();
      await loadDownloads(); // Reload to get updated tracks
    } catch (e) {
      print('Error fixing thumbnails: $e');
    }
  }
  
  // Method to refresh downloads
  Future<void> refreshDownloads() async {
    try {
      await loadDownloads();
    } catch (e) {
      print('Error refreshing downloads: $e');
    }
  }

  Future<void> downloadTrack(Video video) async {
    try {
      _isDownloading = true;
      _downloadProgress[video.id] = 0.0;
      _downloadStatus[video.id] = 'Starting download...';
      notifyListeners();
      
      // Start the download with progress tracking
      await _downloadService.downloadTrack(video, (progress, status) {
        _downloadProgress[video.id] = progress;
        _downloadStatus[video.id] = status;
        notifyListeners();
      });
    } catch (e) {
      _isDownloading = false;
      _downloadProgress.remove(video.id);
      _downloadStatus.remove(video.id);
      notifyListeners();
      print('Error downloading track: $e');
      rethrow;
    }
  }

  Future<void> deleteDownload(DownloadedTrack track) async {
    try {
      await _downloadService.deleteDownload(track.id);
      _downloadedTracks.removeWhere((t) => t.id == track.id);
      notifyListeners();
    } catch (e) {
      print('Error deleting download: $e');
    }
  }

  Future<void> playDownloadedTrack(DownloadedTrack track) async {
    try {
      if (_musicProvider != null) {
        await _musicProvider!.playLocalTrack(
          track.filePath,
          track.title,
          track.author,
          track.thumbnail.startsWith('http') ? null : track.thumbnail,
        );
      } else {
        await _audioService.playLocalFile(
          track.filePath,
          track.title,
          track.author,
          track.thumbnail.startsWith('http') ? null : track.thumbnail,
        );
      }
      print('Playing downloaded track: ${track.title}');
    } catch (e) {
      print('Error playing downloaded track: $e');
      rethrow;
    }
  }

  void setMusicProvider(MusicProvider musicProvider) {
    _musicProvider = musicProvider;
  }

  Future<void> shareDownloadedTrack(DownloadedTrack track) async {
    try {
      // This would typically use a share plugin
      // For now, we'll just print the file path
      print('Sharing file: ${track.filePath}');
      // TODO: Implement actual sharing functionality
    } catch (e) {
      print('Error sharing downloaded track: $e');
    }
  }



  Future<void> addToFavorites(Video video) async {
    if (!_favoriteTracks.any((track) => track.id == video.id)) {
      _favoriteTracks.add(video);
      notifyListeners();
    }
  }

  Future<void> removeFromFavorites(Video video) async {
    _favoriteTracks.removeWhere((track) => track.id == video.id);
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      tracks: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistId, Video video) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.tracks.any((track) => track.id == video.id)) {
      playlist.tracks.add(video);
      notifyListeners();
    }
  }

  Future<void> removeFromPlaylist(String playlistId, Video video) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    playlist.tracks.removeWhere((track) => track.id == video.id);
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  // Get comprehensive download queue status
  Map<String, dynamic> getDownloadQueueStatus() {
    return _downloadService.getDownloadQueueStatus();
  }
  
  // Check if there are any active downloads
  bool get hasActiveDownloads => _downloadService.activeDownloadCount > 0;
  
  // Resumable downloads configuration
  bool get isResumableDownloadsEnabled => _downloadService.useResumableDownloads;
  
  void setResumableDownloads(bool value) {
    _downloadService.setUseResumableDownloads(value);
    notifyListeners();
  }

  // Cancel all active downloads
  void cancelAllDownloads() {
    _downloadService.cancelAllDownloads();
    _isDownloading = false;
    notifyListeners();
  }
  
  // Clear all paused downloads
  void clearPausedDownloads() {
    _downloadService.clearPausedDownloads();
    notifyListeners();
  }

  // Cancel a specific download
  void cancelDownload(String videoId) {
    _downloadService.cancelDownload(videoId);
    _downloadProgress.remove(videoId);
    _downloadStatus.remove(videoId);
    
    // Check if no more downloads are active
    if (_downloadService.activeDownloadCount == 0) {
      _isDownloading = false;
    }
    
    notifyListeners();
  }
  
  // Pause a specific download
  void pauseDownload(String videoId) {
    _downloadService.pauseDownload(videoId);
    // Keep progress and status for resuming
    notifyListeners();
  }
  
  // Resume a paused download
  Future<void> resumeDownload(String videoId, String url, String filePath) async {
    try {
      _isDownloading = true;
      notifyListeners();
      
      await _downloadService.resumeDownload(
        videoId,
        url,
        filePath,
        (progress) {
          _downloadProgress[videoId] = progress;
          notifyListeners();
        },
      );
    } catch (e) {
      _isDownloading = false;
      notifyListeners();
      print('Error resuming download: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
