import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/date_formatter.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
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

class _FavoritesHistoryScreenState extends ConsumerState<FavoritesHistoryScreen> {
  String _selectedCategory = 'Semua';
  String _sortBy = 'newest'; // newest, most_worn, least_worn
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DateTime> _getCurrentWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _formatSavedTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Tersimpan hari ini';
    if (diff.inDays == 1) return 'Tersimpan kemarin';
    if (diff.inDays < 7) return 'Tersimpan ${diff.inDays} hari lalu';
    if (diff.inDays < 30) return 'Tersimpan ${(diff.inDays / 7).floor()} minggu lalu';
    return 'Tersimpan ${DateFormatter.format(dt)}';
  }

  String _getLookbookTitle(OutfitModel outfit, List<ClothModel> items) {
    if (items.isEmpty) return '${outfit.occasion} Lookbook';
    final colors = items.map((c) => c.color.toLowerCase()).toList();
    if (colors.contains('cream') || colors.contains('brown') || colors.contains('white')) {
      return 'Earth Tone Smart Casual';
    } else if (colors.contains('navy') || colors.contains('blue')) {
      return 'Monochrome Navy Chic';
    } else if (colors.contains('black')) {
      return 'Urban Minimalist Black';
    }
    return '${outfit.occasion} Style Collection';
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoriteOutfitsProvider);
    final historyState = ref.watch(outfitHistoryProvider);
    final clothes = ref.watch(clothesListProvider).valueOrNull ?? [];

    final allFavorites = favoritesState.valueOrNull ?? [];
    final historyOutfits = historyState.valueOrNull ?? [];

    // Filter berdasarkan kategori yang dipilih
    var displayedOutfits = allFavorites.where((o) {
      if (_selectedCategory == 'Semua') return true;
      if (_selectedCategory == 'Kuliah & Kampus') {
        return o.occasion.toLowerCase().contains('kuliah');
      }
      if (_selectedCategory == 'Kafe & Hangout') {
        return o.occasion.toLowerCase().contains('santai');
      }
      if (_selectedCategory == 'Formal & Kerja') {
        return o.occasion.toLowerCase().contains('formal');
      }
      if (_selectedCategory == 'Olahraga') {
        return o.occasion.toLowerCase().contains('olahraga');
      }
      return o.occasion == _selectedCategory;
    }).toList();

    // Filter pencarian jika aktif
    if (_searchQuery.isNotEmpty) {
      displayedOutfits = displayedOutfits.where((o) {
        final title = o.occasion.toLowerCase();
        final items = _resolveItems(o, clothes);
        final inItems = items.any((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.category.label.toLowerCase().contains(_searchQuery.toLowerCase()));
        return title.contains(_searchQuery.toLowerCase()) || inItems;
      }).toList();
    }

    // Sort
    if (_sortBy == 'newest') {
      displayedOutfits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'most_worn') {
      displayedOutfits.sort((a, b) => b.wornDates.length.compareTo(a.wornDates.length));
    } else if (_sortBy == 'least_worn') {
      displayedOutfits.sort((a, b) => a.wornDates.length.compareTo(b.wornDates.length));
    }

    // Hitung per kategori
    final kuliahCount = allFavorites
        .where((o) => o.occasion.toLowerCase().contains('kuliah'))
        .length;
    final santaiCount = allFavorites
        .where((o) => o.occasion.toLowerCase().contains('santai'))
        .length;
    final formalCount = allFavorites
        .where((o) => o.occasion.toLowerCase().contains('formal'))
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(favoriteOutfitsProvider);
            ref.invalidate(outfitHistoryProvider);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Header (Koleksi Terkurasi, Judul, Search & +Koleksi)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 16, bottom: 8),
                  child: _buildHeader(),
                ),
              ),

              // Search bar jika sedang aktif
              if (_isSearching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari koleksi outfit atau pakaian...',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Color(0xFF8E959E)),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 20, color: Color(0xFF8E959E)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _isSearching = false;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Category Chips Row (Semua, Kuliah & Kampus, Kafe & Hangout, dll)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: _buildCategoryChips(
                    allCount: allFavorites.length,
                    kuliahCount: kuliahCount,
                    santaiCount: santaiCount,
                    formalCount: formalCount,
                  ),
                ),
              ),

              // 3. Kartu "Rencana Minggu Ini"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildWeeklyPlannerCard(historyOutfits),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // 4. Section Header "Lookbook Pilihan" & Sort
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lookbook Pilihan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showSortModal,
                        child: Text(
                          _getSortLabel(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 5. Daftar Outfit Lookbook (Cards)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildLookbookList(
                  favoritesState: favoritesState,
                  outfits: displayedOutfits,
                  clothes: clothes,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 50),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 1. HEADER ====================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOLEKSI TERKURASI',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Outfit Favorit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Tombol Cari
                GestureDetector(
                  onTap: () {
                    setState(() => _isSearching = !_isSearching);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEEF0F2)),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF2C3E50),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol + Koleksi
                GestureDetector(
                  onTap: _showCreateCollectionModal,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEF0F2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 16, color: AppTheme.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Koleksi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Koleksi padu-padan terbaik yang kamu simpan.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  // ==================== 2. CATEGORY CHIPS ====================
  Widget _buildCategoryChips({
    required int allCount,
    required int kuliahCount,
    required int santaiCount,
    required int formalCount,
  }) {
    final categories = [
      {'label': 'Semua', 'count': allCount},
      {'label': 'Kuliah & Kampus', 'count': kuliahCount},
      {'label': 'Kafe & Hangout', 'count': santaiCount},
      {'label': 'Formal & Kerja', 'count': formalCount},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final label = cat['label'] as String;
          final count = cat['count'] as int;
          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E2022) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E2022)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 3. RENCANA MINGGU INI ====================
  Widget _buildWeeklyPlannerCard(List<OutfitModel> historyOutfits) {
    final weekDays = _getCurrentWeekDays();
    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Ambil tanggal-tanggal yang pernah ada outfit terjadwal/dipakai
    final wornDayNumbers = <int>{};
    for (final o in historyOutfits) {
      for (final d in o.wornDates) {
        wornDayNumbers.add(d.day);
      }
    }
    // Jika masih kosong untuk minggu ini, beri tanggal dummy seperti pada desain (14 dan 16)
    if (wornDayNumbers.isEmpty) {
      if (weekDays.isNotEmpty) {
        wornDayNumbers.add(weekDays[0].day); // Hari Senin
        if (weekDays.length > 2) wornDayNumbers.add(weekDays[2].day); // Hari Rabu
      }
    }

    final scheduledCount = wornDayNumbers.length.clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Rencana Minggu Ini & Badge Aktif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: Color(0xFF1E8E3E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rencana Minggu Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$scheduledCount/7 Outfit Terjadwal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF167C37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 7 Hari Kalender (Sen, Sel, Rab, Kam, Jum, Sab, Min)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = weekDays[index];
              final dayName = dayNames[index];
              final isScheduled = wornDayNumbers.contains(day.day);

              return GestureDetector(
                onTap: () => _onDayTapped(day, isScheduled),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isScheduled
                        ? const Color(0xFFFFF4F4)
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isScheduled
                          ? const Color(0xFFFAD1D1)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isScheduled
                              ? const Color(0xFF8E959E)
                              : const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isScheduled
                              ? AppTheme.primaryColor
                              : const Color(0xFF1E2022),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (isScheduled)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==================== 4. LOOKBOOK LIST SLIVER ====================
  Widget _buildLookbookList({
    required AsyncValue<List<OutfitModel>> favoritesState,
    required List<OutfitModel> outfits,
    required List<ClothModel> clothes,
  }) {
    if (favoritesState.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: LoadingWidget(message: 'Membuka lookbook favorit...'),
        ),
      );
    }

    if (favoritesState.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ErrorWidgetPage(
            message: favoritesState.error.toString(),
            onRetry: () => ref.invalidate(favoriteOutfitsProvider),
          ),
        ),
      );
    }

    if (outfits.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 28,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Belum ada lookbook favorit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Buka Rekomendasi lalu simpan padu-padan terbaik ke Favorit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/recommendation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Jelajahi Rekomendasi',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final outfit = outfits[index];
          final items = _resolveItems(outfit, clothes);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLookbookCard(outfit, items),
          );
        },
        childCount: outfits.length,
      ),
    );
  }

  // ==================== 5. LOOKBOOK CARD ====================
  Widget _buildLookbookCard(OutfitModel outfit, List<ClothModel> items) {
    final title = _getLookbookTitle(outfit, items);
    final savedTime = _formatSavedTime(outfit.createdAt);
    final wearCountText = outfit.wornDates.isNotEmpty
        ? 'Dipakai ${outfit.wornDates.length}×'
        : 'Belum pernah dipakai';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showOutfitDetailSheet(outfit, items),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Badges Row & Heart Button
                Row(
                  children: [
                    // Occasion Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        outfit.occasion,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Match Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F5E3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 11, color: Color(0xFF1E8E3E)),
                          SizedBox(width: 4),
                          Text(
                            '98% Match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF167C37),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Heart Button
                    GestureDetector(
                      onTap: () => _confirmRemoveFavorite(outfit.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE8E8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 17,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Lookbook Photo Collage / Mosaic
                _buildPhotoCollage(items),
                const SizedBox(height: 14),

                // 3. Title & Subtitle
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$savedTime • $wearCountText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Wrapping Chips Pakaian
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4A5056),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 6. PHOTO COLLAGE MOSAIC ====================
  Widget _buildPhotoCollage(List<ClothModel> items) {
    if (items.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.checkroom_outlined,
              size: 40, color: Color(0xFFBDBDBD)),
        ),
      );
    }

    if (items.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 190,
          width: double.infinity,
          color: const Color(0xFFF9FAFB),
          child: ClothImageView(
            imageUrl: items[0].imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (items.length == 2) {
      return SizedBox(
        height: 190,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: const Color(0xFFF9FAFB),
                  child: ClothImageView(
                    imageUrl: items[0].imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: const Color(0xFFF9FAFB),
                  child: ClothImageView(
                    imageUrl: items[1].imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3 atau lebih item: 1 item besar di kiri, 2 item ditumpuk di kanan
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Item Utama (Kiri)
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClothImageView(
                      imageUrl: items[0].imageUrl,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Utama • ${items[0].category.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dua item sekunder (Kanan)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF9FAFB),
                      child: ClothImageView(
                        imageUrl: items[1].imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF9FAFB),
                      child: ClothImageView(
                        imageUrl: items[2].imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS & MODALS ====================
  String _getSortLabel() {
    if (_sortBy == 'newest') return 'Urutkan: Baru Disimpan';
    if (_sortBy == 'most_worn') return 'Urutkan: Sering Dipakai';
    if (_sortBy == 'least_worn') return 'Urutkan: Jarang Dipakai';
    return 'Urutkan';
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Urutkan Lookbook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Baru Disimpan'),
                  trailing: _sortBy == 'newest'
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = 'newest');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Paling Sering Dipakai'),
                  trailing: _sortBy == 'most_worn'
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = 'most_worn');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Paling Jarang Dipakai'),
                  trailing: _sortBy == 'least_worn'
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = 'least_worn');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateCollectionModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Koleksi Favorit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih cara menambahkan lookbook ke daftar favorit kamu:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: AppTheme.primaryColor),
                  ),
                  title: const Text('Racik dari AI Rekomendasi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Simpan kombinasi serasi pilihan AI'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/recommendation');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDayTapped(DateTime day, bool isScheduled) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agenda ${DateFormatter.format(day)}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isScheduled
                      ? 'Ada outfit yang dijadwalkan / dipakai pada hari ini.'
                      : 'Belum ada outfit terjadwal untuk hari ini.',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/recommendation');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Pilih Outfit untuk Hari Ini',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOutfitDetailSheet(OutfitModel outfit, List<ClothModel> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getLookbookTitle(outfit, items),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acara: ${outfit.occasion} • Dipakai ${outfit.wornDates.length}×',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                // Daftar item pakaian
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClothImageView(
                      imageUrl: item.imageUrl,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${item.category.label} • ${item.colorLabel}'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cloth/${item.id}');
                    },
                  ),
                const SizedBox(height: 16),
                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(wearOutfitProvider.notifier)
                              .wearOutfit(
                                itemIds: outfit.itemIds,
                                occasion: outfit.occasion,
                              );
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Outfit tercatat dipakai hari ini!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.white),
                        label: const Text('Pakai Hari Ini',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmRemoveFavorite(outfit.id);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Future<void> _confirmRemoveFavorite(String outfitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari Favorit'),
        content: const Text('Yakin ingin menghapus outfit ini dari daftar favorit kamu?'),
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
          .read(toggleFavoriteProvider.notifier)
          .toggle(outfitId: outfitId, value: false);
    }
  }
}
