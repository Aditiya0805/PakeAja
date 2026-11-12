import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedOccasion = 'Kuliah';

  // Daftar occasion utama di beranda (sesuai tampilan desain)
  final List<Map<String, dynamic>> _occasions = [
    {
      'label': 'Kuliah',
      'subtitle': 'Casual & Rapi',
      'icon': Icons.school_rounded,
      'tag': 'Untuk Kuliah Pagi',
      'styleNote': 'Layering Katun',
    },
    {
      'label': 'Santai',
      'subtitle': 'Cozy Chic',
      'icon': Icons.coffee_outlined,
      'tag': 'Santai & Hangout',
      'styleNote': 'Cozy Minimalist',
    },
    {
      'label': 'Formal',
      'subtitle': 'Professional',
      'icon': Icons.work_outline_rounded,
      'tag': 'Pertemuan Formal',
      'styleNote': 'Professional Look',
    },
    {
      'label': 'Semi Formal',
      'subtitle': 'Smart Casual',
      'icon': Icons.badge_outlined,
      'tag': 'Acara Semi Formal',
      'styleNote': 'Smart Casual',
    },
    {
      'label': 'Olahraga',
      'subtitle': 'Active',
      'icon': Icons.directions_run_rounded,
      'tag': 'Aktivitas Olahraga',
      'styleNote': 'Breathable Active',
    },
    {
      'label': 'Organisasi',
      'subtitle': 'Presentable',
      'icon': Icons.groups_outlined,
      'tag': 'Rapat Organisasi',
      'styleNote': 'Rapi & Terstruktur',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi rekomendasi untuk occasion default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).recommend(_selectedOccasion);
    });
  }

  void _onOccasionSelected(String occasion) {
    if (_selectedOccasion == occasion) return;
    setState(() {
      _selectedOccasion = occasion;
    });
    ref.read(recommendationProvider.notifier).recommend(occasion);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  bool _hasEnoughClothes(List<ClothModel> clothes) {
    int tops = 0, bottoms = 0, shoes = 0, onepieces = 0;
    for (final c in clothes) {
      if (c.category == ClothCategory.top) tops++;
      if (c.category == ClothCategory.bottom) bottoms++;
      if (c.category == ClothCategory.shoes) shoes++;
      if (c.category == ClothCategory.onepiece) onepieces++;
    }
    return (tops >= 1 && bottoms >= 1 && shoes >= 1) ||
        (onepieces >= 1 && shoes >= 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider).valueOrNull;
    final clothes = ref.watch(clothesListProvider).valueOrNull ?? [];
    final recState = ref.watch(recommendationProvider);

    // Otomatis buat rekomendasi jika pakaian sudah cukup dan rekomendasi masih kosong
    if (_hasEnoughClothes(clothes) &&
        recState.recommendation == null &&
        !recState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(recommendationProvider).recommendation == null &&
            !ref.read(recommendationProvider).isLoading) {
          ref.read(recommendationProvider.notifier).recommend(_selectedOccasion);
        }
      });
    }

    final greeting = _getGreeting();
    final fullName = ref.watch(effectiveUserNameProvider).trim();
    final userName = fullName.isNotEmpty
        ? fullName.split(RegExp(r'\s+')).first
        : 'Pengguna';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            await ref
                .read(recommendationProvider.notifier)
                .recommend(_selectedOccasion);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Profil & Notifikasi)
                _buildHeader(user, greeting, userName),
                const SizedBox(height: 18),

                // 2. Weather & Outfit Tip Card
                _buildWeatherCard(),
                const SizedBox(height: 18),

                // 3. Banner Lemari Digital AI
                _buildAiWardrobeBanner(),
                const SizedBox(height: 24),

                // 4. Section "Hari ini mau ke mana?"
                _buildOccasionSection(),
                const SizedBox(height: 24),

                // 5. Section "Rekomendasi Hari Ini"
                _buildRecommendationSection(recState, clothes),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 1. HEADER ====================
  Widget _buildHeader(dynamic user, String greeting, String userName) {
    return Row(
      children: [
        // Avatar dengan status badge hijau
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
              backgroundImage: user?.photoUrl != null
                  ? CachedNetworkImageProvider(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 26)
                  : null,
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Halo, $userName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Tombol lonceng notifikasi
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2C3E50),
              size: 22,
            ),
            onPressed: _showNotificationBottomSheet,
          ),
        ),
      ],
    );
  }

  // ==================== 2. WEATHER CARD ====================
  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: _showWeatherDetailModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '28°C Cerah',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Jakarta Selatan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3B5998),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Pas untuk kemeja katun sejuk & celana linen.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 3. LEMARI DIGITAL AI BANNER ====================
  Widget _buildAiWardrobeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag & Icon Hanger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lemari Digital AI',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.checkroom_outlined,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teks Judul & Subtitle
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
            'Foto baju kamu, biar AI PakeAja yang cocokin.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Ambil Foto & Pilih Galeri
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/cloth/add?source=camera'),
                    icon: const Icon(Icons.photo_camera_outlined,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Ambil Foto',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/cloth/add?source=gallery'),
                    icon: const Icon(Icons.image_outlined,
                        size: 18, color: Color(0xFF2C3E50)),
                    label: const Text(
                      'Pilih Galeri',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                          color: Color(0xFFE2E4E8), width: 1.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 4. OCCASION SECTION ====================
  Widget _buildOccasionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hari ini mau ke mana?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: _showAllOccasionsModal,
              child: const Text(
                'Semua',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih agenda kamu, biar PakeAja racik outfit terbaik dari lemarimu.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemCount: _occasions.length,
          itemBuilder: (context, index) {
            final occ = _occasions[index];
            final label = occ['label'] as String;
            final isSelected = _selectedOccasion == label;

            return GestureDetector(
              onTap: () => _onOccasionSelected(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFFEEF0F2),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    // Titik badge merah di pojok kanan atas jika terpilih
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFFF7F8FA),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                occ['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF5A626A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              occ['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFF8E959E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== 5. REKOMENDASI SECTION ====================
  Widget _buildRecommendationSection(
    RecommendationState recState,
    List<ClothModel> clothes,
  ) {
    final currentOccData = _occasions.firstWhere(
      (o) => o['label'] == _selectedOccasion,
      orElse: () => {
        'label': _selectedOccasion,
        'tag': 'Untuk $_selectedOccasion',
        'styleNote': 'Gaya Pilihan',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header "Rekomendasi Hari Ini" + Badge "98% Cocok"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 19,
                ),
                SizedBox(width: 6),
                Text(
                  'Rekomendasi Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F7EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 7, color: Color(0xFF1E8E3E)),
                  const SizedBox(width: 5),
                  Text(
                    '${recState.recommendation != null ? recState.recommendation!.score.round() : 98}% Cocok',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF167C37),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Kartu Utama Rekomendasi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row Tags & Tombol Acak Ulang
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      currentOccData['tag'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF495057),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      currentOccData['styleNote'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF495057),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      ref
                          .read(recommendationProvider.notifier)
                          .reshuffle(_selectedOccasion);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F5F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        size: 19,
                        color: Color(0xFF495057),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Konten Rekomendasi
              if (recState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'AI sedang meracik paduan outfit terbaik...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_hasEnoughClothes(clothes))
                _buildMissingClothesChecklist(clothes)
              else if (recState.recommendation != null)
                _buildRecommendationContent(
                    recState.recommendation!, clothes)
              else
                _buildEmptyRecommendation(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingClothesChecklist(List<ClothModel> clothes) {
    int tops = 0, bottoms = 0, shoes = 0, onepieces = 0;
    for (final c in clothes) {
      if (c.category == ClothCategory.top) tops++;
      if (c.category == ClothCategory.bottom) bottoms++;
      if (c.category == ClothCategory.shoes) shoes++;
      if (c.category == ClothCategory.onepiece) onepieces++;
    }

    final hasTop = tops >= 1 || onepieces >= 1;
    final hasBottom = bottoms >= 1 || onepieces >= 1;
    final hasShoes = shoes >= 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lengkapi pakaian untuk rekomendasi AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _checkRow('Atasan / One-piece', hasTop),
          _checkRow('Bawahan', hasBottom),
          _checkRow('Sepatu', hasShoes),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/cloth/add'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD97706)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tambah Pakaian Sekarang',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? const Color(0xFF1E8E3E) : const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
              color: checked
                  ? const Color(0xFF1E2022)
                  : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.checkroom_outlined,
                size: 36, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 8),
            const Text(
              'Belum ada rekomendasi outfit yang dibuat.',
              style: TextStyle(color: Color(0xFF757575), fontSize: 13),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(recommendationProvider.notifier)
                    .recommend(_selectedOccasion);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Racik Sekarang',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationContent(
    OutfitRecommendation rec,
    List<ClothModel> clothes,
  ) {
    final items = rec.itemIds
        .map((id) => clothes.firstWhere(
              (c) => c.id == id,
              orElse: () => clothes.first,
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilan Kartu Visual Pakaian yang direkomendasikan
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF0F2)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                _buildClothItemRow(items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol Aksi Cepat
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _wearOutfit(rec),
                  icon: const Icon(Icons.check_circle_outline,
                      size: 17, color: Colors.white),
                  label: const Text(
                    'Pakai Hari Ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () => _saveFavorite(rec),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E4E8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              context.push(
                '/recommendation?occasion=${Uri.encodeComponent(_selectedOccasion)}',
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Detail & Rekomendasi Lengkap',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClothItemRow(ClothModel item) {
    return Row(
      children: [
        ClothImageView(
          imageUrl: item.imageUrl,
          width: 52,
          height: 52,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.colorLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ACTIONS & MODALS ====================
  Future<void> _wearOutfit(OutfitRecommendation rec) async {
    final success = await ref
        .read(wearOutfitProvider.notifier)
        .wearOutfit(itemIds: rec.itemIds, occasion: rec.occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit tercatat di riwayat pemakaian. Tetap gaya!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _saveFavorite(OutfitRecommendation rec) async {
    final success = await ref
        .read(saveOutfitProvider.notifier)
        .saveOutfit(itemIds: rec.itemIds, occasion: rec.occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit berhasil disimpan ke Favorit!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showNotificationBottomSheet() {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEF0F2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF1E8E3E), size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PakeAja Siap Bantu Outfit Kamu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Semua rekomendasi pakaian sudah diperbarui sesuai kondisi cuaca hari ini.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeatherDetailModal() {
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
                const Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded,
                        color: AppTheme.primaryColor, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Cuaca & Saran Busana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lokasi: Jakarta Selatan (28°C - Cerah)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kondisi cuaca hari ini hangat dengan kelembapan sedang. Sangat disarankan memakai pakaian berbahan katun, linen, atau rajutan tipis dengan warna terang agar tidak menyerap panas berlebih.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Mengerti',
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

  void _showAllOccasionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
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
                    'Pilih Agenda Acara',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI PakeAja akan menyesuaikan kombinasi pakaian terbaik untuk acara tersebut.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _occasions.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFF0F0F2),
                      ),
                      itemBuilder: (context, index) {
                        final item = _occasions[index];
                        final label = item['label'] as String;
                        final isSelected = _selectedOccasion == label;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFF7F8FA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5A626A),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF757575),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.primaryColor)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            _onOccasionSelected(label);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
