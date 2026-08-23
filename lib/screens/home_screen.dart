import 'package:flutter/material.dart';
import '../main.dart' show themeModeNotifier;
import '../models/kecamatan_model.dart';
import '../services/app_data_service.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kecamatan_card.dart';
import '../widgets/watermark_footer.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Tab { pencarian, favorit, riwayat }

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _favService = FavoriteService();
  final _data = AppDataService.instance;

  List<KecamatanModel> _results = [];
  Set<String> _favoriteIds = {};
  _Tab _tab = _Tab.pencarian;
  bool _searching = false;

  // Mencegah hasil pencarian lama "menimpa" hasil yang lebih baru — relevan
  // terutama di Web, di mana search() bisa memakan waktu (memuat file
  // provinsi) sehingga dua pencarian beruntun bisa selesai tidak berurutan.
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    // Tampilkan dua titik referensi (Ka'bah & Lirboyo) sebagai state awal
    _results = _data.referensi;
  }

  Future<void> _loadFavorites() async {
    final ids = await _favService.getFavoriteIds();
    if (mounted) setState(() => _favoriteIds = ids.toSet());
  }

  Future<void> _onSearchChanged(String query) async {
    final requestId = ++_searchRequestId;

    setState(() {
      _tab = _Tab.pencarian;
      if (query.trim().isEmpty) {
        _results = _data.referensi;
        _searching = false;
      } else {
        _searching = true;
      }
    });

    if (query.trim().isEmpty) return;

    final referensiMatch = _data.referensi.where(
      (r) => r.searchIndex.contains(query.toLowerCase()),
    );
    final kecamatanMatch = await _data.search(query);

    // Jika sudah ada pencarian yang lebih baru dimulai setelah ini, buang
    // hasil ini (stale) — jangan ditampilkan.
    if (requestId != _searchRequestId || !mounted) return;

    setState(() {
      _results = [...referensiMatch, ...kecamatanMatch];
      _searching = false;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    await _favService.toggleFavorite(id);
    await _loadFavorites();
  }

  Future<void> _openDetail(KecamatanModel data) async {
    await _favService.addToHistory(data.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(data: data)),
    );
  }

  Future<List<KecamatanModel>> _resolveIds(List<String> ids) async {
    return ids.map((id) => _data.findById(id)).whereType<KecamatanModel>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencari Kecamatan Indonesia'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                tooltip: 'Ganti tema',
                onPressed: () {
                  themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kecamatan, kabupaten, provinsi, elevasi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          _buildTabBar(),
          const SizedBox(height: 4),
          Expanded(child: _buildList()),
          const WatermarkFooter(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    Widget tabButton(_Tab tab, String label, IconData icon) {
      final selected = _tab == tab;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.gold : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: selected ? AppColors.emerald : Colors.grey),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: selected ? AppColors.emerald : Colors.grey,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tabButton(_Tab.pencarian, 'Pencarian', Icons.search_rounded),
        tabButton(_Tab.favorit, 'Favorit', Icons.star_rounded),
        tabButton(_Tab.riwayat, 'Riwayat', Icons.history_rounded),
      ],
    );
  }

  Widget _buildList() {
    if (_tab == _Tab.pencarian) {
      if (_searching) {
        return const Center(child: CircularProgressIndicator());
      }
      return _listView(_results);
    }

    final future = _tab == _Tab.favorit
        ? _favService.getFavoriteIds().then(_resolveIds)
        : _favService.getHistoryIds().then(_resolveIds);

    return FutureBuilder<List<KecamatanModel>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Text(
              _tab == _Tab.favorit ? 'Belum ada lokasi favorit' : 'Belum ada riwayat pencarian',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }
        return _listView(items);
      },
    );
  }

  Widget _listView(List<KecamatanModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('Tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KecamatanCard(
          data: item,
          isFavorite: _favoriteIds.contains(item.id),
          onTap: () => _openDetail(item),
          onToggleFavorite: () => _toggleFavorite(item.id),
        );
      },
    );
  }
}
