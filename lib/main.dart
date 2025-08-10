import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/music_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/download_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize just_audio_background
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.udio.yt.channel.audio',
    androidNotificationChannelName: 'VeL-MuSiC Audio playback',
    androidNotificationOngoing: true,
  );
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(const UdioYTApp());
}

class UdioYTApp extends StatelessWidget {
  const UdioYTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => MusicProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => DownloadProvider()),
      ],
      child: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settingsProvider, themeProvider, child) {
          // Update ThemeProvider when settings change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeProvider.updateSystemThemeMode(settingsProvider.themeMode);
          });
          
          return MaterialApp(
            title: 'VeL-MuSiC',
            themeMode: settingsProvider.themeMode,
            theme: ThemeData(
              primaryColor: themeProvider.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                brightness: Brightness.light,
                surface: themeProvider.getSurfaceColor(),
                background: themeProvider.getBackgroundColor(),
                onBackground: themeProvider.getTextColor(),
                onSurface: themeProvider.getTextColor(),
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              cardTheme: CardThemeData(
                color: themeProvider.getCardBackgroundColor(),
                elevation: 2,
                shadowColor: themeProvider.getShadowColor(),
              ),
              scaffoldBackgroundColor: themeProvider.getProminentBackgroundColor(),
              dividerColor: themeProvider.getDividerColor(),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: themeProvider.getTextColor()),
                bodyMedium: TextStyle(color: themeProvider.getTextColor()),
                bodySmall: TextStyle(color: themeProvider.getSecondaryTextColor()),
              ),
            ),
            darkTheme: ThemeData(
              primaryColor: themeProvider.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                brightness: Brightness.dark,
                surface: themeProvider.getSurfaceColor(),
                background: themeProvider.getBackgroundColor(),
                onBackground: themeProvider.getTextColor(),
                onSurface: themeProvider.getTextColor(),
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              cardTheme: CardThemeData(
                color: themeProvider.getCardBackgroundColor(),
                elevation: 2,
                shadowColor: themeProvider.getShadowColor(),
              ),
              scaffoldBackgroundColor: themeProvider.getProminentBackgroundColor(),
              dividerColor: themeProvider.getDividerColor(),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: themeProvider.getTextColor()),
                bodyMedium: TextStyle(color: themeProvider.getTextColor()),
                bodySmall: TextStyle(color: themeProvider.getSecondaryTextColor()),
              ),
            ),
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
