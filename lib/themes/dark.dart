import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// ColorScheme.fromSeed(
//             seedColor: accentColor,
//             brightness: darkScheme.brightness,
//             primary: accentColor,
//             primaryContainer: accentColor,
//             onPrimaryContainer: Colors.black,
//             surface: accentColor.withAlpha(10),
//           )
final defaultFontStyle = GoogleFonts.poppins();
ColorScheme darkScheme = const ColorScheme.dark();
ThemeData darkTheme({required ColorScheme colorScheme}) {
  return ThemeData.dark().copyWith(
    colorScheme: colorScheme.copyWith(
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      surface: colorScheme.surface,
      onSurface: colorScheme.onSurface,
      background: colorScheme.background,
      onBackground: colorScheme.onBackground,
      surfaceContainerLow: colorScheme.surfaceContainerLow,
      surfaceContainerHigh: colorScheme.surfaceContainerHigh,
      outline: colorScheme.outline,
      outlineVariant: colorScheme.outlineVariant,
    ),
    scaffoldBackgroundColor:
        Platform.isWindows ? Colors.transparent : colorScheme.primary.withOpacity(0.1),
    primaryColor: colorScheme.primary,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.primary.withOpacity(0.05),
      surfaceTintColor: Platform.isWindows ? Colors.transparent : null,
      foregroundColor: spotifyWhite,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.primary.withOpacity(0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
      ),
    ),
    iconTheme: IconThemeData(
      color: colorScheme.onSurface,
    ),
    textTheme: TextTheme(
      headlineLarge: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      headlineMedium: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      headlineSmall: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      bodyLarge: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      bodyMedium: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      bodySmall: defaultFontStyle.copyWith(color: colorScheme.onSurfaceVariant),
      displayLarge: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      displayMedium: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      displaySmall: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      titleLarge: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      titleMedium: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      titleSmall: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      labelLarge: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      labelMedium: defaultFontStyle.copyWith(color: colorScheme.onSurface),
      labelSmall: defaultFontStyle.copyWith(color: colorScheme.onSurfaceVariant),
    ),
  );
}
