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
      primary: spotifyGreen,
      onPrimary: spotifyBlack,
      secondary: spotifyDarkGreen,
      onSecondary: spotifyBlack,
      surface: spotifyBlack,
      onSurface: spotifyWhite,
      background: spotifyBlack,
      onBackground: spotifyWhite,
      surfaceContainerLow: spotifyDarkGrey,
      surfaceContainerHigh: spotifyMediumGrey,
      outline: spotifyMediumGrey,
      outlineVariant: spotifyLightGrey,
    ),
    scaffoldBackgroundColor:
        Platform.isWindows ? Colors.transparent : spotifyBlack,
    primaryColor: spotifyGreen,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
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
      color: spotifyDarkGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: spotifyGreen,
        foregroundColor: spotifyBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: spotifyWhite,
      ),
    ),
    iconTheme: const IconThemeData(
      color: spotifyWhite,
    ),
    textTheme: TextTheme(
      headlineLarge: defaultFontStyle.copyWith(color: spotifyWhite),
      headlineMedium: defaultFontStyle.copyWith(color: spotifyWhite),
      headlineSmall: defaultFontStyle.copyWith(color: spotifyWhite),
      bodyLarge: defaultFontStyle.copyWith(color: spotifyWhite),
      bodyMedium: defaultFontStyle.copyWith(color: spotifyWhite),
      bodySmall: defaultFontStyle.copyWith(color: spotifyLightGrey),
      displayLarge: defaultFontStyle.copyWith(color: spotifyWhite),
      displayMedium: defaultFontStyle.copyWith(color: spotifyWhite),
      displaySmall: defaultFontStyle.copyWith(color: spotifyWhite),
      titleLarge: defaultFontStyle.copyWith(color: spotifyWhite),
      titleMedium: defaultFontStyle.copyWith(color: spotifyWhite),
      titleSmall: defaultFontStyle.copyWith(color: spotifyWhite),
      labelLarge: defaultFontStyle.copyWith(color: spotifyWhite),
      labelMedium: defaultFontStyle.copyWith(color: spotifyWhite),
      labelSmall: defaultFontStyle.copyWith(color: spotifyLightGrey),
    ),
  );
}
