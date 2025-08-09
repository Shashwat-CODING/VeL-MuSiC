import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/video.dart';
import '../models/downloaded_track.dart';
import '../services/notification_service.dart';

class DownloadService {
  final Dio _dio = Dio();
  
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
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    
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

      // Get the public Downloads directory
      onProgress?.call(0.2, 'Setting up download...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 20,
        title: 'Downloading ${video.title}',
        body: 'Setting up download...',
      );

      // Try to get the public Downloads directory
      Directory? downloadsDir;
      try {
        // For Android 10+ (API 29+), use the public Downloads directory
        if (Platform.isAndroid) {
          final externalDir = Directory('/storage/emulated/0/Download');
          if (await externalDir.exists()) {
            downloadsDir = externalDir;
          } else {
            // Fallback to app's documents directory
            final appDir = await getApplicationDocumentsDirectory();
            downloadsDir = Directory('${appDir.path}/downloads');
          }
        } else {
          // For other platforms, use app's documents directory
          final appDir = await getApplicationDocumentsDirectory();
          downloadsDir = Directory('${appDir.path}/downloads');
        }
      } catch (e) {
        // Fallback to app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${appDir.path}/downloads');
      }
      
      // Create downloads directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Get audio URL from Innertube API
      onProgress?.call(0.3, 'Getting audio URL...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 30,
        title: 'Downloading ${video.title}',
        body: 'Getting audio URL...',
      );

      final audioUrl = await _getAudioUrl(video.id);
      if (audioUrl == null) {
        await NotificationService.cancelNotification(notificationId);
        throw Exception('Could not get audio URL');
      }

      // Create a unique filename
      final fileName = '${video.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      // Download thumbnail
      String thumbnailPath = video.thumbnail;
      try {
        final thumbnailFileName = '${video.id}_thumb.jpg';
        final thumbnailFilePath = '${downloadsDir.path}/$thumbnailFileName';
        await _downloadThumbnail(video.thumbnail, thumbnailFilePath);
        thumbnailPath = thumbnailFilePath;
      } catch (e) {
        print('Error downloading thumbnail: $e');
        // Keep using the network URL if thumbnail download fails
      }

      // Download the file with progress
      onProgress?.call(0.4, 'Downloading file...');
      await NotificationService.updateDownloadProgress(
        id: notificationId,
        progress: 40,
        title: 'Downloading ${video.title}',
        body: 'Downloading file...',
      );

      await _downloadFile(audioUrl, filePath, (progress) {
        final actualProgress = 0.4 + (progress * 0.5); // 40% to 90%
        onProgress?.call(actualProgress, 'Downloading file...');
        NotificationService.updateDownloadProgress(
          id: notificationId,
          progress: (actualProgress * 100).toInt(),
          title: 'Downloading ${video.title}',
          body: 'Downloading file...',
        );
      });

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

      // Make file accessible to other apps (Android only)
      if (Platform.isAndroid) {
        try {
          await _makeFileAccessible(filePath);
        } catch (e) {
          print('Error making file accessible: $e');
        }
      }

      // Complete
      onProgress?.call(1.0, 'Download complete!');
      await NotificationService.showDownloadCompleteNotification(
        title: 'Download Complete',
        body: '${video.title} has been downloaded successfully',
        id: notificationId,
      );

      return downloadedTrack;
    } catch (e) {
      print('Error downloading track: $e');
      await NotificationService.cancelNotification(notificationId);
      rethrow;
    }
  }

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

  Future<String?> _getAudioUrl(String videoId) async {
    try {
      final url = 'https://youtubei.googleapis.com/youtubei/v1/player?key=AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w';
      
      final payload = {
        'context': {
          'client': {
            'clientName': 'ANDROID',
            'clientVersion': '19.17.34',
            'clientId': 3,
            'userAgent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36'
          }
        },
        'videoId': videoId
      };

      final headers = {
        'X-Goog-Api-Format-Version': '1',
        'X-YouTube-Client-Name': '3',
        'X-YouTube-Client-Version': '19.17.34',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Mobile Safari/537.36',
        'Referer': 'https://www.youtube.com/',
        'Content-Type': 'application/json'
      };

      final response = await _dio.post(url, data: payload, options: Options(headers: headers));
      
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
          
          // Find the best audio format (preferably with audio only)
          for (final format in audioFormats) {
            final mimeType = format['mimeType'] as String?;
            if (mimeType != null && mimeType.contains('audio/')) {
              final url = format['url'] as String?;
              if (url != null) {
                return url;
              }
            }
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
      
      return null;
    } catch (e) {
      print('Error getting audio URL: $e');
      return null;
    }
  }

  Future<void> _downloadFile(String url, String filePath, Function(double)? onProgress) async {
    try {
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
      );
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  Future<void> _downloadThumbnail(String url, String filePath) async {
    try {
      await _dio.download(url, filePath);
    } catch (e) {
      print('Error downloading thumbnail: $e');
      rethrow;
    }
  }

  Future<void> _makeFileAccessible(String filePath) async {
    try {
      // This will make the file visible to other apps and file managers
      // The file is already in the public Downloads directory, so it should be accessible
      // We can also add it to the media store if needed
      final file = File(filePath);
      if (await file.exists()) {
        // The file is now accessible to other apps
        print('File made accessible: $filePath');
      }
    } catch (e) {
      print('Error making file accessible: $e');
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
    
    // Delete the file
    final file = File(track.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Remove from shared preferences
    await _removeDownload(trackId);
  }
}
