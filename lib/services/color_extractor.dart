import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:http/http.dart' as http;

class ColorExtractor {
  static final Map<String, Color> _colorCache = {};
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static Future<Color> extractDominantColor(String imageUrl) async {
    print('ColorExtractor: Starting color extraction for: $imageUrl');
    
    // Check cache first
    if (_colorCache.containsKey(imageUrl)) {
      print('ColorExtractor: Found cached color: ${_colorCache[imageUrl]}');
      return _colorCache[imageUrl]!;
    }

    // Try multiple times with delay to ensure image is loaded
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('ColorExtractor: Attempt $attempt of $_maxRetries');
        
        PaletteGenerator paletteGenerator;
        
        if (imageUrl.startsWith('http')) {
          print('ColorExtractor: Processing network image');
          // Network image - add delay to ensure it's loaded
          if (attempt > 1) {
            await Future.delayed(_retryDelay);
          }
          
          paletteGenerator = await PaletteGenerator.fromImageProvider(
            NetworkImage(imageUrl),
          );
        } else {
          print('ColorExtractor: Processing local file');
          // Local file
          final file = File(imageUrl);
          if (await file.exists()) {
            paletteGenerator = await PaletteGenerator.fromImageProvider(
              FileImage(file),
            );
          } else {
            print('ColorExtractor: File does not exist, returning default color');
            return _getDefaultAccentColor();
          }
        }

        // Verify we got a valid palette
        if (paletteGenerator.colors.isEmpty) {
          print('ColorExtractor: Empty palette, retrying...');
          if (attempt < _maxRetries) continue;
          return _getDefaultAccentColor();
        }

        // Try to get the most vibrant color from the palette
        Color dominantColor = _getBestColorFromPalette(paletteGenerator);
        print('ColorExtractor: Extracted dominant color: $dominantColor');
        
        // Cache the result
        _colorCache[imageUrl] = dominantColor;
        print('ColorExtractor: Cached color for: $imageUrl');
        
        return dominantColor;
        
      } catch (e) {
        print('ColorExtractor: Error on attempt $attempt: $e');
        if (attempt < _maxRetries) {
          print('ColorExtractor: Retrying in ${_retryDelay.inMilliseconds}ms...');
          await Future.delayed(_retryDelay);
        } else {
          print('ColorExtractor: All attempts failed, returning default color');
          // Cache the default color to avoid repeated failures
          _colorCache[imageUrl] = _getDefaultAccentColor();
          return _getDefaultAccentColor();
        }
      }
    }
    
    return _getDefaultAccentColor();
  }

  static Color _getBestColorFromPalette(PaletteGenerator paletteGenerator) {
    // Try to get the most vibrant color from the palette
    // Priority: dominant > most saturated > first available
    
    if (paletteGenerator.dominantColor != null) {
      return paletteGenerator.dominantColor!.color;
    }
    
    // Try to find a vibrant color from the palette
    if (paletteGenerator.colors.isNotEmpty) {
      // Find the most saturated color
      Color mostVibrant = paletteGenerator.colors.first;
      double maxSaturation = 0.0;
      
      for (final color in paletteGenerator.colors) {
        final hsv = HSVColor.fromColor(color);
        if (hsv.saturation > maxSaturation) {
          maxSaturation = hsv.saturation;
          mostVibrant = color;
        }
      }
      
      // Only return the most saturated if it's reasonably saturated
      if (maxSaturation > 0.3) {
        return mostVibrant;
      }
      
      // Otherwise return the first color
      return paletteGenerator.colors.first;
    }
    
    // Fallback to a default color
    return _getDefaultAccentColor();
  }

  static Color _getDefaultAccentColor() {
    return Colors.red;
  }

  static void clearCache() {
    _colorCache.clear();
  }

  static void removeFromCache(String imageUrl) {
    _colorCache.remove(imageUrl);
  }

  static void clearFailedExtractions() {
    // Remove any cached default colors (failed extractions)
    final keysToRemove = <String>[];
    for (final entry in _colorCache.entries) {
      if (entry.value == _getDefaultAccentColor()) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _colorCache.remove(key);
    }
    print('ColorExtractor: Cleared ${keysToRemove.length} failed extractions from cache');
  }
}
