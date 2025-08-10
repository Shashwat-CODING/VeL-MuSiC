import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/downloaded_track.dart';
import '../services/notification_service.dart';
import '../services/config.dart';

class DownloadService {
  late final Dio _dio;
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, int> _pausedDownloads = {}; // Track paused downloads with their current position
  final int _maxConcurrentDownloads = 3;
  final int _downloadTimeout = 300; // 5 minutes
  final int _connectionTimeout = 30; // 30 seconds
  
  // Callback for download completion
  Function(DownloadedTrack)? onDownloadComplete;
  Function(String)? onDownloadFailed;
  
  // Configuration options
  bool _useResumableDownloads = true;
  bool get useResumableDownloads => _useResumableDownloads;
  
  void setUseResumableDownloads(bool value) {
    _useResumableDownloads = value;
  }
  
  DownloadService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio();
    
    // Configure Dio for optimal download performance
    _dio.options = BaseOptions(
      connectTimeout: Duration(seconds: _connectionTimeout),
      receiveTimeout: Duration(seconds: _downloadTimeout),
      sendTimeout: Duration(seconds: _connectionTimeout),
      // Enable keep-alive for better performance
      headers: {
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=300, max=1000',
      },
    );

    // Add interceptors for better error handling and logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add user agent and other headers for better compatibility
        options.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';
        handler.next(options);
      },
      onError: (error, handler) {
        print('Dio error: ${error.message}');
        handler.next(error);
      },
    ));

    // Configure HTTP client for better performance
    // Note: IOHttpClientAdapter is not available in current Dio version
    // Using default adapter with optimized timeout settings
  }

  static const String _downloadsKey = 'downloaded_tracks';

  Future<List<DownloadedTrack>> getDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getStringList(_downloadsKey) ?? [];
      
      return tracksJson
          .map((json) => DownloadedTrack.fromJson(json))
          .where((track) => File(track.filePath).existsSync())
          .toList();
    } catch (e) {
      print('Error loading downloaded tracks: $e');
      return [];
    }
  }

  Future<DownloadedTrack> downloadTrack(Video video, Function(double, String)? onProgress) async {
    // Check if download is already in progress
    if (_activeDownloads.containsKey(video.id)) {
      throw Exception('Download already in progress for this video');
    }

    // Check concurrent download limit
    if (_activeDownloads.length >= _maxConcurrentDownloads) {
      throw Exception('Maximum concurrent downloads reached. Please wait for other downloads to complete.');
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    final cancelToken = CancelToken();
    _activeDownloads[video.id] = cancelToken;
    
    try {
      // Show initial notification
      await NotificationService.showDownloadNotification(
        title: 'Downloading ${video.title}',
        body: 'Preparing download...',
        progress: 0,
        id: notificationId,
      );

      // Request storage permissions with proper handling
      onProgress?.call(0.1, 'Checking permissions...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 10,
        title: 'Downloading ${video.title}',
        body: 'Checking permissions...',
      );

      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        await NotificationService.cancelNotification(notificationId);
        throw Exception('Storage permission is required to download tracks. Please grant permission in settings.');
      }

      // Set up private download directory
      onProgress?.call(0.2, 'Setting up download...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 20,
        title: 'Downloading ${video.title}',
        body: 'Setting up download...',
      );

      // Use app's private directory to keep files hidden from Files app
      // This ensures downloaded content remains private and secure
      Directory downloadsDir;
      try {
        // Always use the app's private documents directory
        final appDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${appDir.path}/downloads');
      } catch (e) {
        // Fallback to app's private cache directory
        final cacheDir = await getTemporaryDirectory();
        downloadsDir = Directory('${cacheDir.path}/downloads');
      }
      
      // Create downloads directory if it doesn't exist
      // This directory is private and won't be visible in the device's Files app
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Get audio URL from Innertube API with retry mechanism
      onProgress?.call(0.3, 'Getting audio URL...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 30,
        title: 'Downloading ${video.title}',
        body: 'Getting audio URL...',
      );

      final audioUrl = await _getAudioUrlWithRetry(video.id);
      if (audioUrl == null) {
        await NotificationService.cancelNotification(notificationId);
        throw Exception('Could not get audio URL after multiple attempts');
      }

      // Create a unique filename
      final fileName = '${video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_${video.id}.mp3';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      // Download thumbnail in parallel with audio (if not cancelled)
      String thumbnailPath = video.thumbnail;
      if (!cancelToken.isCancelled) {
        try {
          final thumbnailFileName = '${video.id}_thumb.jpg';
          final thumbnailFilePath = '${downloadsDir.path}/$thumbnailFileName';
          await _downloadThumbnail(video.thumbnail, thumbnailFilePath);
          // Update thumbnailPath to point to local file
          thumbnailPath = thumbnailFilePath;
        } catch (e) {
          print('Error downloading thumbnail: $e');
          // Keep using the network URL if thumbnail download fails
        }
      }

      // Download the file with progress and retry mechanism
      onProgress?.call(0.4, 'Downloading file...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 40,
        title: 'Downloading ${video.title}',
        body: 'Downloading file...',
      );

      // Choose download method based on configuration
      if (_useResumableDownloads) {
        await _downloadFileResumable(audioUrl, filePath, cancelToken, (progress) {
          if (cancelToken.isCancelled) return;
          final actualProgress = 0.4 + (progress * 0.5); // 40% to 90%
          onProgress?.call(actualProgress, 'Downloading file...');
          NotificationService.updateDownloadProgress(
            id: notificationId,
            progress: (actualProgress * 100).toInt(),
            title: 'Downloading ${video.title}',
            body: 'Downloading file...',
          );
        });
      } else {
        await _downloadFileWithRetry(audioUrl, filePath, cancelToken, (progress) {
          if (cancelToken.isCancelled) return;
          final actualProgress = 0.4 + (progress * 0.5); // 40% to 90%
          onProgress?.call(actualProgress, 'Downloading file...');
          NotificationService.updateDownloadProgress(
            id: notificationId,
            progress: (actualProgress * 100).toInt(),
            title: 'Downloading ${video.title}',
            body: 'Downloading file...',
          );
        });
      }

      // Check if download was cancelled
      if (cancelToken.isCancelled) {
        throw Exception('Download was cancelled');
      }

      // Finalize download
      onProgress?.call(0.95, 'Finalizing download...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 95,
        title: 'Downloading ${video.title}',
        body: 'Finalizing download...',
      );

      final downloadedTrack = DownloadedTrack(
        id: video.id,
        title: video.title,
        author: video.author,
        thumbnail: thumbnailPath,
        filePath: filePath,
        fileSize: await file.length(),
        downloadedAt: DateTime.now(),
        duration: video.lengthSeconds,
      );

      // Save to shared preferences
      await _saveDownload(downloadedTrack);

      // Files are stored in private directory and won't be visible in Files app
      // This provides better privacy and security for downloaded content

      // Complete
      onProgress?.call(1.0, 'Download complete!');
      
      // Cancel the progress notification first
      await NotificationService.cancelNotification(notificationId);
      
      // Show completion notification briefly
      await NotificationService.showDownloadCompleteNotification(
        title: 'Download Complete',
        body: '${video.title} has been downloaded successfully',
        id: notificationId,
      );

      // Notify listeners that download is complete
      onDownloadComplete?.call(downloadedTrack);

      return downloadedTrack;
    } catch (e) {
      print('Error downloading track: $e');
      await NotificationService.cancelNotification(notificationId);
      
      // Notify listeners that download failed
      onDownloadFailed?.call(video.id);
      
      rethrow;
    } finally {
      // Clean up
      _activeDownloads.remove(video.id);
    }
  }

  // Cancel a specific download
  void cancelDownload(String videoId) {
    final cancelToken = _activeDownloads[videoId];
    if (cancelToken != null) {
      cancelToken.cancel('Download cancelled by user');
      _activeDownloads.remove(videoId);
    }
  }

  // Cancel all downloads
  void cancelAllDownloads() {
    for (final cancelToken in _activeDownloads.values) {
      cancelToken.cancel('All downloads cancelled');
    }
    _activeDownloads.clear();
  }
  
  // Pause a specific download
  void pauseDownload(String videoId) {
    final cancelToken = _activeDownloads[videoId];
    if (cancelToken != null) {
      cancelToken.cancel('Download paused by user');
      _activeDownloads.remove(videoId);
      // Note: We'll need to track the current position for resuming
      // This would require more complex state management
    }
  }
  
  // Resume a paused download
  Future<void> resumeDownload(String videoId, String url, String filePath, Function(double)? onProgress) async {
    if (_activeDownloads.containsKey(videoId)) {
      throw Exception('Download already in progress for this video');
    }
    
    if (_activeDownloads.length >= _maxConcurrentDownloads) {
      throw Exception('Maximum concurrent downloads reached. Please wait for other downloads to complete.');
    }
    
    final cancelToken = CancelToken();
    _activeDownloads[videoId] = cancelToken;
    
    try {
      // Resume from where we left off
      await _downloadFileResumable(url, filePath, cancelToken, onProgress);
    } catch (e) {
      _activeDownloads.remove(videoId);
      rethrow;
    }
  }
  
  // Get paused downloads
  List<String> get pausedDownloads => _pausedDownloads.keys.toList();
  
  // Get download queue status
  Map<String, dynamic> getDownloadQueueStatus() {
    return {
      'active': _activeDownloads.keys.toList(),
      'paused': _pausedDownloads.keys.toList(),
      'activeCount': _activeDownloads.length,
      'pausedCount': _pausedDownloads.length,
      'maxConcurrent': _maxConcurrentDownloads,
      'canStartNew': _activeDownloads.length < _maxConcurrentDownloads,
    };
  }
  
  // Clear all paused downloads
  void clearPausedDownloads() {
    _pausedDownloads.clear();
  }
  
  // Get download info for a specific video
  Map<String, dynamic>? getDownloadInfo(String videoId) {
    if (_activeDownloads.containsKey(videoId)) {
      return {
        'status': 'active',
        'videoId': videoId,
      };
    } else if (_pausedDownloads.containsKey(videoId)) {
      return {
        'status': 'paused',
        'videoId': videoId,
        'position': _pausedDownloads[videoId],
      };
    }
    return null;
  }
  
  // Get download progress for a specific video
  Map<String, dynamic>? getDownloadProgress(String videoId) {
    if (_activeDownloads.containsKey(videoId)) {
      return {
        'status': 'active',
        'videoId': videoId,
        'canCancel': true,
        'canPause': true,
      };
    } else if (_pausedDownloads.containsKey(videoId)) {
      return {
        'status': 'paused',
        'videoId': videoId,
        'position': _pausedDownloads[videoId],
        'canResume': true,
        'canCancel': true,
      };
    }
    return null;
  }

  // Get active download count
  int get activeDownloadCount => _activeDownloads.length;

  // Get max concurrent downloads
  int get maxConcurrentDownloads => _maxConcurrentDownloads;

  Future<bool> _requestStoragePermission() async {
    try {
      // First try to request storage permission
      PermissionStatus status = await Permission.storage.status;
      
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      
      if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        return await _showPermissionDialog();
      }
      
      if (status.isGranted) {
        return true;
      }
      
      // If storage permission is not available, try manage external storage
      status = await Permission.manageExternalStorage.status;
      
      if (status.isDenied) {
        status = await Permission.manageExternalStorage.request();
      }
      
      if (status.isPermanentlyDenied) {
        return await _showPermissionDialog();
      }
      
      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> _showPermissionDialog() async {
    // This would typically show a dialog, but since we're in a service,
    // we'll return false and let the UI handle the dialog
    return false;
  }

  Future<String?> _getAudioUrlWithRetry(String videoId, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final url = Config.youtubeApiUrl;
        
        final payload = {
          'context': {
            'client': {
              'clientName': 'ANDROID',
              'clientVersion': '19.17.34',
              'clientId': 3,
              'userAgent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36'
            }
          },
          'videoId': videoId
        };

        final headers = {
          'X-Goog-Api-Format-Version': '1',
          'X-YouTube-Client-Name': '3',
          'X-YouTube-Client-Version': '19.17.34',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Referer': 'https://www.youtube.com/',
          'Content-Type': 'application/json'
        };

        final response = await _dio.post(
          url, 
          data: payload, 
          options: Options(
            headers: headers,
            sendTimeout: Duration(seconds: 15),
            receiveTimeout: Duration(seconds: 30),
          )
        );
        
        if (response.statusCode == 200) {
          final data = response.data;
          final streamingData = data['streamingData'];
          
          if (streamingData != null) {
            final formats = streamingData['formats'] as List?;
            final adaptiveFormats = streamingData['adaptiveFormats'] as List?;
            
            // Look for audio-only format
            final audioFormats = <Map<String, dynamic>>[];
            
            if (formats != null) {
              audioFormats.addAll(formats.cast<Map<String, dynamic>>());
            }
            
            if (adaptiveFormats != null) {
              audioFormats.addAll(adaptiveFormats.cast<Map<String, dynamic>>());
            }
            
            // Find the best audio format (preferably with audio only and good quality)
            String? bestAudioUrl;
            int bestBitrate = 0;
            
            for (final format in audioFormats) {
              final mimeType = format['mimeType'] as String?;
              if (mimeType != null && mimeType.contains('audio/')) {
                final url = format['url'] as String?;
                final bitrate = format['bitrate'] as int? ?? 0;
                
                if (url != null) {
                  if (bitrate > bestBitrate) {
                    bestBitrate = bitrate;
                    bestAudioUrl = url;
                  }
                }
              }
            }
            
            if (bestAudioUrl != null) {
              return bestAudioUrl;
            }
            
            // If no audio-only format found, use the first available format
            for (final format in audioFormats) {
              final url = format['url'] as String?;
              if (url != null) {
                return url;
              }
            }
          }
        }
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      } catch (e) {
        print('Error getting audio URL (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      }
    }
    
    return null;
  }

  Future<void> _downloadFileWithRetry(String url, String filePath, CancelToken cancelToken, Function(double)? onProgress, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // First, get the total file size
        final headResponse = await _dio.head(
          url,
          options: Options(
            sendTimeout: Duration(seconds: _connectionTimeout),
            receiveTimeout: Duration(seconds: _connectionTimeout),
          ),
        );
        
        final totalBytes = headResponse.headers.value('content-length');
        final totalSize = totalBytes != null ? int.tryParse(totalBytes) ?? 0 : 0;
        
        // Download with Range header for better control
        await _dio.download(
          url,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (cancelToken.isCancelled) return;
            if (totalSize > 0) {
              final progress = received / totalSize;
              onProgress?.call(progress);
            } else if (total != -1) {
              final progress = received / total;
              onProgress?.call(progress);
            }
          },
          options: Options(
            sendTimeout: Duration(seconds: _connectionTimeout),
            receiveTimeout: Duration(seconds: _downloadTimeout),
            responseType: ResponseType.bytes,
            headers: {
              if (totalSize > 0) "Range": "bytes=0-$totalSize",
            },
          ),
        );
        return; // Success, exit retry loop
      } catch (e) {
        print('Error downloading file (attempt $attempt): $e');
        
        // Delete partial file if it exists
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        if (attempt < maxRetries && !cancelToken.isCancelled) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
  }

  // Resumable download method for large files
  Future<void> _downloadFileResumable(String url, String filePath, CancelToken cancelToken, Function(double)? onProgress, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if file exists and get its current size
        final file = File(filePath);
        int startByte = 0;
        
        if (await file.exists()) {
          startByte = await file.length();
          print('Resuming download from byte: $startByte');
        }
        
        // Get total file size
        final headResponse = await _dio.head(
          url,
          options: Options(
            sendTimeout: Duration(seconds: _connectionTimeout),
            receiveTimeout: Duration(seconds: _connectionTimeout),
          ),
        );
        
        final totalBytes = headResponse.headers.value('content-length');
        final totalSize = totalBytes != null ? int.tryParse(totalBytes) ?? 0 : 0;
        
        if (totalSize > 0 && startByte >= totalSize) {
          // File is already complete
          onProgress?.call(1.0);
          return;
        }
        
        // Download with Range header for resumable downloads
        await _dio.download(
          url,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (cancelToken.isCancelled) return;
            if (totalSize > 0) {
              final progress = (startByte + received) / totalSize;
              onProgress?.call(progress);
            } else if (total != -1) {
              final progress = (startByte + received) / (startByte + total);
              onProgress?.call(progress);
            }
          },
          options: Options(
            sendTimeout: Duration(seconds: _connectionTimeout),
            receiveTimeout: Duration(seconds: _downloadTimeout),
            responseType: ResponseType.bytes,
            headers: {
              if (startByte > 0 && totalSize > 0) "Range": "bytes=$startByte-$totalSize",
              if (startByte == 0 && totalSize > 0) "Range": "bytes=0-$totalSize",
            },
          ),
        );
        return; // Success, exit retry loop
      } catch (e) {
        print('Error downloading file (attempt $attempt): $e');
        
        // Don't delete the file on error for resumable downloads
        // Only delete if it's a new download (startByte == 0)
        if (attempt == 1) {
          final file = File(filePath);
          if (await file.exists() && await file.length() == 0) {
            await file.delete();
          }
        }
        
        if (attempt < maxRetries && !cancelToken.isCancelled) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
  }


  Future<void> _downloadThumbnail(String url, String filePath) async {
    try {
      // First, get the total file size
      final headResponse = await _dio.head(
        url,
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      
      final totalBytes = headResponse.headers.value('content-length');
      final totalSize = totalBytes != null ? int.tryParse(totalBytes) ?? 0 : 0;
      
      // Download with Range header for better control
      await _dio.download(
        url, 
        filePath,
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 30),
          responseType: ResponseType.bytes,
          headers: {
            if (totalSize > 0) "Range": "bytes=0-$totalSize",
          },
        ),
      );
      
      // Verify the file was downloaded successfully
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Thumbnail file not created or empty');
      }
    } catch (e) {
      print('Error downloading thumbnail: $e');
      rethrow;
    }
  }



  Future<void> _saveDownload(DownloadedTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    final tracksJson = prefs.getStringList(_downloadsKey) ?? [];
    tracksJson.add(track.toJson());
    await prefs.setStringList(_downloadsKey, tracksJson);
  }

  Future<void> _removeDownload(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final tracksJson = prefs.getStringList(_downloadsKey) ?? [];
    tracksJson.removeWhere((json) => json.contains('"id":"$trackId"'));
    await prefs.setStringList(_downloadsKey, tracksJson);
  }

  Future<bool> isDownloaded(String videoId) async {
    final tracks = await getDownloadedTracks();
    return tracks.any((track) => track.id == videoId);
  }

  Future<void> deleteDownload(String trackId) async {
    final tracks = await getDownloadedTracks();
    final track = tracks.firstWhere((t) => t.id == trackId);
    
    // Delete the audio file
    final file = File(track.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Delete the thumbnail file if it's a local file
    if (!track.thumbnail.startsWith('http')) {
      final thumbnailFile = File(track.thumbnail);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    }
    
    // Remove from shared preferences
    await _removeDownload(trackId);
  }

  // Get the private download directory path for informational purposes
  Future<String> getDownloadDirectoryPath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/downloads';
    } catch (e) {
      final cacheDir = await getTemporaryDirectory();
      return '${cacheDir.path}/downloads';
    }
  }

  // Check if downloads are stored privately (not in public directory)
  bool get isPrivateStorage => true;

  // Get storage info for user information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final downloadsDir = Directory(await getDownloadDirectoryPath());
      if (await downloadsDir.exists()) {
        final files = downloadsDir.listSync();
        int totalSize = 0;
        int fileCount = 0;
        
        for (final entity in files) {
          if (entity is File) {
            totalSize += await entity.length();
            fileCount++;
          }
        }
        
        return {
          'isPrivate': true,
          'fileCount': fileCount,
          'totalSize': totalSize,
          'directory': await getDownloadDirectoryPath(),
        };
      }
      return {
        'isPrivate': true,
        'fileCount': 0,
        'totalSize': 0,
        'directory': await getDownloadDirectoryPath(),
      };
    } catch (e) {
      return {
        'isPrivate': true,
        'fileCount': 0,
        'totalSize': 0,
        'directory': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  // Fix existing downloads that have network thumbnail URLs
  Future<void> fixExistingThumbnails() async {
    try {
      final tracks = await getDownloadedTracks();
      final tracksToUpdate = <DownloadedTrack>[];
      
      for (final track in tracks) {
        if (track.thumbnail.startsWith('http')) {
          print('Fixing thumbnail for track: ${track.title}');
          try {
            final downloadsDir = await getDownloadDirectoryPath();
            final thumbnailFileName = '${track.id}_thumb.jpg';
            final thumbnailFilePath = '$downloadsDir/$thumbnailFileName';
            
            await _downloadThumbnail(track.thumbnail, thumbnailFilePath);
            
            // Create updated track with local thumbnail
            final updatedTrack = DownloadedTrack(
              id: track.id,
              title: track.title,
              author: track.author,
              thumbnail: thumbnailFilePath,
              filePath: track.filePath,
              fileSize: track.fileSize,
              downloadedAt: track.downloadedAt,
              duration: track.duration,
            );
            
            tracksToUpdate.add(updatedTrack);
            print('Fixed thumbnail for track: ${track.title}');
          } catch (e) {
            print('Failed to fix thumbnail for track ${track.title}: $e');
          }
        }
      }
      
      // Update shared preferences with fixed tracks
      if (tracksToUpdate.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final allTracks = tracks.where((t) => !t.thumbnail.startsWith('http')).toList();
        allTracks.addAll(tracksToUpdate);
        
        final tracksJson = allTracks.map((t) => t.toJson()).toList();
        await prefs.setStringList(_downloadsKey, tracksJson);
        print('Updated ${tracksToUpdate.length} tracks with local thumbnails');
      }
    } catch (e) {
      print('Error fixing existing thumbnails: $e');
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    cancelAllDownloads();
    _dio.close();
  }
}
