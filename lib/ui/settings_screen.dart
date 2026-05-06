import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Download Tiles'),
            subtitle: const Text('Download elevation data for offline use'),
            onTap: () {
              // TODO Phase 2: navigate to download screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.compress),
            title: const Text('Reduced Quality Mode'),
            subtitle: const Text('Use 360 rays instead of 1080 for slower devices'),
            trailing: Switch(value: false, onChanged: (v) {
              // TODO: persist setting
            }),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Mountain Panorama v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mountain Panorama',
                applicationVersion: '1.0.0',
                children: [
                  const Text('A PeakFinder-like mountain panorama viewer.\n\n'
                      'Elevation data: SRTM3 (NASA)\n'
                      'Peak data: GeoNames'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
