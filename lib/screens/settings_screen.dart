import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.watch<ThemeProvider>().getProminentBackgroundColor(),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              _buildSectionHeader(context, 'Appearance'),
              _buildThemeSelector(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // Audio Section
              _buildSectionHeader(context, 'Audio'),
              _buildAudioSettings(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // Download Section
              _buildSectionHeader(context, 'Downloads'),
              _buildDownloadSettings(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader(context, 'About'),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.watch<ThemeProvider>().getSecondaryTextColor(),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Theme'),
        subtitle: Text(settingsProvider.themeMode == ThemeMode.system 
            ? 'System' 
            : settingsProvider.themeMode == ThemeMode.light 
                ? 'Light' 
                : 'Dark'),
        trailing: DropdownButton<ThemeMode>(
          value: settingsProvider.themeMode,
          onChanged: (ThemeMode? newValue) {
            if (newValue != null) {
              settingsProvider.setThemeMode(newValue);
            }
          },
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Auto-play'),
            subtitle: const Text('Automatically play next track'),
            trailing: Switch(
              value: settingsProvider.autoPlay,
              onChanged: settingsProvider.setAutoPlay,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Repeat Mode'),
            subtitle: Text(settingsProvider.repeatMode == RepeatMode.none 
                ? 'No repeat' 
                : settingsProvider.repeatMode == RepeatMode.one 
                    ? 'Repeat one' 
                    : 'Repeat all'),
            trailing: DropdownButton<RepeatMode>(
              value: settingsProvider.repeatMode,
              onChanged: (RepeatMode? newValue) {
                if (newValue != null) {
                  settingsProvider.setRepeatMode(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: RepeatMode.none,
                  child: Text('None'),
                ),
                DropdownMenuItem(
                  value: RepeatMode.one,
                  child: Text('One'),
                ),
                DropdownMenuItem(
                  value: RepeatMode.all,
                  child: Text('All'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSettings(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download Quality'),
            subtitle: Text('${settingsProvider.downloadQuality}kbps'),
            trailing: DropdownButton<int>(
              value: settingsProvider.downloadQuality,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  settingsProvider.setDownloadQuality(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 128, child: Text('128 kbps')),
                DropdownMenuItem(value: 192, child: Text('192 kbps')),
                DropdownMenuItem(value: 320, child: Text('320 kbps')),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.download_for_offline),
            title: const Text('Show download popup'),
            value: settingsProvider.showDownloadPopup,
            onChanged: (v) => settingsProvider.setShowDownloadPopup(v),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Download Location'),
            subtitle: const Text('Private app storage'),
            onTap: () {
              // TODO: Implement download location picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy Protection'),
            subtitle: const Text('Downloads are stored privately and won\'t appear in Files app'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {
              _showPrivacyInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Open terms of service
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.green),
              SizedBox(width: 8),
              Text('Privacy Protection'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your downloaded music is completely private and secure:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Files are stored in the app\'s private directory'),
              Text('• Downloads won\'t appear in your device\'s Files app'),
              Text('• Other apps cannot access your downloaded music'),
              Text('• Your music library remains private and secure'),
              SizedBox(height: 12),
              Text(
                'This ensures your personal music collection stays private and won\'t clutter your device\'s file system.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
