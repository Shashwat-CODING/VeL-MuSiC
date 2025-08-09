import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RepeatMode { none, one, all }

class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _autoPlayKey = 'auto_play';
  static const String _repeatModeKey = 'repeat_mode';
  static const String _downloadQualityKey = 'download_quality';
  static const String _downloadLocationKey = 'download_location';
  static const String _showDownloadPopupKey = 'show_download_popup';

  ThemeMode _themeMode = ThemeMode.system;
  bool _autoPlay = true;
  RepeatMode _repeatMode = RepeatMode.none;
  int _downloadQuality = 192;
  String _downloadLocation = '/storage/emulated/0/Music/Udio-YT';
  bool _showDownloadPopup = true;

  ThemeMode get themeMode => _themeMode;
  bool get autoPlay => _autoPlay;
  RepeatMode get repeatMode => _repeatMode;
  int get downloadQuality => _downloadQuality;
  String get downloadLocation => _downloadLocation;
  bool get showDownloadPopup => _showDownloadPopup;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      
      _autoPlay = prefs.getBool(_autoPlayKey) ?? true;
      
      final repeatIndex = prefs.getInt(_repeatModeKey) ?? 0;
      _repeatMode = RepeatMode.values[repeatIndex];
      
      _downloadQuality = prefs.getInt(_downloadQualityKey) ?? 192;
      _downloadLocation = prefs.getString(_downloadLocationKey) ?? '/storage/emulated/0/Music/Udio-YT';
      _showDownloadPopup = prefs.getBool(_showDownloadPopupKey) ?? true;
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayKey, value);
    notifyListeners();
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repeatModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setDownloadQuality(int quality) async {
    _downloadQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_downloadQualityKey, quality);
    notifyListeners();
  }

  Future<void> setDownloadLocation(String location) async {
    _downloadLocation = location;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadLocationKey, location);
    notifyListeners();
  }

  Future<void> setShowDownloadPopup(bool value) async {
    _showDownloadPopup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDownloadPopupKey, value);
    notifyListeners();
  }
}
