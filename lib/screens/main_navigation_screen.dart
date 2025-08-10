import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load downloaded tracks when app starts
      context.read<DownloadProvider>().loadDownloadedTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProxyProvider<ThemeProvider, MusicProvider>(
          create: (context) => MusicProvider(),
          update: (context, themeProvider, musicProvider) {
            musicProvider?.setThemeProvider(themeProvider);
            return musicProvider ?? MusicProvider();
          },
        ),
        ChangeNotifierProxyProvider<MusicProvider, LibraryProvider>(
          create: (context) => LibraryProvider(),
          update: (context, musicProvider, libraryProvider) {
            libraryProvider?.setMusicProvider(musicProvider);
            return libraryProvider ?? LibraryProvider();
          },
        ),
        ChangeNotifierProxyProvider<LibraryProvider, DownloadProvider>(
          create: (context) => DownloadProvider(),
          update: (context, libraryProvider, downloadProvider) {
            downloadProvider?.setLibraryProvider(libraryProvider);
            return downloadProvider ?? DownloadProvider();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.watch<ThemeProvider>().getProminentBackgroundColor(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: themeProvider.primaryColor,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white70,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music),
                      label: 'Library',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
