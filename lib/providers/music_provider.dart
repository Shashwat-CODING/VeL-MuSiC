import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video.dart';
import '../models/content_item.dart';
import '../services/piped_api.dart';
import '../services/audio_player_service.dart';
import '../providers/theme_provider.dart';

// Add RepeatMode enum
enum RepeatMode {
  none,
  all,
  one,
}

class MusicProvider with ChangeNotifier {
  final PipedApiService _apiService = PipedApiService();
  final AudioPlayerService _audioService = AudioPlayerService();
  ThemeProvider? _themeProvider;

  MusicProvider() {
    _setupAudioListeners();
  }

  void setThemeProvider(ThemeProvider themeProvider) {
    _themeProvider = themeProvider;
  }

  List<Video> _trendingVideos = [];
  List<ContentItem> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _currentFilter = 'all';
  String _currentTrendingFilter = 'music';
  
  // Add repeat and shuffle properties
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isShuffling = false;

  List<Video> get trendingVideos => _trendingVideos;
  List<ContentItem> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;
  String get currentTrendingFilter => _currentTrendingFilter;
  Video? get currentVideo => _audioService.currentVideo;
  bool get isPlaying => _audioService.isPlaying;
  Duration get position => _audioService.position;
  Duration get duration => _audioService.duration;
  
  // Add repeat and shuffle getters
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffling => _isShuffling;
  
  // Local track getters
  String? get currentLocalTrackId => _audioService.currentLocalTrackId;
  String? get currentLocalTrackTitle => _audioService.currentLocalTrackTitle;
  String? get currentLocalTrackAuthor => _audioService.currentLocalTrackAuthor;
  String? get currentLocalTrackThumbnail => _audioService.currentLocalTrackThumbnail;
  bool get isPlayingLocalTrack => _audioService.isPlayingLocalTrack;

  // YouTube controller getter (placeholder for now)
  YoutubePlayerController? get youtubeController => null;

  // Get available filters
  Map<String, String> get searchFilters => PipedApiService.searchFilters;
  Map<String, String> get trendingFilters => PipedApiService.trendingFilters;

  // Add repeat and shuffle methods
  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  void setShuffle(bool shuffle) {
    _isShuffling = shuffle;
    notifyListeners();
  }

  Future<void> loadTrendingMusic({String filter = 'music'}) async {
    _setLoading(true);
    _clearError();
    _currentTrendingFilter = filter;

    try {
      _trendingVideos = await _apiService.getTrending(filter: filter);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchContent(String query, {String filter = 'all'}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      _currentFilter = filter;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    _searchQuery = query;
    _currentFilter = filter;

    try {
      _searchResults = await _apiService.search(query, filter: filter);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Legacy method for backward compatibility
  Future<void> searchMusic(String query) async {
    await searchContent(query, filter: 'music');
  }

  Future<void> playVideo(Video video) async {
    try {
      _clearError();
      await _audioService.playVideo(video);
      
      print('Playing video: ${video.title}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to play audio: ${e.toString()}');
    }
  }

  Future<void> playLocalTrack(String filePath, String title, String author, String? thumbnailPath) async {
    try {
      _clearError();
      await _audioService.playLocalFile(filePath, title, author, thumbnailPath);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to play local track: ${e.toString()}');
    }
  }

  void _setupAudioListeners() {
    _audioService.playerStateStream.listen((state) {
      notifyListeners();
    });
    
    _audioService.positionStream.listen((position) {
      notifyListeners();
    });
    
    _audioService.durationStream.listen((duration) {
      notifyListeners();
    });
  }

  Future<void> play() async {
    await _audioService.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioService.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioService.stop();
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seekTo(position);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = '';
    notifyListeners();
  }



  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 