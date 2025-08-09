import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video.dart';

class YouTubePlayerService {
  static final YouTubePlayerService _instance = YouTubePlayerService._internal();
  factory YouTubePlayerService() => _instance;
  YouTubePlayerService._internal();

  YoutubePlayerController? _controller;
  Video? _currentVideo;
  bool _isInitialized = false;

  Video? get currentVideo => _currentVideo;
  YoutubePlayerController? get controller => _controller;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.metadata.duration ?? Duration.zero;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> playVideo(Video video) async {
    try {
      await initialize();
      
      _currentVideo = video;
      
      // Extract video ID from URL
      final videoId = _extractVideoId(video.url);
      if (videoId.isEmpty) {
        throw Exception('Invalid video URL');
      }

      // Dispose previous controller
      _controller?.dispose();

      // Create new controller
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      );

    } catch (e) {
      print('Error playing video: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    try {
      _controller?.play();
    } catch (e) {
      print('Error playing: $e');
    }
  }

  Future<void> pause() async {
    try {
      _controller?.pause();
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  Future<void> stop() async {
    try {
      _controller?.pause();
      _currentVideo = null;
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      _controller?.seekTo(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _controller?.setVolume((volume * 100).toInt());
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  String _extractVideoId(String url) {
    if (url.isEmpty) return '';
    
    // Handle different URL formats
    if (url.contains('v=')) {
      return url.split('v=').last.split('&').first;
    } else if (url.contains('/watch/')) {
      return url.split('/watch/').last.split('?').first;
    }
    return '';
  }

  void dispose() {
    _controller?.dispose();
    _currentVideo = null;
    _isInitialized = false;
  }
} 