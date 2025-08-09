import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../models/download_item.dart';
import '../models/downloaded_track.dart';
import '../services/download_service.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/download_progress_dialog.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  
  List<DownloadItem> _downloads = [];
  List<DownloadedTrack> _downloadedTracks = [];
  bool _isLoading = false;
  LibraryProvider? _libraryProvider;

  List<DownloadItem> get downloads => _downloads;
  List<DownloadedTrack> get downloadedTracks => _downloadedTracks;
  bool get isLoading => _isLoading;
  
  Future<List<DownloadedTrack>> getDownloadedTracks() async {
    return await _downloadService.getDownloadedTracks();
  }

  Future<void> loadDownloadedTracks() async {
    try {
      _downloadedTracks = await _downloadService.getDownloadedTracks();
      notifyListeners();
    } catch (e) {
      print('Error loading downloaded tracks: $e');
    }
  }

  Future<void> startDownload(Video video, BuildContext context) async {
    // Check if already downloading
    if (_downloads.any((d) => d.video.id == video.id && d.status == DownloadStatus.downloading)) {
      return;
    }

    final downloadItem = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      video: video,
      status: DownloadStatus.downloading,
      progress: 0.0,
    );

    _downloads.add(downloadItem);
    notifyListeners();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final dialogKey = GlobalKey<DownloadProgressDialogState>();
    if (settings.showDownloadPopup) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DownloadProgressDialog(
            key: dialogKey,
            title: video.title,
            author: video.author,
            onCancel: () {
              Navigator.of(context).pop();
              cancelDownload(downloadItem.id);
            },
          );
        },
      );
    }

    try {
      await _downloadService.downloadTrack(video, (progress, status) {
        _updateProgress(downloadItem.id, progress);
        
        // Update progress dialog
        final dialogState = dialogKey.currentState;
        if (settings.showDownloadPopup && dialogState != null && dialogState.mounted) {
          dialogState.updateProgress(progress, status);
        }
      });
      
      _updateStatus(downloadItem.id, DownloadStatus.completed);
      
      // Reload downloaded tracks to update the UI
      await loadDownloadedTracks();
      
      // Notify library provider to refresh
      if (_libraryProvider != null) {
        _libraryProvider!.refreshDownloads();
      }
      
      // Close progress dialog
      final dialogState = dialogKey.currentState;
      if (settings.showDownloadPopup && dialogState != null && dialogState.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${video.title} downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Download failed: $e');
      _updateStatus(downloadItem.id, DownloadStatus.failed);
      
      // Close progress dialog
      final dialogState = dialogKey.currentState;
      if (settings.showDownloadPopup && dialogState != null && dialogState.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Show permission dialog if permission is denied
      if (e.toString().contains('permission')) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionDialog(),
        );
        
        if (shouldOpenSettings == true) {
          // User chose to open settings
          print('User opened settings');
        }
      }
    }
  }

  void _updateProgress(String id, double progress) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index] = _downloads[index].copyWith(progress: progress);
      notifyListeners();
    }
  }

  void _updateStatus(String id, DownloadStatus status) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index] = _downloads[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void cancelDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads.removeAt(index);
      notifyListeners();
    }
  }

  void removeDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads.removeAt(index);
      notifyListeners();
    }
  }

  bool isDownloading(String videoId) {
    return _downloads.any((d) => d.video.id == videoId && d.status == DownloadStatus.downloading);
  }

  bool isDownloaded(String videoId) {
    // First check if it's in our memory state
    final inMemory = _downloads.any((d) => d.video.id == videoId && d.status == DownloadStatus.completed);
    if (inMemory) return true;
    
    // If not in memory, check our loaded downloaded tracks
    return _downloadedTracks.any((track) => track.id == videoId);
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }
}
