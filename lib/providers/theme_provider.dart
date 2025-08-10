import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  Color _accentColor = Colors.grey[400]!;
  Color _primaryColor = Colors.grey[400]!;
  bool _isDarkMode = true; // Default to dark mode
  ThemeMode _systemThemeMode = ThemeMode.system;

  Color get accentColor => _accentColor;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get systemThemeMode => _systemThemeMode;

  // Update system theme mode and recalculate isDarkMode
  void updateSystemThemeMode(ThemeMode mode) {
    _systemThemeMode = mode;
    _updateIsDarkMode();
    notifyListeners();
  }

  // Update isDarkMode based on system theme mode
  void _updateIsDarkMode() {
    switch (_systemThemeMode) {
      case ThemeMode.light:
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        _isDarkMode = true;
        break;
      case ThemeMode.system:
        // Get system brightness
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
        break;
    }
  }

  // Set theme mode (dark/light)
  void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
    // Force immediate rebuild of all widgets
    notifyListeners();
  }

  // Toggle between dark and light mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    // Force immediate rebuild of all widgets
    notifyListeners();
  }

  // Get background color based on theme mode
  Color getBackgroundColor() {
    if (_isDarkMode) {
      return Colors.black;
    } else {
      // Use a very light, warm color for light theme
      return const Color(0xFFFAFAFA);
    }
  }

  // Get surface color based on theme mode
  Color getSurfaceColor() {
    if (_isDarkMode) {
      return Colors.grey[900]!;
    } else {
      // Use a light surface color for light theme
      return const Color(0xFFF5F5F5);
    }
  }

  // Get text color based on theme mode
  Color getTextColor() {
    if (_isDarkMode) {
      return Colors.white;
    } else {
      return const Color(0xFF1A1A1A);
    }
  }

  // Get secondary text color based on theme mode
  Color getSecondaryTextColor() {
    if (_isDarkMode) {
      return Colors.grey[400]!;
    } else {
      return const Color(0xFF666666);
    }
  }

  // Get tertiary text color based on theme mode
  Color getTertiaryTextColor() {
    if (_isDarkMode) {
      return Colors.grey[500]!;
    } else {
      return const Color(0xFF888888);
    }
  }

  // Get placeholder/disabled color based on theme mode
  Color getPlaceholderColor() {
    if (_isDarkMode) {
      return Colors.grey[600]!;
    } else {
      return const Color(0xFFCCCCCC);
    }
  }

  // Get shimmer base color based on theme mode
  Color getShimmerBaseColor() {
    if (_isDarkMode) {
      return Colors.grey[800]!;
    } else {
      return Colors.grey[300]!;
    }
  }

  // Get shimmer highlight color based on theme mode
  Color getShimmerHighlightColor() {
    if (_isDarkMode) {
      return Colors.grey[700]!;
    } else {
      return Colors.grey[100]!;
    }
  }

  // Get error icon color based on theme mode
  Color getErrorIconColor() {
    if (_isDarkMode) {
      return Colors.grey[400]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  // Get error text color based on theme mode
  Color getErrorTextColor() {
    if (_isDarkMode) {
      return Colors.grey[500]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  // Get error title color based on theme mode
  Color getErrorTitleColor() {
    if (_isDarkMode) {
      return Colors.grey[400]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  // Mix accent color with theme-appropriate base color
  Color getMixedAccentColor() {
    if (_isDarkMode) {
      // Mix with black for dark theme
      return Color.lerp(_accentColor, Colors.black, 0.3)!;
    } else {
      // Mix with white for light theme
      return Color.lerp(_accentColor, Colors.white, 0.3)!;
    }
  }

  // Set accent color (for manual color selection)
  void setAccentColor(Color color) {
    _accentColor = color;
    _primaryColor = color;
    // Force immediate rebuild of all widgets
    notifyListeners();
  }

  // Reset to default colors
  void resetToDefault() {
    _accentColor = Colors.grey[400]!;
    _primaryColor = Colors.grey[400]!;
    // Force immediate rebuild of all widgets
    notifyListeners();
  }

  // Get card background color for light theme
  Color getCardBackgroundColor() {
    if (_isDarkMode) {
      return Colors.grey[850]!;
    } else {
      return Colors.white;
    }
  }

  // Get divider color based on theme
  Color getDividerColor() {
    if (_isDarkMode) {
      return Colors.grey[700]!;
    } else {
      return const Color(0xFFE0E0E0);
    }
  }

  // Get shadow color based on theme
  Color getShadowColor() {
    if (_isDarkMode) {
      return Colors.black.withOpacity(0.3);
    } else {
      return Colors.black.withOpacity(0.08);
    }
  }

  // Get gradient colors for light theme
  List<Color> getGradientColors() {
    if (_isDarkMode) {
      return [
        _primaryColor.withOpacity(0.8),
        _primaryColor.withOpacity(0.6),
        getBackgroundColor().withOpacity(0.9),
      ];
    } else {
      return [
        const Color(0xFFF8F9FA), // Very light blue-gray
        const Color(0xFFE9ECEF), // Light blue-gray
        const Color(0xFFFAFAFA), // Light warm background
      ];
    }
  }

  // Get a more prominent background color for light mode
  Color getProminentBackgroundColor() {
    if (_isDarkMode) {
      return Colors.black;
    } else {
      return const Color(0xFFF0F2F5); // Light blue-gray, more visible than FAFAFA
    }
  }
}
