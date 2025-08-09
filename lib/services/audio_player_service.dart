import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/video.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Video? _currentVideo;
  bool _isInitialized = false;
  
  // Add support for local tracks
  String? _currentLocalTrackId;
  String? _currentLocalTrackTitle;
  String? _currentLocalTrackAuthor;
  String? _currentLocalTrackThumbnail;

  Video? get currentVideo => _currentVideo;
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  // Local track getters
  String? get currentLocalTrackId => _currentLocalTrackId;
  String? get currentLocalTrackTitle => _currentLocalTrackTitle;
  String? get currentLocalTrackAuthor => _currentLocalTrackAuthor;
  String? get currentLocalTrackThumbnail => _currentLocalTrackThumbnail;
  bool get isPlayingLocalTrack => _currentLocalTrackId != null;

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

      print('Getting player response for video ID: $videoId');
      
      // Get player response from Piped API
      final playerResponse = await _getPlayerResponse(videoId);
      print('Player response received: ${playerResponse.keys}');
      
      final audioUrl = _extractAudioUrl(playerResponse);
      print('Extracted audio URL: ${audioUrl.isNotEmpty ? "Found" : "Not found"}');
      
      if (audioUrl.isEmpty) {
        throw Exception('No audio URL found');
      }

      // Stop current playback
      await _audioPlayer.stop();

      // Create MediaItem for background playback
      final mediaItem = MediaItem(
        id: videoId,
        album: video.author,
        title: video.title,
        artUri: Uri.parse(video.thumbnail),
      );

      // Set audio source with MediaItem and play
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          tag: mediaItem,
        ),
      );
      await _audioPlayer.play();

    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> playLocalFile(String filePath, String title, String author, String? thumbnailPath) async {
    try {
      await initialize();
      
      // Stop current playback and clear previous track info
      await _audioPlayer.stop();
      _currentVideo = null;
      
      // Set local track information
      _currentLocalTrackId = filePath;
      _currentLocalTrackTitle = title;
      _currentLocalTrackAuthor = author;
      _currentLocalTrackThumbnail = thumbnailPath;

      // Create MediaItem for background playback
      final mediaItem = MediaItem(
        id: filePath,
        album: author,
        title: title,
        artUri: thumbnailPath != null ? Uri.file(thumbnailPath) : null,
      );

      // Set audio source with MediaItem and play
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.file(filePath),
          tag: mediaItem,
        ),
      );
      await _audioPlayer.play();

    } catch (e) {
      print('Error playing local file: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getPlayerResponse(String videoId) async {
    try {
      // Use Innertube API with Android client configuration
      final url = 'https://youtubei.googleapis.com/youtubei/v1/player?key=AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w';
      print('Requesting URL: $url');
      
      final payload = {
        'context': {
          'client': {
            'clientName': 'ANDROID',
            'clientVersion': '19.17.34',
            'clientId': 3,
            'userAgent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
          }
        },
        'videoId': videoId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Format-Version': '1',
          'X-YouTube-Client-Name': '3',
          'X-YouTube-Client-Version': '19.17.34',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
          'Referer': 'https://www.youtube.com/',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get player response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in _getPlayerResponse: $e');
      throw Exception('Error getting player response: $e');
    }
  }

  String _extractAudioUrl(Map<String, dynamic> playerResponse) {
    try {
      // Innertube API returns streamingData with formats
      final streamingData = playerResponse['streamingData'];
      if (streamingData == null) {
        print('No streamingData found in response');
        return '';
      }

      final formats = streamingData['formats'] as List<dynamic>?;
      final adaptiveFormats = streamingData['adaptiveFormats'] as List<dynamic>?;

      // Combine formats and adaptive formats
      final allFormats = <Map<String, dynamic>>[];
      if (formats != null) allFormats.addAll(formats.cast<Map<String, dynamic>>());
      if (adaptiveFormats != null) allFormats.addAll(adaptiveFormats.cast<Map<String, dynamic>>());

      print('Found ${allFormats.length} formats');

      // Find the best audio-only format
      String? bestAudioUrl;
      int bestBitrate = 0;

      for (final format in allFormats) {
        final mimeType = format['mimeType'] as String?;
        final url = format['url'] as String?;
        final bitrate = format['bitrate'] as int?;

        print('Format: mimeType=$mimeType, bitrate=$bitrate, hasUrl=${url != null}');

        // Look for audio-only formats (audio/mp4, audio/webm, etc.)
        if (mimeType != null && 
            mimeType.startsWith('audio/') && 
            url != null && 
            bitrate != null) {
          if (bitrate > bestBitrate) {
            bestBitrate = bitrate;
            bestAudioUrl = url;
            print('Found better audio format: bitrate=$bitrate');
          }
        }
      }

      if (bestAudioUrl != null) {
        print('Selected audio URL with bitrate: $bestBitrate');
      } else {
        print('No audio URL found');
      }

      return bestAudioUrl ?? '';
    } catch (e) {
      print('Error extracting audio URL: $e');
      return '';
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentVideo = null;
      _currentLocalTrackId = null;
      _currentLocalTrackTitle = null;
      _currentLocalTrackAuthor = null;
      _currentLocalTrackThumbnail = null;
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
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
    _audioPlayer.dispose();
    _currentVideo = null;
    _isInitialized = false;
  }
} 