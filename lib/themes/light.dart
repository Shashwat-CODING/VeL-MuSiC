import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

final defaultFontStyle = GoogleFonts.poppins();

ThemeData lightTheme({required ColorScheme colorScheme}) {
  return ThemeData.light().copyWith(
    colorScheme: colorScheme.copyWith(
      primary: spotifyGreen,
      onPrimary: spotifyWhite,
      secondary: spotifyDarkGreen,
      onSecondary: spotifyWhite,
      surface: spotifyWhite,
      onSurface: spotifyBlack,
      background: spotifyWhite,
      onBackground: spotifyBlack,
      surfaceContainerLow: const Color(0xFFF5F5F5),
      surfaceContainerHigh: const Color(0xFFE0E0E0),
      outline: spotifyMediumGrey,
      outlineVariant: spotifyLightGrey,
    ),
    primaryColor: spotifyGreen,
    scaffoldBackgroundColor:
        Platform.isWindows ? Colors.transparent : spotifyWhite,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      surfaceTintColor: Platform.isWindows ? Colors.transparent : null,
      foregroundColor: spotifyBlack,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF5F5F5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: spotifyGreen,
        foregroundColor: spotifyWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: spotifyBlack,
      ),
    ),
    iconTheme: const IconThemeData(
      color: spotifyBlack,
    ),
    textTheme: TextTheme(
      headlineLarge: defaultFontStyle.copyWith(color: spotifyBlack),
      headlineMedium: defaultFontStyle.copyWith(color: spotifyBlack),
      headlineSmall: defaultFontStyle.copyWith(color: spotifyBlack),
      bodyLarge: defaultFontStyle.copyWith(color: spotifyBlack),
      bodyMedium: defaultFontStyle.copyWith(color: spotifyBlack),
      bodySmall: defaultFontStyle.copyWith(color: spotifyMediumGrey),
      displayLarge: defaultFontStyle.copyWith(color: spotifyBlack),
      displayMedium: defaultFontStyle.copyWith(color: spotifyBlack),
      displaySmall: defaultFontStyle.copyWith(color: spotifyBlack),
      titleLarge: defaultFontStyle.copyWith(color: spotifyBlack),
      titleMedium: defaultFontStyle.copyWith(color: spotifyBlack),
      titleSmall: defaultFontStyle.copyWith(color: spotifyBlack),
      labelLarge: defaultFontStyle.copyWith(color: spotifyBlack),
      labelMedium: defaultFontStyle.copyWith(color: spotifyBlack),
      labelSmall: defaultFontStyle.copyWith(color: spotifyMediumGrey),
    ),
  );
}
