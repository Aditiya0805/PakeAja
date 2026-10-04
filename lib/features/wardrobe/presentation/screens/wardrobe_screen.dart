import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/clothing_card.dart';
import 'package:pakeaja/core/widgets/filter_chip.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clothesState = ref.watch(clothesListProvider);
    final filtered = ref.watch(filteredClothesProvider);
    final filter = ref.watch(clothFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lemari'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: filter.isActive ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref
                  .read(clothFilterProvider.notifier)
                  .state = filter.copyWith(search: v),
              decoration: InputDecoration(
                hintText: 'Cari pakaian...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(clothFilterProvider.notifier)
                              .state = filter.copyWith(search: '');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(filter),

          // Grid
          Expanded(
            child: clothesState.isLoading
                ? const LoadingWidget(message: 'Memuat lemari...')
                : clothesState.hasError
                    ? ErrorWidgetPage(
                        message: clothesState.error.toString(),
                        onRetry: () => ref.invalidate(clothesListProvider),
                      )
                    : filtered.isEmpty
                        ? _buildEmpty(filter)
                        : _buildGrid(filtered),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cloth/add'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildGrid(List<ClothModel> clothes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: clothes.length,
      itemBuilder: (context, index) {
        final cloth = clothes[index];
        return ClothingCard(
          cloth: cloth,
          onTap: () => context.push('/cloth/${cloth.id}'),
          onLongPress: () => _showOptions(cloth),
        );
      },
    );
  }

  Widget _buildFilters(ClothFilter filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori
          const Text('Kategori',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChipWidget(
                  label: 'Semua',
                  selected: filter.category == 'all',
                  onSelected: () => _updateFilter(filter.copyWith(category: 'all')),
                ),
                for (final entry in AppConstants.clothCategories.entries)
                  FilterChipWidget(
                    label: entry.value,
                    selected: filter.category == entry.key,
                    onSelected: () =>
                        _updateFilter(filter.copyWith(category: entry.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Warna
          const Text('Warna',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChipWidget(
                  label: 'Semua',
                  selected: filter.color == 'all',
                  onSelected: () => _updateFilter(filter.copyWith(color: 'all')),
                ),
                for (final entry in AppConstants.clothColors.entries)
                  FilterChipWidget(
                    label: entry.value,
                    selected: filter.color == entry.key,
                    onSelected: () =>
                        _updateFilter(filter.copyWith(color: entry.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Gaya
          const Text('Gaya',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChipWidget(
                  label: 'Semua',
                  selected: filter.style == 'all',
                  onSelected: () => _updateFilter(filter.copyWith(style: 'all')),
                ),
                for (final entry in AppConstants.styles.entries)
                  FilterChipWidget(
                    label: entry.value,
                    selected: filter.style == entry.key,
                    onSelected: () =>
                        _updateFilter(filter.copyWith(style: entry.key)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateFilter(ClothFilter newFilter) {
    ref.read(clothFilterProvider.notifier).state = newFilter;
  }

  Widget _buildEmpty(ClothFilter filter) {
    if (filter.isActive) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: 'Coba ubah kata kunci atau filter kamu.',
      );
    }
    return EmptyState(
      icon: Icons.checkroom_outlined,
      title: 'Lemari masih kosong',
      subtitle: 'Tambahkan pakaian pertamamu sekarang.',
      actionText: 'Tambah Pakaian',
      onAction: () => context.push('/cloth/add'),
    );
  }

  void _showOptions(ClothModel cloth) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                context.pop();
                context.push('/cloth/${cloth.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor),
              title: const Text('Hapus',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                context.pop();
                _confirmDelete(cloth);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ClothModel cloth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pakaian'),
        content: Text('Yakin hapus "${cloth.name}"? Tindakan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              context.pop();
              final user = ref.read(authStateProvider).value;
              if (user == null) return;

              final success = await ref
                  .read(deleteClothProvider.notifier)
                  .deleteCloth(
                    uid: user.uid,
                    clothId: cloth.id,
                    imageUrl: cloth.imageUrl,
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pakaian berhasil dihapus.')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Gagal menghapus: ${ref.read(deleteClothProvider).error}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
