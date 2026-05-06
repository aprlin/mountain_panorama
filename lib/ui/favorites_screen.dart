import 'package:flutter/material.dart';
import '../data/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoritesService favoritesService;

  const FavoritesScreen({super.key, required this.favoritesService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoritePeak> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await widget.favoritesService.getAllFavorites();
    setState(() {
      _favorites = favorites;
      _loading = false;
    });
  }

  Future<void> _removeFavorite(FavoritePeak fav) async {
    await widget.favoritesService.removeFavorite(fav.peakId);
    await _loadFavorites();
  }

  Future<void> _editNote(FavoritePeak fav) async {
    final controller = TextEditingController(text: fav.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note for ${fav.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add a note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (note != null) {
      await widget.favoritesService.updateNote(fav.peakId, note);
      await _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Peaks'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap a peak in the panorama to bookmark it',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return Dismissible(
                      key: Key('fav_${fav.peakId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove favorite?'),
                            content: Text('Remove ${fav.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _removeFavorite(fav),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _elevationColor(fav.elevation),
                          child: Text(
                            '${(fav.elevation / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                        title: Text(fav.name),
                        subtitle: Text(
                          '${fav.elevation.round()}m · '
                          '${fav.latitude.toStringAsFixed(4)}°, '
                          '${fav.longitude.toStringAsFixed(4)}°'
                          '${fav.note != null && fav.note!.isNotEmpty ? '\n${fav.note}' : ''}',
                        ),
                        isThreeLine: fav.note != null && fav.note!.isNotEmpty,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note),
                          onPressed: () => _editNote(fav),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _elevationColor(double elevation) {
    if (elevation > 3500) return Colors.blueGrey.shade200;
    if (elevation > 2500) return Colors.brown;
    if (elevation > 1500) return Colors.green.shade800;
    return Colors.green;
  }
}
