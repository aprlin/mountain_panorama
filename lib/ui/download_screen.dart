import 'package:flutter/material.dart';
import '../data/tile_downloader.dart';
import '../data/tile_cache.dart';

class DownloadScreen extends StatefulWidget {
  final TileDownloader downloader;
  final TileCache cache;

  const DownloadScreen({
    super.key,
    required this.downloader,
    required this.cache,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  double _radius = 2.0;
  bool _downloading = false;
  int _completed = 0;
  int _total = 0;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _updateCacheInfo();
  }

  void _updateCacheInfo() {
    setState(() {});
  }

  Future<void> _download() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    if (lat == null || lon == null) {
      setState(() => _resultMessage = 'Enter valid coordinates');
      return;
    }

    setState(() {
      _downloading = true;
      _resultMessage = null;
      _completed = 0;
    });

    final result = await widget.downloader.downloadAround(
      lat, lon, _radius,
      (completed, total) {
        setState(() {
          _completed = completed;
          _total = total;
        });
      },
    );

    // Evict old tiles if needed
    widget.cache.evictIfNeeded();

    setState(() {
      _downloading = false;
      _resultMessage = result.allSucceeded
          ? 'Downloaded ${result.downloaded} tiles'
          : '${result.downloaded} downloaded, ${result.failed} failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cacheSizeMB =
        (widget.cache.cacheSizeBytes() / (1024 * 1024)).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('Download Tiles')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cache info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cached tiles: ${widget.cache.tileCount}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Cache size: $cacheSizeMB MB',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Coordinates input
            TextField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g. 46.5366',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g. 7.9632',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Radius slider
            Text('Radius: ${_radius.toStringAsFixed(1)}° '
                '~${(_radius * 111).round()}km'),
            Slider(
              value: _radius,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 16),

            // Download button
            ElevatedButton(
              onPressed: _downloading ? null : _download,
              child: _downloading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('$_completed / $_total'),
                      ],
                    )
                  : const Text('Download Region'),
            ),
            const SizedBox(height: 8),

            // Result message
            if (_resultMessage != null)
              Text(_resultMessage!,
                  style: TextStyle(
                    color: _resultMessage!.contains('failed')
                        ? Colors.orange
                        : Colors.green,
                  )),

            const SizedBox(height: 16),

            // Clear cache button
            OutlinedButton(
              onPressed: () {
                widget.cache.clear();
                _updateCacheInfo();
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear Cache'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}
