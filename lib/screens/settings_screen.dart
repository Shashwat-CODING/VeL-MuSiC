import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildSectionHeader('Appearance'),
              _buildThemeSelector(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // Audio Section
              _buildSectionHeader('Audio'),
              _buildAudioSettings(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // Download Section
              _buildSectionHeader('Downloads'),
              _buildDownloadSettings(context, settingsProvider),
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader('About'),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
            subtitle: Text(settingsProvider.downloadLocation),
            onTap: () {
              // TODO: Implement download location picker
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
}
