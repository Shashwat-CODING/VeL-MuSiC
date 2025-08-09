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

  List<DownloadedTrack> _downloadedTracks = [];
  List<Playlist> _playlists = [];
  List<Video> _favoriteTracks = [];
  bool _isLoading = false;

  List<DownloadedTrack> get downloadedTracks => _downloadedTracks;
  List<Playlist> get playlists => _playlists;
  List<Video> get favoriteTracks => _favoriteTracks;
  bool get isLoading => _isLoading;

  Future<void> loadDownloads() async {
    _setLoading(true);
    try {
      _downloadedTracks = await _downloadService.getDownloadedTracks();
      notifyListeners();
    } catch (e) {
      print('Error loading downloads: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Method to refresh downloads (called when new downloads complete)
  Future<void> refreshDownloads() async {
    await loadDownloads();
  }

  Future<void> downloadTrack(Video video) async {
    try {
      final downloadedTrack = await _downloadService.downloadTrack(video, null);
      _downloadedTracks.add(downloadedTrack);
      notifyListeners();
    } catch (e) {
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

  Future<void> openInFileManager(DownloadedTrack track) async {
    try {
      // This would typically use a file manager plugin
      // For now, we'll just print the file path
      print('Opening in file manager: ${track.filePath}');
      // TODO: Implement actual file manager opening
    } catch (e) {
      print('Error opening in file manager: $e');
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
