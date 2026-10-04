import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedOccasion;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider).value;
    final clothes = ref.watch(clothesListProvider).value ?? [];

    final greeting = _getGreeting();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh stream
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Profile photo
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: user?.photoUrl != null
                          ? CachedNetworkImageProvider(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.person,
                              color: AppTheme.primaryColor)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Halo, ${user?.name?.split(' ').first ?? 'User'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Judul
                const Text(
                  'Hari ini mau pake apa?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih acara kamu, biar PakeAja yang pilih outfit-nya.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Pilihan acara (grid)
                _buildOccasionGrid(),
                const SizedBox(height: 24),

                // Tombol rekomendasi
                _buildRecommendationButton(clothes),
                const SizedBox(height: 16),

                // Checklist kelengkapan
                if (!_hasEnoughClothes(clothes)) ...[
                  _buildChecklist(clothes),
                ],

                // Info jumlah pakaian
                const SizedBox(height: 16),
                _buildWardrobeSummary(clothes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  Widget _buildOccasionGrid() {
    final occasions = [
      {'icon': Icons.school_outlined, 'label': 'Kuliah'},
      {'icon': Icons.coffee_outlined, 'label': 'Santai'},
      {'icon': Icons.business_center_outlined, 'label': 'Formal'},
      {'icon': Icons.badge_outlined, 'label': 'Semi Formal'},
      {'icon': Icons.directions_run_outlined, 'label': 'Olahraga'},
      {'icon': Icons.group_outlined, 'label': 'Organisasi'},
      {'icon': Icons.more_horiz, 'label': 'Lainnya'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: occasions.length,
      itemBuilder: (context, index) {
        final occ = occasions[index];
        final isSelected = _selectedOccasion == occ['label'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedOccasion = isSelected ? null : occ['label'] as String;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  occ['icon'] as IconData,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  occ['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationButton(List clothes) {
    final canRecommend = _hasEnoughClothes(clothes);
    final hasSelection = _selectedOccasion != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: (canRecommend && hasSelection)
            ? () => context.push(
                  '/recommendation?occasion=${Uri.encodeComponent(_selectedOccasion!)}',
                )
            : null,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Rekomendasikan Outfit'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  bool _hasEnoughClothes(List clothes) {
    // (1 top + 1 bottom + 1 shoes) atau (1 onepiece + 1 shoes)
    int tops = 0, bottoms = 0, shoes = 0, onepieces = 0;
    for (final c in clothes) {
      final cat = c.category.value;
      if (cat == 'top') tops++;
      if (cat == 'bottom') bottoms++;
      if (cat == 'shoes') shoes++;
      if (cat == 'onepiece') onepieces++;
    }
    return (tops >= 1 && bottoms >= 1 && shoes >= 1) ||
        (onepieces >= 1 && shoes >= 1);
  }

  Widget _buildChecklist(List clothes) {
    int tops = 0, bottoms = 0, shoes = 0, onepieces = 0;
    for (final c in clothes) {
      final cat = c.category.value;
      if (cat == 'top') tops++;
      if (cat == 'bottom') bottoms++;
      if (cat == 'shoes') shoes++;
      if (cat == 'onepiece') onepieces++;
    }

    final hasTop = tops >= 1 || onepieces >= 1;
    final hasBottom = bottoms >= 1 || onepieces >= 1;
    final hasShoes = shoes >= 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Belum bisa dapat rekomendasi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _checkRow('Atasan', hasTop),
          _checkRow('Bawahan', hasBottom),
          _checkRow('Sepatu', hasShoes),
          const SizedBox(height: 12),
          const Text(
            'Tambahkan minimal 1 atasan, 1 bawahan, dan 1 sepatu untuk mendapatkan rekomendasi.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: checked ? AppTheme.successColor : AppTheme.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: checked ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeSummary(List clothes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(Icons.checkroom, '${clothes.length}', 'Pakaian'),
          _summaryItem(Icons.star, 'Lihat', 'Favorit'),
          _summaryItem(Icons.history, 'Lihat', 'Riwayat'),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
