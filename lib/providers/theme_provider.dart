import 'package:flutter/material.dart';
import '../services/color_extractor.dart';

class ThemeProvider with ChangeNotifier {
  Color _accentColor = Colors.red;
  Color _primaryColor = Colors.red;
  bool _isUpdating = false;
  String? _lastThumbnailUrl;

  Color get accentColor => _accentColor;
  Color get primaryColor => _primaryColor;
  bool get isUpdating => _isUpdating;
  String? get lastThumbnailUrl => _lastThumbnailUrl;

  Future<void> updateAccentColorFromThumbnail(String thumbnailUrl) async {
    if (_isUpdating) {
      print('ThemeProvider: Already updating, skipping...');
      return;
    }

    if (thumbnailUrl.isEmpty) {
      print('ThemeProvider: Empty thumbnail URL, skipping...');
      return;
    }

    // Check if this is the same thumbnail we're already using
    if (_lastThumbnailUrl == thumbnailUrl) {
      print('ThemeProvider: Same thumbnail URL, skipping update...');
      return;
    }

    try {
      _isUpdating = true;
      print('ThemeProvider: Extracting color from thumbnail: $thumbnailUrl');
      
      final newAccentColor = await ColorExtractor.extractDominantColor(thumbnailUrl);
      print('ThemeProvider: Extracted color: $newAccentColor');
      
      // Only update if the color is significantly different
      if (_shouldUpdateColor(newAccentColor)) {
        print('ThemeProvider: Color is significantly different, updating...');
        _accentColor = newAccentColor;
        _primaryColor = newAccentColor;
        _lastThumbnailUrl = thumbnailUrl;
        print('ThemeProvider: Updated accent color to: $_accentColor');
        notifyListeners();
        print('ThemeProvider: Notified listeners');
      } else {
        print('ThemeProvider: Color is similar, not updating');
        // Still update the last thumbnail URL to avoid repeated processing
        _lastThumbnailUrl = thumbnailUrl;
      }
    } catch (e) {
      print('Error updating accent color: $e');
      // Don't update colors on error, keep current ones
    } finally {
      _isUpdating = false;
    }
  }

  bool _shouldUpdateColor(Color newColor) {
    // Check if the new color is significantly different from current
    final currentHsv = HSVColor.fromColor(_accentColor);
    final newHsv = HSVColor.fromColor(newColor);
    
    // Update if hue difference is more than 20 degrees (reduced threshold)
    final hueDifference = (currentHsv.hue - newHsv.hue).abs();
    if (hueDifference > 20) {
      print('ThemeProvider: Hue difference ($hueDifference) > 20, updating');
      return true;
    }
    
    // Update if saturation difference is more than 0.15 (reduced threshold)
    final saturationDifference = (currentHsv.saturation - newHsv.saturation).abs();
    if (saturationDifference > 0.15) {
      print('ThemeProvider: Saturation difference ($saturationDifference) > 0.15, updating');
      return true;
    }
    
    // Update if value (brightness) difference is more than 0.2
    final valueDifference = (currentHsv.value - newHsv.value).abs();
    if (valueDifference > 0.2) {
      print('ThemeProvider: Value difference ($valueDifference) > 0.2, updating');
      return true;
    }
    
    print('ThemeProvider: Color is similar, not updating');
    return false;
  }

  void resetToDefaultColor() {
    print('ThemeProvider: Resetting to default color');
    _accentColor = Colors.red;
    _primaryColor = Colors.red;
    _lastThumbnailUrl = null;
    notifyListeners();
  }

  void setCustomColor(Color color) {
    print('ThemeProvider: Setting custom color: $color');
    _accentColor = color;
    _primaryColor = color;
    _lastThumbnailUrl = null;
    notifyListeners();
  }

  Future<void> forceUpdateFromThumbnail(String thumbnailUrl) async {
    print('ThemeProvider: Force updating from thumbnail: $thumbnailUrl');
    _lastThumbnailUrl = null; // Reset to force update
    await updateAccentColorFromThumbnail(thumbnailUrl);
  }

  void clearCache() {
    print('ThemeProvider: Clearing color cache');
    ColorExtractor.clearCache();
  }

  void clearFailedExtractions() {
    print('ThemeProvider: Clearing failed extractions');
    ColorExtractor.clearFailedExtractions();
  }
}
