import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/date_formatter.dart';
import 'package:pakeaja/core/widgets/outfit_card.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class FavoritesHistoryScreen extends ConsumerStatefulWidget {
  const FavoritesHistoryScreen({super.key});

  @override
  ConsumerState<FavoritesHistoryScreen> createState() =>
      _FavoritesHistoryScreenState();
}

class _FavoritesHistoryScreenState extends ConsumerState<FavoritesHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit & Riwayat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.favorite_outline), text: 'Favorit'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favorites = ref.watch(favoriteOutfitsProvider);
    final clothes = ref.watch(clothesListProvider).value ?? [];

    return favorites.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidgetPage(
        message: e.toString(),
        onRetry: () => ref.invalidate(favoriteOutfitsProvider),
      ),
      data: (outfits) {
        if (outfits.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_outline,
            title: 'Belum ada favorit',
            subtitle: 'Simpan outfit yang kamu suka di sini.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: outfits.length,
          itemBuilder: (context, index) {
            final outfit = outfits[index];
            final items = _resolveItems(outfit, clothes);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutfitCard(
                items: items,
                occasion: outfit.occasion,
                isFavorite: true,
                onFavoriteToggle: () => _toggleFavorite(outfit.id, false),
                onDelete: () => _confirmDeleteOutfit(outfit.id),
                onWear: () => _wearAgain(outfit),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final history = ref.watch(outfitHistoryProvider);
    final clothes = ref.watch(clothesListProvider).value ?? [];

    return history.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidgetPage(
        message: e.toString(),
        onRetry: () => ref.invalidate(outfitHistoryProvider),
      ),
      data: (outfits) {
        // Filter outfit yang pernah dipakai
        final worn = outfits.where((o) => o.wornDates.isNotEmpty).toList();

        if (worn.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'Belum ada riwayat',
            subtitle: 'Outfit yang sudah kamu pakai akan muncul di sini.',
          );
        }

        // Kelompokkan berdasarkan tanggal
        final grouped = <String, List<OutfitModel>>{};
        for (final o in worn) {
          for (final date in o.wornDates) {
            final key = DateFormatter.dayTitle(date);
            grouped.putIfAbsent(key, () => []).add(o);
          }
        }

        final keys = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final dateKey = keys[index];
            final dayOutfits = grouped[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final outfit in dayOutfits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutfitCard(
                      items: _resolveItems(outfit, clothes),
                      occasion: outfit.occasion,
                      onFavoriteToggle: () =>
                          _toggleFavorite(outfit.id, !outfit.isFavorite),
                      onWear: () => _wearAgain(outfit),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<ClothModel> _resolveItems(OutfitModel outfit, List<ClothModel> clothes) {
    return outfit.itemIds
        .map((id) => clothes.firstWhere(
              (c) => c.id == id,
              orElse: () => ClothModel(
                id: id,
                name: 'Item tidak ditemukan',
                category: ClothCategory.top,
                color: 'other',
                styles: const [],
                weather: ClothWeather.cool,
                imageUrl: '',
                createdAt: DateTime.now(),
              ),
            ))
        .toList();
  }

  Future<void> _toggleFavorite(String outfitId, bool value) async {
    await ref
        .read(toggleFavoriteProvider.notifier)
        .toggle(outfitId: outfitId, value: value);
  }

  Future<void> _confirmDeleteOutfit(String outfitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Outfit'),
        content: const Text('Yakin hapus outfit ini dari favorit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(deleteOutfitProvider.notifier)
          .deleteOutfit(outfitId: outfitId);
    }
  }

  Future<void> _wearAgain(OutfitModel outfit) async {
    final success = await ref
        .read(wearOutfitProvider.notifier)
        .wearOutfit(itemIds: outfit.itemIds, occasion: outfit.occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit tercatat dipakai hari ini.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
