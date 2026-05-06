import 'package:flutter/material.dart';
import '../data/tile_downloader.dart';
import '../data/tile_cache.dart';
import 'download_screen.dart';

class SettingsScreen extends StatelessWidget {
  final TileDownloader? downloader;
  final TileCache? tileCache;

  const SettingsScreen({super.key, this.downloader, this.tileCache});

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
            enabled: downloader != null && tileCache != null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DownloadScreen(
                    downloader: downloader!,
                    cache: tileCache!,
                  ),
                ),
              );
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
            subtitle: const Text('Mountain Panorama v2.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mountain Panorama',
                applicationVersion: '2.0.0',
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
