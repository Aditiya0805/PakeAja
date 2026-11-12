import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/data/models/weather_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:pakeaja/features/weather/providers/weather_provider.dart';

// ─── Palette ───────────────────────────────────────────────────────────────
const _crimson = Color(0xFFC4202F);
const _crimsonLight = Color(0xFFEF5537);
const _surface = Color(0xFFF6F7FA);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1D23);
const _textSecondary = Color(0xFF6B7280);
const _divider = Color(0xFFEDF0F3);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnimCtrl;
  late final AnimationController _cardPulseCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardPulse;

  final List<Map<String, dynamic>> _occasions = [
    {
      'label': 'Kuliah',
      'subtitle': 'Casual & Rapi',
      'icon': Icons.school_rounded,
      'tag': 'Untuk Kuliah Pagi',
      'styleNote': 'Layering Katun',
      'emoji': '🎓',
      'gradient': [const Color(0xFF6C63FF), const Color(0xFF9B59B6)],
    },
    {
      'label': 'Santai',
      'subtitle': 'Cozy Chic',
      'icon': Icons.coffee_outlined,
      'tag': 'Santai & Hangout',
      'styleNote': 'Cozy Minimalist',
      'emoji': '☕',
      'gradient': [const Color(0xFFFF7043), const Color(0xFFFFB74D)],
    },
    {
      'label': 'Formal',
      'subtitle': 'Professional',
      'icon': Icons.work_outline_rounded,
      'tag': 'Pertemuan Formal',
      'styleNote': 'Professional Look',
      'emoji': '💼',
      'gradient': [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    },
    {
      'label': 'Semi Formal',
      'subtitle': 'Smart Casual',
      'icon': Icons.badge_outlined,
      'tag': 'Acara Semi Formal',
      'styleNote': 'Smart Casual',
      'emoji': '👔',
      'gradient': [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
    },
    {
      'label': 'Olahraga',
      'subtitle': 'Active',
      'icon': Icons.directions_run_rounded,
      'tag': 'Aktivitas Olahraga',
      'styleNote': 'Breathable Active',
      'emoji': '🏃',
      'gradient': [const Color(0xFFF44336), const Color(0xFFFF7043)],
    },
    {
      'label': 'Organisasi',
      'subtitle': 'Presentable',
      'icon': Icons.groups_outlined,
      'tag': 'Rapat Organisasi',
      'styleNote': 'Rapi & Terstruktur',
      'emoji': '🤝',
      'gradient': [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
    },
  ];

  String get _selectedOccasion =>
      ref.read(recommendationProvider).selectedOccasion;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    ));
    _cardPulse = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardPulseCtrl, curve: Curves.easeOut),
    );

    _headerAnimCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(recommendationProvider);
      if (state.recommendation == null &&
          state.error == null &&
          !state.isLoading) {
        ref
            .read(recommendationProvider.notifier)
            .recommend(state.selectedOccasion);
      }
    });
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    _cardPulseCtrl.dispose();
    super.dispose();
  }

  void _onOccasionSelected(String occasion) {
    final current = ref.read(recommendationProvider);
    if (current.selectedOccasion == occasion &&
        (current.recommendation != null || current.error != null)) {
      return;
    }
    ref.read(recommendationProvider.notifier).recommend(occasion);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 11) return '🌤️';
    if (hour < 15) return '☀️';
    if (hour < 19) return '🌇';
    return '🌙';
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
    final weatherState = ref.watch(weatherProvider);
    final activeOccasion = recState.selectedOccasion;

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
          ref
              .read(recommendationProvider.notifier)
              .recommend(latest.selectedOccasion);
        }
      });
    }

    final greeting = _getGreeting();
    final fullName = ref.watch(effectiveUserNameProvider).trim();
    final userName = fullName.isNotEmpty
        ? fullName.split(RegExp(r'\s+')).first
        : 'Pengguna';

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: _crimson,
        onRefresh: () async {
          await Future.wait([
            ref.read(weatherProvider.notifier).refresh(),
            ref.read(recommendationProvider.notifier).recommend(activeOccasion),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero Header (gradient app bar) ──────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                user: user,
                greeting: greeting,
                greetingEmoji: _getGreetingEmoji(),
                userName: userName,
                onNotification: _showNotificationBottomSheet,
                clothes: clothes,
                fadeAnimation: _headerFade,
                slideAnimation: _headerSlide,
              ),
            ),

            // ── Cuaca ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _WeatherBadgeCard(
                  weatherState: weatherState,
                  onTap: _showWeatherDetailModal,
                ),
              ),
            ),

            // ── Banner Tambah Pakaian ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: ScaleTransition(
                  scale: _cardPulse,
                  child: _AddClothesBanner(context: context),
                ),
              ),
            ),

            // ── Section Agenda ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              sliver: SliverToBoxAdapter(
                child: _buildOccasionSection(),
              ),
            ),

            // ── Section Rekomendasi ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
              sliver: SliverToBoxAdapter(
                child: _buildRecommendationSection(recState, clothes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== OCCASION SECTION ====================
  Widget _buildOccasionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mau ke mana hari ini?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: _showAllOccasionsModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _crimson.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _crimson,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih agenda, PakeAja racik outfit terbaik dari lemarimu.',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // Horizontal scroll chips
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _occasions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final occ = _occasions[i];
              final label = occ['label'] as String;
              final isSelected = _selectedOccasion == label;
              final gradColors = occ['gradient'] as List<Color>;

              return GestureDetector(
                onTap: () => _onOccasionSelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: gradColors)
                        : null,
                    color: isSelected ? null : _cardBg,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : _divider,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gradColors.first.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        occ['emoji'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Grid cards for occasions
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemCount: _occasions.length,
          itemBuilder: (context, index) {
            final occ = _occasions[index];
            final label = occ['label'] as String;
            final isSelected = _selectedOccasion == label;
            final gradColors = occ['gradient'] as List<Color>;

            return GestureDetector(
              onTap: () => _onOccasionSelected(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? gradColors.first : _divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? gradColors.first.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: gradColors.first,
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: gradColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color:
                                    isSelected ? null : const Color(0xFFF4F5F7),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  occ['emoji'] as String,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? gradColors.first
                                    : _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              occ['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _textSecondary,
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

  // ==================== RECOMMENDATION SECTION ====================
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
        'gradient': [_crimson, _crimsonLight],
        'emoji': '👗',
      },
    );
    final gradColors = currentOccData['gradient'] as List<Color>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome,
                        size: 17, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rekomendasi Hari Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            if (recState.recommendation != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle,
                        size: 7, color: Color(0xFF1E8E3E)),
                    const SizedBox(width: 5),
                    Text(
                      '${recState.recommendation!.score.round()}% Cocok',
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

        // Kartu Rekomendasi dengan gradient header
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradColors.first.withValues(alpha: 0.08),
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
              // Gradient header strip
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
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: gradColors.first.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${currentOccData['emoji']}  ${currentOccData['tag']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: gradColors.first,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Tombol acak ulang
                    InkWell(
                      onTap: () {
                        ref
                            .read(recommendationProvider.notifier)
                            .reshuffle(_selectedOccasion);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _divider),
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          size: 18,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Konten
              Padding(
                padding: const EdgeInsets.all(16),
                child: recState.isLoading
                    ? _buildLoadingState()
                    : !_hasEnoughClothes(clothes)
                        ? _buildMissingClothesChecklist(clothes)
                        : recState.error != null
                            ? _buildIncompatibleOccasionCard(
                                recState.error!, _selectedOccasion)
                            : recState.recommendation != null
                                ? _buildRecommendationContent(
                                    recState.recommendation!, clothes)
                                : _buildEmptyRecommendation(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_crimson),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'AI sedang meracik paduan outfit terbaik…',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompatibleOccasionCard(
    String errorMessage,
    String occasion,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFAD1D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style_outlined, color: _crimson, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belum ada pakaian yang pas untuk $occasion',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF5A626A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/cloth/add'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _crimson),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Tambah Pakaian $occasion',
                    style: const TextStyle(
                      color: _crimson,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              if (occasion != 'Santai') ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _onOccasionSelected('Santai'),
                  child: const Text('Coba Santai',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ],
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.checkroom_outlined,
                size: 40, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 10),
            const Text(
              'Belum ada rekomendasi outfit yang dibuat.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(recommendationProvider.notifier)
                    .recommend(_selectedOccasion);
              },
              icon: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.white),
              label: const Text('Racik Sekarang',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _crimson,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final clothesById = {for (final c in clothes) c.id: c};
    final items =
        rec.itemIds.map((id) => clothesById[id]).whereType<ClothModel>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clothes display
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                            child: Divider(height: 1, color: Color(0xFFEEF0F2))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: Color(0xFFCBCDD2),
                          ),
                        ),
                        Expanded(
                            child: Divider(height: 1, color: Color(0xFFEEF0F2))),
                      ],
                    ),
                  ),
                _buildClothItemRow(items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol aksi
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_crimson, _crimsonLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _crimson.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _wearOutfit(rec),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 17, color: Colors.white),
                    label: const Text(
                      'Pakai Hari Ini',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              width: 48,
              child: OutlinedButton(
                onPressed: () => _saveFavorite(rec),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: _crimson,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                    color: _crimson,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: _crimson),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClothItemRow(ClothModel item) {
    return InkWell(
      onTap: () => context.push('/cloth/${item.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 54,
              height: 54,
              color: Colors.white,
              child: ClothImageView(
                imageUrl: item.imageUrl,
                width: 54,
                height: 54,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _crimson.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _crimson,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.colorLabel,
                      style: const TextStyle(
                          fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFBDBDBD),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: _textPrimary,
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _divider),
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
                                color: _textSecondary,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Consumer(
          builder: (context, modalRef, _) {
            final weatherState = modalRef.watch(weatherProvider);
            final weather = weatherState.data;
            final showSettingsButton = !kIsWeb &&
                (weatherState.issueType ==
                        WeatherIssueType.permissionDeniedForever ||
                    weatherState.issueType == WeatherIssueType.serviceDisabled);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          weather?.iconData ?? Icons.location_on_rounded,
                          color: _crimson,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cuaca & Saran Busana',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Perbarui lokasi & cuaca',
                          onPressed: weatherState.isLoading
                              ? null
                              : () => modalRef
                                  .read(weatherProvider.notifier)
                                  .refresh(),
                          icon: const Icon(Icons.refresh_rounded,
                              color: _crimson),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (weather != null) ...[
                      Text(
                        'Lokasi: ${weather.locationName} (${weather.tempText} - ${weather.conditionLabel})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _WeatherMetaChip(
                            icon: Icons.thermostat_rounded,
                            label: 'Terasa ${weather.roundedFeelsLike}°C',
                          ),
                          _WeatherMetaChip(
                            icon: Icons.water_drop_outlined,
                            label: 'Kelembapan ${weather.humidity}%',
                          ),
                          _WeatherMetaChip(
                            icon: Icons.air_rounded,
                            label: 'Angin ${weather.windSpeedKmh.round()} km/j',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        weather.detailedAdvice,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ] else ...[
                      Text(
                        weatherState.isLoading
                            ? 'Sedang mendeteksi lokasi GPS dan mengambil cuaca terkini...'
                            : (weatherState.errorMessage ??
                                'Aktifkan izin lokasi agar PakeAja dapat menampilkan cuaca nyata di lokasimu.'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: weatherState.isLoading
                                ? null
                                : () => modalRef
                                    .read(weatherProvider.notifier)
                                    .refresh(),
                            icon: const Icon(Icons.my_location_rounded,
                                size: 18),
                            label: Text(weatherState.isLoading
                                ? 'Memuat...'
                                : 'Perbarui Lokasi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _crimson,
                              side: const BorderSide(color: _crimson),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (showSettingsButton && weather == null) {
                                if (weatherState.issueType ==
                                    WeatherIssueType.serviceDisabled) {
                                  await Geolocator.openLocationSettings();
                                } else {
                                  await Geolocator.openAppSettings();
                                }
                              }
                              if (modalContext.mounted) {
                                Navigator.pop(modalContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _crimson,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              showSettingsButton && weather == null
                                  ? 'Buka Pengaturan'
                                  : 'Mengerti',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAllOccasionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI PakeAja akan menyesuaikan kombinasi pakaian terbaik untuk acara tersebut.',
                    style: TextStyle(fontSize: 13, color: _textSecondary),
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
                        final gradColors = item['gradient'] as List<Color>;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: gradColors)
                                  : null,
                              color: isSelected
                                  ? null
                                  : const Color(0xFFF7F8FA),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                item['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? gradColors.first : _textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: gradColors.first)
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

// ═══════════════════════════════════════════════════════════════════════════
// HERO HEADER — Crimson gradient app bar + user greeting
// ═══════════════════════════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final dynamic user;
  final String greeting;
  final String greetingEmoji;
  final String userName;
  final VoidCallback onNotification;
  final List<ClothModel> clothes;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _HeroHeader({
    required this.user,
    required this.greeting,
    required this.greetingEmoji,
    required this.userName,
    required this.onNotification,
    required this.clothes,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC4202F), Color(0xFFE8392A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + greeting + bell
              FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          backgroundImage: user?.photoUrl != null
                              ? CachedNetworkImageProvider(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting $greetingEmoji',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
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
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bell button
                      GestureDetector(
                        onTap: onNotification,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Stats row
              FadeTransition(
                opacity: fadeAnimation,
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.checkroom_outlined,
                      label: '${clothes.length} Pakaian',
                    ),
                    const SizedBox(width: 10),
                    const _StatChip(
                      icon: Icons.auto_awesome,
                      label: 'AI Aktif',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Decorative circles
        Positioned(
          right: -30,
          top: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          right: 30,
          bottom: 10,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEATHER BADGE CARD
// ═══════════════════════════════════════════════════════════════════════════
class _WeatherBadgeCard extends StatelessWidget {
  final WeatherState weatherState;
  final VoidCallback onTap;

  const _WeatherBadgeCard({
    required this.weatherState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weather = weatherState.data;
    final emoji = weather != null
        ? weather.emoji
        : (weatherState.isLoading ? '📍' : '🌦️');

    final headline = weather != null
        ? '${weather.tempText}  ${weather.conditionLabel}'
        : (weatherState.isLoading
            ? 'Mendeteksi lokasi...'
            : 'Lokasi & Cuaca');

    final locationChip = weather != null
        ? weather.locationName
        : (weatherState.isLoading ? 'GPS Aktif' : 'Ketuk Aktifkan');

    final subtitle = weather != null
        ? (weatherState.isLoading
            ? 'Memperbarui lokasi & cuaca terkini...'
            : weather.shortAdvice)
        : (weatherState.isLoading
            ? 'Mengambil suhu & kondisi cuaca di sekitarmu'
            : (weatherState.errorMessage ??
                'Ketuk untuk mengizinkan lokasi & melihat cuaca terkini.'));

    final isRainyOrCool = weather != null &&
        (weather.isRainy || weather.clothWeather == ClothWeather.cool);

    final badgeGradientColors = isRainyOrCool
        ? const [Color(0xFFBBDEFB), Color(0xFFE3F2FD)]
        : const [Color(0xFFFFE0B2), Color(0xFFFFF3E0)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: badgeGradientColors),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: Color(0xFF3B5998),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  locationChip,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3B5998),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12.5, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFBDBDBD), size: 20),
          ],
        ),
      ),
    );
  }
}

class _WeatherMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _crimson),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD CLOTHES BANNER — Gradient card dengan visual ilustrasi
// ═══════════════════════════════════════════════════════════════════════════
class _AddClothesBanner extends StatelessWidget {
  final BuildContext context;
  const _AddClothesBanner({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC4202F), Color(0xFFEF5537)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC4202F).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative wardrobe pattern
          Positioned(
            right: -10,
            top: -10,
            child: CustomPaint(
              size: const Size(110, 110),
              painter: _BannerDecorPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Lemari Digital AI',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tambah Pakaian\nke Lemari Digitalmu',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Foto baju kamu, biar AI PakeAja yang cocokin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/cloth/add?source=camera'),
                          icon: const Icon(Icons.photo_camera_outlined,
                              size: 17, color: _crimson),
                          label: const Text(
                            'Ambil Foto',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _crimson,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/cloth/add?source=gallery'),
                          icon: Icon(Icons.image_outlined,
                              size: 17,
                              color: Colors.white.withValues(alpha: 0.9)),
                          label: Text(
                            'Pilih Galeri',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
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
          ),
        ],
      ),
    );
  }
}

class _BannerDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.3), 55, paint);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.9), 30, paint);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.6), 40, paint2);

    // Hanger silhouette
    final hangerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.72;
    final cy = size.height * 0.3;
    // Hook
    final hookPath = Path()
      ..moveTo(cx, cy - 18)
      ..quadraticBezierTo(cx + 8, cy - 26, cx + 8, cy - 18)
      ..quadraticBezierTo(cx + 8, cy - 10, cx, cy - 6);
    canvas.drawPath(hookPath, hangerPaint);
    // Bar
    canvas.drawLine(
        Offset(cx - 24, cy + 8), Offset(cx + 24, cy + 8), hangerPaint);
    // Left side
    canvas.drawLine(
        Offset(cx - 24, cy + 8), Offset(cx - 32, cy + 22), hangerPaint);
    // Right side
    canvas.drawLine(
        Offset(cx + 24, cy + 8), Offset(cx + 32, cy + 22), hangerPaint);
    // Bottom bar
    canvas.drawLine(
        Offset(cx - 32, cy + 22), Offset(cx + 32, cy + 22), hangerPaint);

    // Sparkles
    _drawSparkle(canvas, Offset(size.width * 0.15, size.height * 0.15), 5,
        Colors.white.withValues(alpha: 0.3));
    _drawSparkle(canvas, Offset(size.width * 0.9, size.height * 0.75), 4,
        Colors.white.withValues(alpha: 0.2));
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + r * math.cos(angle),
            center.dy + r * math.sin(angle)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
