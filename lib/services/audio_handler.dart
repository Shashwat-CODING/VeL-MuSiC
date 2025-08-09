import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/video.dart';

class AudioHandlerService {
  static final AudioHandlerService _instance = AudioHandlerService._internal();
  factory AudioHandlerService() => _instance;
  AudioHandlerService._internal();

  AudioHandler? _audioHandler;
  bool _isInitialized = false;

  AudioHandler? get audioHandler => _audioHandler;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.test_app.channel.audio',
        androidNotificationChannelName: 'YouTube Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    _isInitialized = true;
  }

  Future<void> playVideo(Video video) async {
    await initialize();
    
    if (_audioHandler != null) {
      await _audioHandler!.addQueueItem(
        MediaItem(
          id: video.id,
          album: 'YouTube Music',
          title: video.title,
          artist: video.author,
          artUri: Uri.parse(video.thumbnail),
          duration: Duration.zero, // Will be updated when loaded
        ),
      );
      
      await _audioHandler!.play();
    }
  }

  Future<void> play() async {
    await _audioHandler?.play();
  }

  Future<void> pause() async {
    await _audioHandler?.pause();
  }

  Future<void> stop() async {
    await _audioHandler?.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _audioHandler?.seek(position);
  }

  Future<void> skipToNext() async {
    await _audioHandler?.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await _audioHandler?.skipToPrevious();
  }

  void dispose() {
    _audioHandler?.stop();
    _isInitialized = false;
  }
}

class MyAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<MediaItem> _mediaItems = [];
  int _currentIndex = 0;

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  void _loadEmptyPlaylist() {
    queue.add([]);
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _currentIndex;
      final newQueue = queue.value;
      if (index < newQueue.length && duration != null) {
        final oldMediaItem = newQueue[index];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        newQueue[index] = newMediaItem;
        queue.add(newQueue);
        // mediaItem.add(newMediaItem); // Removed - not needed
      }
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((int? index) {
      if (index != null && index < queue.value.length) {
        _currentIndex = index;
        // mediaItem.add(queue.value[index]); // Removed - not needed
      }
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      if (sequenceState == null || sequenceState.currentIndex == null) return;
      final source = sequenceState.currentSource;
      final tag = source?.tag;
      if (tag is MediaItem && tag != queue.value[_currentIndex]) {
        queue.value[_currentIndex] = tag;
        queue.add(queue.value);
        // mediaItem.add(tag); // Removed - not needed
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _mediaItems.add(mediaItem);
    queue.add(_mediaItems);
    
    // If this is the first item, set it as the current source
    if (_mediaItems.length == 1) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(mediaItem.extras!['url'] as String)),
        initialPosition: Duration.zero,
        preload: true,
      );
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index >= 0 && index < _mediaItems.length) {
      _mediaItems.removeAt(index);
      queue.add(_mediaItems);
    }
  }

  @override
  Future<void> setQueue(List<MediaItem> queue) async {
    _mediaItems.clear();
    _mediaItems.addAll(queue);
    this.queue.add(_mediaItems);
  }

  @override
  Future<void> setMediaItem(MediaItem mediaItem) async {
    queue.add([mediaItem]);
    // mediaItem.add(mediaItem); // Removed - not needed
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      stop();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
