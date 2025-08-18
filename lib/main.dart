
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';


import 'generated/l10n.dart';
import 'services/download_manager.dart';
import 'services/file_storage.dart';
import 'services/library.dart';
import 'services/lyrics.dart';
import 'services/media_player.dart';
import 'services/settings_manager.dart';
import 'themes/colors.dart';
import 'themes/dark.dart';
import 'themes/light.dart';
import 'utils/router.dart';
import 'ytmusic/ytmusic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ColorExtractor

  
  if (Platform.isAndroid) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.vel.music',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  }
  await initialiseHive();
  if (Platform.isWindows) {
    await Window.initialize();

    await Window.hideWindowControls();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      WindowEffect windowEffect = windowEffectList.firstWhere(
        (el) =>
            el.name.toUpperCase() ==
            Hive.box('SETTINGS').get(
              'WINDOW_EFFECT',
              defaultValue: WindowEffect.mica.name.toUpperCase(),
            ),
      );
      await Window.setEffect(
        effect: windowEffect,
        dark: getInitialDarkness(),
      );

      await windowManager.show();
      await windowManager.setPreventClose(false);
      await windowManager.setSkipTaskbar(false);
    });
  }
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized();
    JustAudioMediaKit.bufferSize = 8 * 1024 * 1024;
    JustAudioMediaKit.title = 'VeL-MuSic Music';
    JustAudioMediaKit.prefetchPlaylist = true;
  }
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  YTMusic ytMusic = YTMusic();
  await ytMusic.init();

  final GlobalKey<NavigatorState> panelKey = GlobalKey<NavigatorState>();

  await FileStorage.initialise();
  FileStorage fileStorage = FileStorage();
  SettingsManager settingsManager = SettingsManager();
  GetIt.I.registerSingleton<SettingsManager>(settingsManager);
  MediaPlayer mediaPlayer = MediaPlayer();
  GetIt.I.registerSingleton<MediaPlayer>(mediaPlayer);
  LibraryService libraryService = LibraryService();
  GetIt.I.registerSingleton<DownloadManager>(DownloadManager());
  GetIt.I.registerSingleton(panelKey);
  GetIt.I.registerSingleton<YTMusic>(ytMusic);

  GetIt.I.registerSingleton<FileStorage>(fileStorage);

  GetIt.I.registerSingleton<LibraryService>(libraryService);
  GetIt.I.registerSingleton<Lyrics>(Lyrics());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsManager),
        ChangeNotifierProvider(create: (_) => mediaPlayer),
        ChangeNotifierProvider(create: (_) => libraryService),
      ],
      child: const VelMusic(),
    ),
  );
}

class VelMusic extends StatelessWidget {
  const VelMusic({super.key});
  @override
  Widget build(BuildContext context) {
    SettingsManager settingsManager = context.watch<SettingsManager>();
    return DynamicColorBuilder(builder: (lightScheme, darkScheme) {
      return Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        },
        child: Platform.isWindows
            ? _buildFluentApp(
                settingsManager,
                lightScheme: lightScheme,
                darkScheme: darkScheme,
              )
            : MaterialApp.router(
                key: ValueKey(settingsManager.accentColor?.value ?? 0), // Force rebuild when accent color changes
                title: 'VeL-MuSic',
                routerConfig: router,
                locale:
                    Locale(context.watch<SettingsManager>().language['value']!),
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                debugShowCheckedModeBanner: false,
                themeMode: (() {
                  final themeMode = context.watch<SettingsManager>().themeMode;
                  print('🎨 Current theme mode: $themeMode');
                  return themeMode;
                })(),
                theme: lightTheme(
                  colorScheme: (!context.watch<SettingsManager>().dynamicColors &&
                          lightScheme != null)
                      ? lightScheme
                      : ColorScheme(
                          brightness: Brightness.light,
                          primary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            final accentColor = settingsManager.dynamicColors ? settingsManager.accentColor : null;
                            print('🎨 Light theme primary color: $accentColor (dynamicColors: ${settingsManager.dynamicColors})');
                            return accentColor ?? spotifyGreen;
                          })(),
                          onPrimary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            if (settingsManager.dynamicColors && settingsManager.accentColor != null) {
                              // Use white text on accent color for good contrast
                              return Colors.white;
                            }
                            // Use black text on Spotify green for good contrast
                            return spotifyBlack;
                          })(),
                          secondary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors ? (settingsManager.accentColor ?? spotifyDarkGreen) : spotifyDarkGreen;
                          })(),
                          onSecondary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors && settingsManager.accentColor != null ? Colors.white : spotifyBlack;
                          })(),
                          surface: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            Color surfaceColor;
                            if (settingsManager.dynamicColors && settingsManager.accentColor != null) {
                              // Use a very light tint of the accent color for surface
                              surfaceColor = settingsManager.accentColor!.withOpacity(0.08);
                            } else {
                              // Use white for surface in light theme
                              surfaceColor = Colors.white;
                            }
                            print('🎨 Light theme surface color: $surfaceColor (dynamicColors: ${settingsManager.dynamicColors})');
                            return surfaceColor;
                          })(),
                          onSurface: spotifyBlack,
                          background: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            Color backgroundColor;
                            if (settingsManager.dynamicColors && settingsManager.accentColor != null) {
                              // Use a very light tint of the accent color for background
                              backgroundColor = settingsManager.accentColor!.withOpacity(0.05);
                            } else {
                              // Use white for background in light theme
                              backgroundColor = Colors.white;
                            }
                            print('🎨 Light theme background color: $backgroundColor (dynamicColors: ${settingsManager.dynamicColors})');
                            return backgroundColor;
                          })(),
                          onBackground: spotifyBlack,
                          surfaceContainerLow: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            if (settingsManager.dynamicColors && settingsManager.accentColor != null) {
                              // Use a light tint of the accent color for surface containers
                              return settingsManager.accentColor!.withOpacity(0.12);
                            } else {
                              // Use light gray for surface containers in light theme
                              return const Color(0xFFF5F5F5);
                            }
                          })(),
                          surfaceContainerHigh: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            if (settingsManager.dynamicColors && settingsManager.accentColor != null) {
                              // Use a medium tint of the accent color for surface containers
                              return settingsManager.accentColor!.withOpacity(0.18);
                            } else {
                              // Use medium gray for surface containers in light theme
                              return const Color(0xFFE0E0E0);
                            }
                          })(),
                          outline: spotifyMediumGrey,
                          outlineVariant: spotifyLightGrey,
                          error: Colors.red,
                          onError: Colors.white,
                        ),
                ),
                darkTheme: darkTheme(
                  colorScheme: (!context.watch<SettingsManager>().dynamicColors &&
                          darkScheme != null)
                      ? darkScheme
                      : ColorScheme(
                          brightness: Brightness.dark,
                          primary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors ? (settingsManager.accentColor ?? spotifyGreen) : spotifyGreen;
                          })(),
                          onPrimary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors && settingsManager.accentColor != null ? spotifyBlack : spotifyWhite;
                          })(),
                          secondary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors ? (settingsManager.accentColor ?? spotifyDarkGreen) : spotifyDarkGreen;
                          })(),
                          onSecondary: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors && settingsManager.accentColor != null ? spotifyBlack : spotifyWhite;
                          })(),
                          surface: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            if (!settingsManager.dynamicColors || settingsManager.accentColor == null) {
                              return settingsManager.amoledBlack ? Colors.black : spotifyBlack;
                            }
                            if (settingsManager.amoledBlack) {
                              return settingsManager.accentColor!.withOpacity(0.15);
                            }
                            return settingsManager.accentColor!.withOpacity(0.1);
                          })(),
                          onSurface: spotifyWhite,
                          background: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            if (!settingsManager.dynamicColors || settingsManager.accentColor == null) {
                              return settingsManager.amoledBlack ? Colors.black : spotifyBlack;
                            }
                            if (settingsManager.amoledBlack) {
                              return settingsManager.accentColor!.withOpacity(0.08);
                            }
                            return settingsManager.accentColor!.withOpacity(0.05);
                          })(),
                          onBackground: spotifyWhite,
                          surfaceContainerLow: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors && settingsManager.accentColor != null 
                                ? settingsManager.accentColor!.withOpacity(0.2) 
                                : spotifyDarkGrey;
                          })(),
                          surfaceContainerHigh: (() {
                            final settingsManager = context.watch<SettingsManager>();
                            return settingsManager.dynamicColors && settingsManager.accentColor != null 
                                ? settingsManager.accentColor!.withOpacity(0.25) 
                                : spotifyMediumGrey;
                          })(),
                          outline: spotifyMediumGrey,
                          outlineVariant: spotifyLightGrey,
                          error: Colors.red,
                          onError: Colors.white,
                        ),
                ),
              ),
      );
    });
  }

  _buildFluentApp(SettingsManager settingsManager,
      {ColorScheme? lightScheme, ColorScheme? darkScheme}) {
    return fluent_ui.FluentApp.router(
      key: ValueKey(settingsManager.accentColor?.value ?? 0), // Force rebuild when accent color changes
      title: 'VeL-MuSic',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: Locale(settingsManager.language['value']!),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      themeMode: settingsManager.themeMode,
      theme: fluent_ui.FluentThemeData(
        brightness: Brightness.light,
        accentColor: settingsManager.dynamicColors
            ? lightScheme?.primary.toAccentColor()
            : settingsManager.accentColor?.toAccentColor(),
        fontFamily: GoogleFonts.poppins().fontFamily,
        typography: fluent_ui.Typography.fromBrightness(
          brightness: Brightness.light,
        ),
        iconTheme: const fluent_ui.IconThemeData(color: Colors.black),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor:
            (settingsManager.windowEffect == WindowEffect.disabled &&
                    settingsManager.dynamicColors)
                ? lightScheme?.surface
                : null,
      ),
      darkTheme: fluent_ui.FluentThemeData(
        brightness: Brightness.dark,
        accentColor: settingsManager.dynamicColors
            ? darkScheme?.primary.toAccentColor()
            : settingsManager.accentColor?.toAccentColor(),
        fontFamily: GoogleFonts.poppins().fontFamily,
        typography: fluent_ui.Typography.fromBrightness(
          brightness: Brightness.dark,
        ),
        iconTheme: const fluent_ui.IconThemeData(color: Colors.white),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor:
            (settingsManager.windowEffect == WindowEffect.disabled)
                ? (settingsManager.dynamicColors
                    ? darkScheme?.surface
                    : settingsManager.amoledBlack
                        ? Colors.black
                        : null)
                : null,
      ),
      builder: (context, child) {
        return fluent_ui.NavigationPaneTheme(
          data: fluent_ui.NavigationPaneThemeData(
            backgroundColor:
                settingsManager.windowEffect == WindowEffect.disabled
                    ? null
                    : fluent_ui.Colors.transparent,
          ),
          child: child!,
        );
      },
    );
  }
}

initialiseHive() async {
  String? applicationDataDirectoryPath;
  if (Platform.isWindows || Platform.isLinux) {
    applicationDataDirectoryPath =
        "${(await getApplicationSupportDirectory()).path}/database";
  }
  await Hive.initFlutter(applicationDataDirectoryPath);
  await Hive.openBox('SETTINGS');
  await Hive.openBox('LIBRARY');
  await Hive.openBox('SEARCH_HISTORY');
  await Hive.openBox('SONG_HISTORY');
  await Hive.openBox('FAVOURITES');
  await Hive.openBox('DOWNLOADS');
}

bool getInitialDarkness() {
  int themeMode = Hive.box('SETTINGS').get('THEME_MODE', defaultValue: 0);
  if (themeMode == 0) {
    return MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .platformBrightness ==
            Brightness.dark
        ? true
        : false;
  } else if (themeMode == 2) {
    return true;
  }
  return false;
}

List<WindowEffect> get windowEffectList => [
      WindowEffect.disabled,
      WindowEffect.acrylic,
      WindowEffect.solid,
      WindowEffect.mica,
      WindowEffect.tabbed,
      WindowEffect.aero,
    ];
