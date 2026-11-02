import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  final String occasion;

  const RecommendationScreen({super.key, this.occasion = 'Kuliah'});

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  late String _selectedAgenda;

  // Custom assigned items jika pengguna mengganti item tertentu (swap)
  final Map<ClothCategory, ClothModel?> _customSwapped = {};

  final List<Map<String, dynamic>> _agendaList = [
    {
      'label': 'Kuliah Pagi',
      'occasion': 'Kuliah',
      'sublabel': 'Kuliah & Kafe',
      'icon': Icons.school_rounded,
    },
    {
      'label': 'Santai Hangout',
      'occasion': 'Santai',
      'sublabel': 'Santai & Liburan',
      'icon': Icons.coffee_outlined,
    },
    {
      'label': 'Formal Presentasi',
      'occasion': 'Formal',
      'sublabel': 'Meeting & Kantor',
      'icon': Icons.work_outline_rounded,
    },
    {
      'label': 'Semi Formal',
      'occasion': 'Semi Formal',
      'sublabel': 'Smart Casual',
      'icon': Icons.badge_outlined,
    },
    {
      'label': 'Olahraga Aktif',
      'occasion': 'Olahraga',
      'sublabel': 'Aktivitas Luar',
      'icon': Icons.directions_run_rounded,
    },
    {
      'label': 'Organisasi',
      'occasion': 'Organisasi',
      'sublabel': 'Rapat & Diskusi',
      'icon': Icons.groups_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedAgenda = widget.occasion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).recommend(_getOccasionKey());
    });
  }

  String _getOccasionKey() {
    final matched = _agendaList.firstWhere(
      (a) => a['label'] == _selectedAgenda || a['occasion'] == _selectedAgenda,
      orElse: () => _agendaList.first,
    );
    return matched['occasion'] as String;
  }

  void _onAgendaSelected(String label) {
    if (_selectedAgenda == label) return;
    setState(() {
      _selectedAgenda = label;
      _customSwapped.clear(); // Reset custom swap saat ganti agenda
    });
    ref.read(recommendationProvider.notifier).recommend(_getOccasionKey());
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
    final recState = ref.watch(recommendationProvider);
    final clothes = ref.watch(clothesListProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            setState(() => _customSwapped.clear());
            await ref
                .read(recommendationProvider.notifier)
                .recommend(_getOccasionKey());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar / Header
                _buildHeader(),
                const SizedBox(height: 20),

                // 2. Pilih Agenda Hari Ini
                _buildAgendaSection(),
                const SizedBox(height: 18),

                // 3. Recommendation Main Card & Content
                if (recState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'AI Stylist sedang memilih padu-padan terbaik...',
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
                  _buildMissingClothesWidget()
                else if (recState.recommendation != null)
                  _buildRecommendationCard(
                    rec: recState.recommendation!,
                    clothes: clothes,
                  )
                else
                  _buildEmptyState(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 1. TOP BAR / HEADER ====================
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ikon Sparkle Peach Circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE8E8),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFAD1D1)),
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Title & Subtitles
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Stylist',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5056),
                ),
              ),
              Text(
                'Rekomendasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Padu-padan cerdas dari isi lemarimu',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        // Weather Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              Icon(Icons.wb_sunny_outlined,
                  size: 15, color: Color(0xFF4A5056)),
              SizedBox(width: 5),
              Text(
                '28°C',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Notification Bell Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rekomendasi disesuaikan dengan cuaca hari ini.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 2. PILIH AGENDA ====================
  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Agenda Hari Ini',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: _showFilterModal,
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _agendaList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final agenda = _agendaList[index];
              final label = agenda['label'] as String;
              final isSelected = _selectedAgenda == label ||
                  _selectedAgenda == agenda['occasion'];

              return GestureDetector(
                onTap: () => _onAgendaSelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E2022)
                        : Colors.white,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        agenda['icon'] as IconData,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF5A626A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2C3E50),
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

  // ==================== 3. KARTU REKOMENDASI OUTFIT ====================
  Widget _buildRecommendationCard({
    required OutfitRecommendation rec,
    required List<ClothModel> clothes,
  }) {
    // Ambil item dari rec.itemIds
    final initialItems = rec.itemIds
        .map((id) => clothes.firstWhere(
              (c) => c.id == id,
              orElse: () => clothes.first,
            ))
        .toList();

    // Petakan ke masing-masing slot (Atasan, Bawahan, Sepatu, Outer)
    ClothModel? top = _customSwapped[ClothCategory.top] ??
        initialItems.cast<ClothModel?>().firstWhere(
              (c) => c?.category == ClothCategory.top,
              orElse: () => initialItems.cast<ClothModel?>().firstWhere(
                    (c) => c?.category == ClothCategory.onepiece,
                    orElse: () => null,
                  ),
            );

    ClothModel? bottom = _customSwapped[ClothCategory.bottom] ??
        initialItems.cast<ClothModel?>().firstWhere(
              (c) => c?.category == ClothCategory.bottom,
              orElse: () => null,
            );

    ClothModel? shoes = _customSwapped[ClothCategory.shoes] ??
        initialItems.cast<ClothModel?>().firstWhere(
              (c) => c?.category == ClothCategory.shoes,
              orElse: () => null,
            );

    ClothModel? layering = _customSwapped[ClothCategory.outer] ??
        initialItems.cast<ClothModel?>().firstWhere(
              (c) =>
                  c?.category == ClothCategory.outer ||
                  c?.category == ClothCategory.accessory,
              orElse: () => null,
            );

    // Kumpulan item aktif untuk aksi & palette
    final activeItems = [
      if (top != null) top,
      if (bottom != null) bottom,
      if (shoes != null) shoes,
      if (layering != null) layering,
    ];

    // Info agenda & sublabel
    final currentAgenda = _agendaList.firstWhere(
      (a) => a['label'] == _selectedAgenda || a['occasion'] == _selectedAgenda,
      orElse: () => _agendaList.first,
    );
    final sublabel = currentAgenda['sublabel'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu: 98% Sangat Serasi, Sublabel, Palette Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Cocok Hijau
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F3E4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF1E8E3E),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '98% Sangat Serasi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF167C37),
                      ),
                    ),
                  ],
                ),
              ),
              // Sublabel acara
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A626A),
                ),
              ),
              // Dots Palet Warna
              _buildColorPaletteDots(activeItems),
            ],
          ),
          const SizedBox(height: 16),

          // Grid 2x2 Pakaian: Atasan, Bawahan, Sepatu, Layering
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildItemCard(
                  item: top,
                  slotLabel: 'Atasan',
                  category: ClothCategory.top,
                  clothes: clothes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildItemCard(
                  item: bottom,
                  slotLabel: 'Bawahan',
                  category: ClothCategory.bottom,
                  clothes: clothes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildItemCard(
                  item: shoes,
                  slotLabel: 'Sepatu',
                  category: ClothCategory.shoes,
                  clothes: clothes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildItemCard(
                  item: layering,
                  slotLabel: 'Layering (Opsi)',
                  category: ClothCategory.outer,
                  clothes: clothes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Catatan Stylist AI
          _buildStylistNotes(top, bottom),
          const SizedBox(height: 18),

          // Tombol Aksi: Pakai Hari Ini & Simpan Favorit & Acak Ulang
          _buildActionButtons(activeItems, rec.occasion),
        ],
      ),
    );
  }

  // ==================== ITEM CARD DALAM GRID 2x2 ====================
  Widget _buildItemCard({
    required ClothModel? item,
    required String slotLabel,
    required ClothCategory category,
    required List<ClothModel> clothes,
  }) {
    if (item == null) {
      // Slot kosong / belum ada
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F2)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                slotLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.add_circle_outline_rounded,
                size: 28, color: Colors.grey[400]),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openSwapModal(category, clothes),
              child: Text(
                'Pilih $slotLabel',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header slot: Label slot & Tombol Swap
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEF0F2)),
                ),
                child: Text(
                  slotLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5056),
                  ),
                ),
              ),
              // Tombol Swap Ganti Item
              GestureDetector(
                onTap: () => _openSwapModal(category, clothes),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 15,
                      color: Color(0xFF5A626A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Area Gambar Pakaian
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 118,
              width: double.infinity,
              color: Colors.white,
              child: ClothImageView(
                imageUrl: item.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nama Pakaian
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),

          // Subtitle Gaya & Warna
          Text(
            '${item.styles.isNotEmpty ? item.styles.first.label : 'Casual'} • ${item.colorLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CATATAN STYLIST AI ====================
  Widget _buildStylistNotes(ClothModel? top, ClothModel? bottom) {
    final topName = top != null ? top.name : 'atasan favorit';
    final bottomName = bottom != null ? bottom.name : 'celana bahan';

    final text = _getPersonalizedStylistNote(topName, bottomName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.smart_toy_outlined,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFF4A4A4A),
                ),
                children: [
                  const TextSpan(
                    text: 'Catatan Stylist: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPersonalizedStylistNote(String topName, String bottomName) {
    if (_selectedAgenda.contains('Kuliah')) {
      return '"Paduan $topName dan $bottomName warna netral memberi kesan rapi namun santai, ideal untuk suhu 28°C hari ini."';
    } else if (_selectedAgenda.contains('Santai')) {
      return '"Kombinasi kasual yang nyaman dan bernapas, pas untuk nongkrong dan santai seharian."';
    } else if (_selectedAgenda.contains('Formal')) {
      return '"Kombinasi $topName dan $bottomName memberikan tampilan profesional, bersih, dan berwibawa."';
    } else if (_selectedAgenda.contains('Olahraga')) {
      return '"Material elastis dan fleksibel memberikan sirkulasi udara optimal untuk mobilitas tinggi."';
    }
    return '"Kombinasi warna yang harmonis dari lemarimu, siap menemani aktivitas dengan rasa percaya diri."';
  }

  // ==================== COLOR PALETTE DOTS ====================
  Widget _buildColorPaletteDots(List<ClothModel> items) {
    final colors =
        items.map((c) => _mapClothColor(c.color)).toSet().toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in colors.take(3))
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1),
            ),
          ),
      ],
    );
  }

  Color _mapClothColor(String c) {
    switch (c.toLowerCase()) {
      case 'black':
        return const Color(0xFF212121);
      case 'white':
        return const Color(0xFFF3EFE0);
      case 'gray':
        return const Color(0xFF9E9E9E);
      case 'navy':
        return const Color(0xFF1E3A5F);
      case 'blue':
        return const Color(0xFF4A90E2);
      case 'red':
        return const Color(0xFFD9383A);
      case 'green':
        return const Color(0xFF4E7D55);
      case 'brown':
        return const Color(0xFF8D6E63);
      case 'cream':
        return const Color(0xFFEFE4D2);
      default:
        return const Color(0xFFC7A788);
    }
  }

  // ==================== TOMBOL AKSI ====================
  Widget _buildActionButtons(List<ClothModel> items, String occasion) {
    final itemIds = items.map((c) => c.id).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _wearOutfit(itemIds, occasion),
                  icon: const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Pakai Hari Ini',
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
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => _saveFavorite(itemIds, occasion),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E4E8), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
        SizedBox(
          width: double.infinity,
          height: 38,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _customSwapped.clear());
              ref
                  .read(recommendationProvider.notifier)
                  .reshuffle(_getOccasionKey());
            },
            icon: const Icon(Icons.sync_rounded,
                size: 18, color: Color(0xFF5A626A)),
            label: const Text(
              'Acak Ulang Kombinasi',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A626A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SWAP MODAL ====================
  void _openSwapModal(ClothCategory category, List<ClothModel> clothes) {
    // Cari semua pakaian yang kategorinya sama
    final candidates = clothes.where((c) {
      if (category == ClothCategory.outer) {
        return c.category == ClothCategory.outer ||
            c.category == ClothCategory.accessory;
      }
      return c.category == category;
    }).toList();

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
                  Text(
                    'Ganti ${category.label}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih alternatif ${category.label.toLowerCase()} dari lemari kamu:',
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 16),
                  if (candidates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'Belum ada pilihan ${category.label.toLowerCase()} lain di lemarimu.',
                          style: const TextStyle(color: Color(0xFF757575)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFF0F0F2),
                        ),
                        itemBuilder: (context, index) {
                          final item = candidates[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            leading: ClothImageView(
                              imageUrl: item.imageUrl,
                              width: 48,
                              height: 48,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${item.styles.isNotEmpty ? item.styles.first.label : 'Casual'} • ${item.colorLabel}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF757575)),
                            ),
                            trailing: const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.primaryColor,
                            ),
                            onTap: () {
                              setState(() {
                                _customSwapped[category] = item;
                              });
                              Navigator.pop(context);
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

  // ==================== FILTER MODAL ====================
  void _showFilterModal() {
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
                  'Preferensi AI Stylist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI PakeAja meracik outfit dengan menganalisis kecocokan warna analogus, rotasi pakaian yang jarang dipakai, dan kondisi cuaca 28°C.',
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
                    child: const Text('Terapkan',
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

  // ==================== ACTION LOGIC ====================
  Future<void> _wearOutfit(List<String> itemIds, String occasion) async {
    final success = await ref
        .read(wearOutfitProvider.notifier)
        .wearOutfit(itemIds: itemIds, occasion: occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit tercatat di riwayat pemakaian. Tetap gaya!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _saveFavorite(List<String> itemIds, String occasion) async {
    final success = await ref
        .read(saveOutfitProvider.notifier)
        .saveOutfit(itemIds: itemIds, occasion: occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit berhasil disimpan ke Favorit!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Widget _buildMissingClothesWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        children: [
          const Icon(Icons.checkroom_outlined,
              size: 40, color: Color(0xFFD97706)),
          const SizedBox(height: 10),
          const Text(
            'Belum Cukup Pakaian',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan minimal 1 atasan, 1 bawahan, dan 1 sepatu agar AI Stylist bisa meracik outfit kamu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.push('/cloth/add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tambah Pakaian Sekarang',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, size: 40, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 10),
            const Text(
              'Belum ada rekomendasi yang dibuat',
              style: TextStyle(color: Color(0xFF757575), fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(recommendationProvider.notifier)
                    .recommend(_getOccasionKey());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Mulai Racik',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
