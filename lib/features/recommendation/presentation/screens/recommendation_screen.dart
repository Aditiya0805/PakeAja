import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/core/widgets/menu_hero_header.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:pakeaja/features/weather/providers/weather_provider.dart';

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
      'emoji': '🎓',
      'gradient': [const Color(0xFF6C63FF), const Color(0xFF9B59B6)],
    },
    {
      'label': 'Santai Hangout',
      'occasion': 'Santai',
      'sublabel': 'Santai & Liburan',
      'icon': Icons.coffee_outlined,
      'emoji': '☕',
      'gradient': [const Color(0xFFFF7043), const Color(0xFFFFB74D)],
    },
    {
      'label': 'Formal Presentasi',
      'occasion': 'Formal',
      'sublabel': 'Meeting & Kantor',
      'icon': Icons.work_outline_rounded,
      'emoji': '💼',
      'gradient': [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    },
    {
      'label': 'Semi Formal',
      'occasion': 'Semi Formal',
      'sublabel': 'Smart Casual',
      'icon': Icons.badge_outlined,
      'emoji': '👔',
      'gradient': [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
    },
    {
      'label': 'Olahraga Aktif',
      'occasion': 'Olahraga',
      'sublabel': 'Aktivitas Luar',
      'icon': Icons.directions_run_rounded,
      'emoji': '🏃',
      'gradient': [const Color(0xFFF44336), const Color(0xFFFF7043)],
    },
    {
      'label': 'Organisasi',
      'occasion': 'Organisasi',
      'sublabel': 'Rapat & Diskusi',
      'icon': Icons.groups_outlined,
      'emoji': '🤝',
      'gradient': [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
    },
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(recommendationProvider);
    final initialOccasion =
        widget.occasion != 'Kuliah' ? widget.occasion : state.selectedOccasion;
    _selectedAgenda = _getAgendaLabelForOccasion(initialOccasion);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latest = ref.read(recommendationProvider);
      if (widget.occasion != 'Kuliah' &&
          latest.selectedOccasion != widget.occasion) {
        ref.read(recommendationProvider.notifier).recommend(widget.occasion);
      } else if (latest.recommendation == null &&
          latest.error == null &&
          !latest.isLoading) {
        ref.read(recommendationProvider.notifier).recommend(_getOccasionKey());
      }
    });
  }

  String _getAgendaLabelForOccasion(String occasion) {
    final lower = occasion.toLowerCase().replaceAll('-', ' ');
    for (final agenda in _agendaList) {
      final occ =
          (agenda['occasion'] as String).toLowerCase().replaceAll('-', ' ');
      final label =
          (agenda['label'] as String).toLowerCase().replaceAll('-', ' ');
      if (occ == lower ||
          label == lower ||
          lower.contains(occ) ||
          occ.contains(lower)) {
        return agenda['label'] as String;
      }
    }
    return _agendaList.first['label'] as String;
  }

  String _getOccasionKey() {
    final target = _selectedAgenda.toLowerCase().replaceAll('-', ' ');
    final matched = _agendaList.firstWhere(
      (a) {
        final label =
            (a['label'] as String).toLowerCase().replaceAll('-', ' ');
        final occasion =
            (a['occasion'] as String).toLowerCase().replaceAll('-', ' ');
        return label == target ||
            occasion == target ||
            target.contains(occasion) ||
            occasion.contains(target);
      },
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
    final syncedLabel = _getAgendaLabelForOccasion(recState.selectedOccasion);
    if (_selectedAgenda != syncedLabel) {
      _selectedAgenda = syncedLabel;
      _customSwapped.clear();
    }
    final clothes = ref.watch(clothesListProvider).valueOrNull ?? [];
    final weatherState = ref.watch(weatherProvider);

    // Otomatis buat rekomendasi jika pakaian sudah cukup dan rekomendasi masih kosong
    if (_hasEnoughClothes(clothes) &&
        recState.recommendation == null &&
        recState.error == null &&
        !recState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latest = ref.read(recommendationProvider);
        if (mounted &&
            latest.recommendation == null &&
            latest.error == null &&
            !latest.isLoading) {
          ref.read(recommendationProvider.notifier).recommend(_getOccasionKey());
        }
      });
    }

    return Scaffold(
      backgroundColor: MenuUiColors.surface,
      body: RefreshIndicator(
        color: MenuUiColors.crimson,
        onRefresh: () async {
          setState(() => _customSwapped.clear());
          await Future.wait([
            ref.read(weatherProvider.notifier).refresh(),
            ref.read(recommendationProvider.notifier).recommend(_getOccasionKey()),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hero Header gradasi crimson mengikuti HomeScreen
            SliverToBoxAdapter(
              child: _buildHeroHeader(recState, clothes, weatherState),
            ),

            // 2. Pilih Agenda Hari Ini
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _buildAgendaSection(),
              ),
            ),

            // 3. Recommendation Main Card & Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
              sliver: SliverToBoxAdapter(
                child: recState.isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  MenuUiColors.crimson,
                                ),
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'AI Stylist sedang memilih padu-padan terbaik...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MenuUiColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : !_hasEnoughClothes(clothes)
                        ? _buildMissingClothesWidget()
                        : recState.error != null
                            ? _buildIncompatibleOccasionWidget(
                                recState.error!,
                                _getOccasionKey(),
                              )
                            : recState.recommendation != null
                                ? _buildRecommendationCard(
                                    rec: recState.recommendation!,
                                    clothes: clothes,
                                  )
                                : _buildEmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1. HERO HEADER ====================
  Widget _buildHeroHeader(
    RecommendationState recState,
    List<ClothModel> clothes,
    WeatherState weatherState,
  ) {
    final weather = weatherState.data;
    final weatherEmoji =
        weather != null ? weather.emoji : (weatherState.isLoading ? '📍' : '🌦️');
    final weatherBadgeText = weather != null
        ? weather.tempText
        : (weatherState.isLoading ? '...' : 'Lokasi');
    final weatherDesc = weather != null
        ? 'Rekomendasi disesuaikan dengan cuaca ${weather.tempText} (${weather.conditionLabel}) di ${weather.locationName}.'
        : 'Aktifkan izin lokasi agar rekomendasi menyesuaikan cuaca daerahmu.';
    return MenuHeroHeader(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
      subtitle: 'AI Stylist',
      title: 'Rekomendasi',
      caption: 'Padu-padan cerdas dari isi lemarimu',
      actions: [
        GestureDetector(
          onTap: () => ref.read(weatherProvider.notifier).refresh(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(weatherEmoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  weatherBadgeText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        HeroGlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(weatherDesc),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
      statChips: [
        HeroStatChip(
          icon: Icons.event_note_rounded,
          label: 'Agenda: ${_getOccasionKey()}',
        ),
        HeroStatChip(
          icon: Icons.checkroom_outlined,
          label: '${clothes.length} Item Lemari',
        ),
        if (recState.recommendation != null)
          HeroStatChip(
            icon: Icons.verified_outlined,
            label: '${recState.recommendation!.score.round()}% Cocok',
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MenuUiColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: _showFilterModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: MenuUiColors.crimson.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 14, color: MenuUiColors.crimson),
                    SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MenuUiColors.crimson,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _agendaList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final agenda = _agendaList[index];
              final label = agenda['label'] as String;
              final gradColors = agenda['gradient'] as List<Color>;
              final isSelected = _selectedAgenda == label ||
                  _selectedAgenda == agenda['occasion'];

              return GestureDetector(
                onTap: () => _onAgendaSelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: gradColors)
                        : null,
                    color: isSelected ? null : MenuUiColors.cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : MenuUiColors.divider,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gradColors.first.withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        agenda['emoji'] as String,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : MenuUiColors.textPrimary,
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
    // Ambil item dari rec.itemIds secara aman tanpa fallback ke item acak
    final clothesById = {for (final c in clothes) c.id: c};
    final initialItems = rec.itemIds
        .map((id) => clothesById[id])
        .whereType<ClothModel>()
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
    final emoji = (currentAgenda['emoji'] as String?) ?? '👗';
    final gradColors = (currentAgenda['gradient'] as List<Color>?) ??
        [MenuUiColors.crimson, MenuUiColors.crimsonLight];

    return Container(
      decoration: BoxDecoration(
        color: MenuUiColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header strip mengikuti kartu Rekomendasi di HomeScreen
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradColors.first.withValues(alpha: 0.12),
                  gradColors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF1E8E3E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${rec.score.round()}% Sangat Serasi',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF167C37),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gradColors.first.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '$emoji $sublabel',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: gradColors.first,
                    ),
                  ),
                ),
                _buildColorPaletteDots(activeItems),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildStylistNotes(top, bottom, gradColors),
                const SizedBox(height: 18),

                // Tombol Aksi: Pakai Hari Ini & Simpan Favorit & Acak Ulang
                _buildActionButtons(activeItems, rec.occasion),
              ],
            ),
          ),
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
      return Container(
        height: 204,
        decoration: BoxDecoration(
          color: MenuUiColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MenuUiColors.divider),
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
                border: Border.all(color: MenuUiColors.divider),
              ),
              child: Text(
                slotLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MenuUiColors.textSecondary,
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
                  fontWeight: FontWeight.w700,
                  color: MenuUiColors.crimson,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: MenuUiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MenuUiColors.divider),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MenuUiColors.divider),
                ),
                child: Text(
                  slotLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MenuUiColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openSwapModal(category, clothes),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: MenuUiColors.crimson.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: MenuUiColors.crimson,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/cloth/${item.id}'),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MenuUiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.styles.isNotEmpty ? item.styles.map((s) => s.label).join(', ') : 'Casual'} • ${item.colorLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MenuUiColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CATATAN STYLIST AI ====================
  Widget _buildStylistNotes(
    ClothModel? top,
    ClothModel? bottom,
    List<Color> gradColors,
  ) {
    final topName = top != null ? top.name : 'atasan favorit';
    final bottomName = bottom != null ? bottom.name : 'celana bahan';
    final text = _getPersonalizedStylistNote(topName, bottomName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MenuUiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MenuUiColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradColors),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
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
                      color: MenuUiColors.crimson,
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
    if (_selectedAgenda.contains('Semi') || _selectedAgenda.contains('Smart')) {
      return '"Paduan semi-formal $topName dan $bottomName memberikan kesan rapi, profesional, dan tetap santai, sangat serasi untuk agenda Semi Formal hari ini."';
    } else if (_selectedAgenda.contains('Formal')) {
      return '"Setelan formal $topName dan $bottomName memberikan tampilan profesional, bersih, dan berwibawa."';
    } else if (_selectedAgenda.contains('Kuliah')) {
      return '"Paduan smart-casual $topName dan $bottomName memberi kesan rapi namun santai, ideal untuk aktivitas kampus hari ini."';
    } else if (_selectedAgenda.contains('Santai')) {
      return '"Kombinasi kasual yang nyaman dan bernapas, pas untuk nongkrong dan santai seharian."';
    } else if (_selectedAgenda.contains('Olahraga')) {
      return '"Setelan aktif $topName dan $bottomName memberikan sirkulasi udara optimal dan fleksibilitas untuk mobilitas tinggi."';
    } else if (_selectedAgenda.contains('Organisasi')) {
      return '"Setelan representatif $topName dan $bottomName memberikan kesan kredibel dan siap untuk forum organisasi."';
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
              child: PakeAjaGradientButton(
                onPressed: () => _wearOutfit(itemIds, occasion),
                icon: Icons.check_circle_outline,
                label: 'Pakai Hari Ini',
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              width: 48,
              child: OutlinedButton(
                onPressed: () => _saveFavorite(itemIds, occasion),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MenuUiColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: MenuUiColors.crimson,
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
                size: 18, color: MenuUiColors.crimson),
            label: const Text(
              'Acak Ulang Kombinasi',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: MenuUiColors.crimson,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SWAP MODAL ====================
  void _openSwapModal(ClothCategory category, List<ClothModel> clothes) {
    final occasionKey = _getOccasionKey();
    final service = ref.read(recommendationServiceProvider);

    // Cari pakaian yang kategorinya sama DAN layak untuk agenda yang sedang dipilih
    final candidates = clothes.where((c) {
      final matchesCategory = category == ClothCategory.outer
          ? (c.category == ClothCategory.outer ||
              c.category == ClothCategory.accessory)
          : category == ClothCategory.top
              ? (c.category == ClothCategory.top ||
                  c.category == ClothCategory.onepiece)
              : c.category == category;
      return matchesCategory && service.isSuitableForOccasion(c, occasionKey);
    }).toList();

    // Urutkan yang paling tepat sesuai gaya agenda
    final normOccasion = service.normalizeOccasion(occasionKey);
    candidates.sort((a, b) {
      final aStyles = service.getEffectiveStyleValues(a);
      final bStyles = service.getEffectiveStyleValues(b);
      final aExact = aStyles.contains(normOccasion);
      final bExact = bStyles.contains(normOccasion);
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

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
                          'Belum ada ${category.label.toLowerCase()} yang cocok untuk kategori $occasionKey di lemarimu.',
                          textAlign: TextAlign.center,
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
                              '${item.styles.isNotEmpty ? item.styles.map((s) => s.label).join(', ') : 'Casual'} • ${item.colorLabel}',
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
    final weather = ref.read(weatherProvider).data;
    final weatherSummary = weather != null
        ? 'kondisi cuaca ${weather.tempText} (${weather.conditionLabel}) di ${weather.locationName}'
        : 'kondisi cuaca di lokasimu';

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
                Text(
                  'AI PakeAja meracik outfit dengan menganalisis kecocokan warna analogus, rotasi pakaian yang jarang dipakai, dan $weatherSummary.',
                  style: const TextStyle(
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

  Widget _buildIncompatibleOccasionWidget(
    String errorMessage,
    String occasionKey,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFAD1D1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.style_outlined,
              size: 40, color: AppTheme.primaryColor),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Pakaian untuk $occasionKey',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF5A626A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/cloth/add'),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(
                  'Tambah Pakaian $occasionKey',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (occasionKey != 'Santai')
                OutlinedButton(
                  onPressed: () => _onAgendaSelected('Santai Hangout'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Lihat Santai'),
                ),
            ],
          ),
        ],
      ),
    );
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
