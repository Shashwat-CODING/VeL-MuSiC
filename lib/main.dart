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
          return MaterialApp(
            title: 'VeL-MuSiC',
            themeMode: settingsProvider.themeMode,
            theme: ThemeData(
              primaryColor: themeProvider.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                brightness: Brightness.light,
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
                color: themeProvider.accentColor.withOpacity(0.1),
                elevation: 2,
              ),
              scaffoldBackgroundColor: themeProvider.accentColor.withOpacity(0.05),
            ),
            darkTheme: ThemeData(
              primaryColor: themeProvider.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.primaryColor,
                brightness: Brightness.dark,
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
                color: themeProvider.accentColor.withOpacity(0.15),
                elevation: 2,
              ),
              scaffoldBackgroundColor: themeProvider.accentColor.withOpacity(0.08),
            ),
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
