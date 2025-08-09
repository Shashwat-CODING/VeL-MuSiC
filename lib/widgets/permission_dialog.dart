import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open, color: Colors.blue),
          SizedBox(width: 8),
          Text('Storage Permission Required'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VeL-MuSiC needs storage permission to download tracks to your device.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'To grant permission:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('1. Tap "Open Settings"'),
          Text('2. Find "Files and media"'),
          Text('3. Select "Allow"'),
          Text('4. Return to the app'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
