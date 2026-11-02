import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/clothing_card.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider, userDataProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final current = ref.read(clothFilterProvider);
    ref.read(clothFilterProvider.notifier).state =
        current.copyWith(search: query);
  }

  void _selectCategory(String cat) {
    final current = ref.read(clothFilterProvider);
    ref.read(clothFilterProvider.notifier).state = current.copyWith(
      category: current.category == cat ? 'all' : cat,
    );
  }

  void _selectStatus(String status) {
    final current = ref.read(clothFilterProvider);
    ref.read(clothFilterProvider.notifier).state = current.copyWith(
      status: current.status == status ? 'all' : status,
    );
  }

  void _selectStyle(String style) {
    final current = ref.read(clothFilterProvider);
    ref.read(clothFilterProvider.notifier).state = current.copyWith(
      style: current.style == style ? 'all' : style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider).value;
    final clothesState = ref.watch(clothesListProvider);
    final allClothes = clothesState.value ?? [];
    final filtered = ref.watch(filteredClothesProvider);
    final filter = ref.watch(clothFilterProvider);

    final favoriteIds = ref.watch(favoriteClothIdsProvider);
    final washingIds = ref.watch(washingClothIdsProvider);

    // Hitung item per kategori untuk badge angka
    final outerCount =
        allClothes.where((c) => c.category == ClothCategory.outer).length;
    final shoesCount =
        allClothes.where((c) => c.category == ClothCategory.shoes).length;
    final accessoryCount =
        allClothes.where((c) => c.category == ClothCategory.accessory).length;
    final topCount =
        allClothes.where((c) => c.category == ClothCategory.top).length;
    final bottomCount =
        allClothes.where((c) => c.category == ClothCategory.bottom).length;
    final onepieceCount =
        allClothes.where((c) => c.category == ClothCategory.onepiece).length;

    // Hitung status Siap Pakai vs Sedang Dicuci
    final washingCount =
        allClothes.where((c) => washingIds.contains(c.id)).length;
    final readyCount = allClothes.length - washingCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(clothesListProvider);
          },
          child: CustomScrollView(
            slivers: [
              // 1. Header (Avatar, Title, Notification & Filter Icons)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                  child: _buildHeader(user),
                ),
              ),

              // 2. Search Bar & Count Pill
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _buildSearchAndCountRow(allClothes.length),
                ),
              ),

              // 3. AI Auto-Detect Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildAiAutoDetectBanner(),
                ),
              ),

              // 4. Kategori Koleksi Header & Horizontal Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: _buildCategoriesSection(
                    filter: filter,
                    allCount: allClothes.length,
                    outerCount: outerCount,
                    shoesCount: shoesCount,
                    accessoryCount: accessoryCount,
                    topCount: topCount,
                    bottomCount: bottomCount,
                    onepieceCount: onepieceCount,
                  ),
                ),
              ),

              // 5. Sub-filter Row (Siap Pakai, Sedang Dicuci, Gaya)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 14),
                  child: _buildSubFiltersRow(
                    filter: filter,
                    readyCount: readyCount,
                    washingCount: washingCount,
                  ),
                ),
              ),

              // 6. Grid Koleksi Pakaian
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildClothesContent(
                  clothesState: clothesState,
                  filtered: filtered,
                  filter: filter,
                  favoriteIds: favoriteIds,
                  washingIds: washingIds,
                ),
              ),

              // Bottom Padding untuk FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClothModal,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: const Icon(
          Icons.add_a_photo_outlined,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Tambah Pakaian',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==================== 1. HEADER ====================
  Widget _buildHeader(dynamic user) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
          backgroundImage: user?.photoUrl != null
              ? CachedNetworkImageProvider(user!.photoUrl!)
              : null,
          child: user?.photoUrl == null
              ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 24)
              : null,
        ),
        const SizedBox(width: 12),
        // Judul Lemari
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PakeAja Wardrobe',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lemari Digital',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Tombol Lonceng Notifikasi
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2C3E50),
              size: 21,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lemari pakaian Anda sudah tersinkronisasi.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Tombol Filter & Sort (Tune)
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF2C3E50),
              size: 21,
            ),
            onPressed: _showFilterAndSortModal,
          ),
        ),
      ],
    );
  }

  // ==================== 2. SEARCH & COUNT ROW ====================
  Widget _buildSearchAndCountRow(int totalCount) {
    return Row(
      children: [
        // Input Pencarian
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari pakaian, bahan, warna...',
                hintStyle:
                    const TextStyle(color: Color(0xFF8E959E), fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8E959E),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF8E959E)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Badge Total Pakaian
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.checkroom_outlined,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '$totalCount Pakaian',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 3. AI AUTO-DETECT BANNER ====================
  Widget _buildAiAutoDetectBanner() {
    return GestureDetector(
      onTap: () => context.push('/cloth/add?source=camera'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ikon Kotak Merah Muda
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Teks Banner
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Auto-Detect Siap',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F7EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CEPAT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E8E3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Pindai pakaian baru lewat kamera untuk potong latar otomatis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Panah Kanan
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5A626A),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 4. KATEGORI KOLEKSI ====================
  Widget _buildCategoriesSection({
    required ClothFilter filter,
    required int allCount,
    required int outerCount,
    required int shoesCount,
    required int accessoryCount,
    required int topCount,
    required int bottomCount,
    required int onepieceCount,
  }) {
    final categories = [
      {'key': 'all', 'label': 'Semua', 'count': allCount},
      {'key': 'outer', 'label': 'Outerwear', 'count': outerCount},
      {'key': 'shoes', 'label': 'Alas Kaki', 'count': shoesCount},
      {'key': 'accessory', 'label': 'Aksesoris', 'count': accessoryCount},
      {'key': 'top', 'label': 'Atasan', 'count': topCount},
      {'key': 'bottom', 'label': 'Bawahan', 'count': bottomCount},
      {'key': 'onepiece', 'label': 'One-piece', 'count': onepieceCount},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KATEGORI KOLEKSI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF6B7280),
                ),
              ),
              GestureDetector(
                onTap: _showManageCategoriesModal,
                child: const Text(
                  'Atur Kategori',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final key = cat['key'] as String;
              final label = cat['label'] as String;
              final count = cat['count'] as int;
              final isSelected = filter.category == key;

              return GestureDetector(
                onTap: () => _selectCategory(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E2022),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 5. SUB-FILTERS ROW ====================
  Widget _buildSubFiltersRow({
    required ClothFilter filter,
    required int readyCount,
    required int washingCount,
  }) {
    final isReadySelected = filter.status == 'ready';
    final isWashingSelected = filter.status == 'washing';
    final isCasualSelected = filter.style == 'casual';
    final isFormalSelected = filter.style == 'formal';
    final isSmartCasualSelected = filter.style == 'semi-formal';
    final isSportSelected = filter.style == 'sport';

    return SizedBox(
      height: 36,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          // 1. Siap Pakai Filter Chip
          GestureDetector(
            onTap: () => _selectStatus('ready'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isReadySelected
                    ? const Color(0xFFDCEEE2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isReadySelected
                      ? const Color(0xFFB8DEC4)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Siap Pakai ($readyCount)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isReadySelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isReadySelected
                          ? const Color(0xFF1B4328)
                          : const Color(0xFF2E5B3C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Sedang Dicuci Filter Chip
          GestureDetector(
            onTap: () => _selectStatus('washing'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isWashingSelected
                    ? const Color(0xFFEEF2FA)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isWashingSelected
                      ? const Color(0xFFD0DCF2)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A6572),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sedang Dicuci ($washingCount)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isWashingSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: const Color(0xFF4A6572),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Casual Style Chip
          GestureDetector(
            onTap: () => _selectStyle('casual'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isCasualSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCasualSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dry_cleaning_outlined,
                    size: 15,
                    color: isCasualSelected
                        ? Colors.white
                        : const Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Casual',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCasualSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCasualSelected
                          ? Colors.white
                          : const Color(0xFF1E2022),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Formal Style Chip
          GestureDetector(
            onTap: () => _selectStyle('formal'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isFormalSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFormalSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                'Formal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isFormalSelected ? FontWeight.bold : FontWeight.w500,
                  color: isFormalSelected
                      ? Colors.white
                      : const Color(0xFF1E2022),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Smart Casual
          GestureDetector(
            onTap: () => _selectStyle('semi-formal'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSmartCasualSelected
                    ? AppTheme.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSmartCasualSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                'Smart Casual',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSmartCasualSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isSmartCasualSelected
                      ? Colors.white
                      : const Color(0xFF1E2022),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Sport
          GestureDetector(
            onTap: () => _selectStyle('sport'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSportSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSportSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                'Sport',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSportSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSportSelected
                      ? Colors.white
                      : const Color(0xFF1E2022),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6. CLOTHES CONTENT ====================
  Widget _buildClothesContent({
    required AsyncValue<List<ClothModel>> clothesState,
    required List<ClothModel> filtered,
    required ClothFilter filter,
    required Set<String> favoriteIds,
    required Set<String> washingIds,
  }) {
    if (clothesState.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: LoadingWidget(message: 'Membuka lemari digital...'),
        ),
      );
    }

    if (clothesState.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ErrorWidgetPage(
            message: clothesState.error.toString(),
            onRetry: () => ref.invalidate(clothesListProvider),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: _buildEmptyState(filter),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cloth = filtered[index];
          final isFav = favoriteIds.contains(cloth.id);
          final isWash = washingIds.contains(cloth.id);

          return ClothingCard(
            cloth: cloth,
            isFavorite: isFav,
            isWashing: isWash,
            onFavoriteToggle: () {
              final favs = ref.read(favoriteClothIdsProvider);
              if (favs.contains(cloth.id)) {
                ref.read(favoriteClothIdsProvider.notifier).state =
                    {...favs}..remove(cloth.id);
              } else {
                ref.read(favoriteClothIdsProvider.notifier).state =
                    {...favs, cloth.id};
              }
            },
            onStatusToggle: () {
              final wash = ref.read(washingClothIdsProvider);
              if (wash.contains(cloth.id)) {
                ref.read(washingClothIdsProvider.notifier).state =
                    {...wash}..remove(cloth.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${cloth.name}" ditandai Siap Pakai.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                ref.read(washingClothIdsProvider.notifier).state =
                    {...wash, cloth.id};
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${cloth.name}" ditandai Sedang Dicuci.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            onTap: () => context.push('/cloth/${cloth.id}'),
            onLongPress: () => _showOptions(cloth),
            onEdit: () => context.push('/cloth/${cloth.id}/edit'),
            onDelete: () => _confirmDelete(cloth),
          );
        },
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildEmptyState(ClothFilter filter) {
    if (filter.isActive) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Color(0xFFBDC3C7)),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada pakaian yang cocok',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba sesuaikan pencarian atau reset filter kamu.',
              style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                ref.read(clothFilterProvider.notifier).state =
                    const ClothFilter();
              },
              child: const Text('Reset Filter'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          const Icon(Icons.checkroom_outlined,
              size: 54, color: Color(0xFFBDC3C7)),
          const SizedBox(height: 14),
          const Text(
            'Lemari kamu masih kosong',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai foto baju kamu sekarang biar AI PakeAja yang cocokin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => context.push('/cloth/add'),
            icon: const Icon(Icons.add_a_photo_outlined,
                size: 18, color: Colors.white),
            label: const Text(
              'Tambah Pakaian Pertama',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODALS & ACTIONS ====================
  void _showAddClothModal() {
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
                  'Tambah Pakaian ke Lemari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih metode pengambilan foto pakaian kamu:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera_outlined,
                        color: AppTheme.primaryColor),
                  ),
                  title: const Text('Ambil Foto Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('AI memotong latar otomatis'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/cloth/add?source=camera');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image_outlined,
                        color: AppTheme.primaryColor),
                  ),
                  title: const Text('Pilih dari Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Gunakan foto yang sudah ada'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/cloth/add?source=gallery');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManageCategoriesModal() {
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
                const Text(
                  'Kategori Koleksi Lemari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Koleksi pakaian kamu dikelompokkan secara otomatis berdasarkan kategori berikut:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                for (final cat in AppConstants.clothCategories.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.checkroom,
                        color: AppTheme.primaryColor),
                    title: Text(cat.value,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('ID Kategori: ${cat.key}'),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF9E9E9E)),
                    onTap: () {
                      Navigator.pop(context);
                      _selectCategory(cat.key);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterAndSortModal() {
    final filter = ref.read(clothFilterProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Urutkan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(clothFilterProvider.notifier).state =
                                const ClothFilter();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset',
                              style: TextStyle(color: AppTheme.primaryColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Warna
                    const Text('Warna Pakaian',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: filter.color == 'all',
                            onSelected: (_) {
                              ref.read(clothFilterProvider.notifier).state =
                                  filter.copyWith(color: 'all');
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          for (final color in AppConstants.clothColors.entries) ...[
                            ChoiceChip(
                              label: Text(color.value),
                              selected: filter.color == color.key,
                              onSelected: (_) {
                                ref.read(clothFilterProvider.notifier).state =
                                    filter.copyWith(color: color.key);
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Gaya
                    const Text('Gaya / Style',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: filter.style == 'all',
                            onSelected: (_) {
                              ref.read(clothFilterProvider.notifier).state =
                                  filter.copyWith(style: 'all');
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          for (final st in AppConstants.styles.entries) ...[
                            ChoiceChip(
                              label: Text(st.value),
                              selected: filter.style == st.key,
                              onSelected: (_) {
                                ref.read(clothFilterProvider.notifier).state =
                                    filter.copyWith(style: st.key);
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOptions(ClothModel cloth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Detail Pakaian'),
              onTap: () {
                context.pop();
                context.push('/cloth/${cloth.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor),
              title: const Text('Hapus Pakaian',
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pakaian'),
        content: Text(
            'Yakin hapus "${cloth.name}" dari lemari kamu? Tindakan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final user = ref.read(authStateProvider).value;
              if (user == null) return;

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Menghapus "${cloth.name}"...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              final success = await ref
                  .read(deleteClothProvider.notifier)
                  .deleteCloth(
                    uid: user.uid,
                    clothId: cloth.id,
                    imageUrl: cloth.imageUrl,
                  );

              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pakaian berhasil dihapus.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } else {
                final err = ref.read(deleteClothProvider).error?.toString() ??
                    'Gagal menghapus pakaian.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $err'),
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
