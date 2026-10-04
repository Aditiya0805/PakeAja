import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/outfit_card.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:pakeaja/features/recommendation/providers/recommendation_provider.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  final String occasion;

  const RecommendationScreen({super.key, required this.occasion});

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    // Generate rekomendasi pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).recommend(widget.occasion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationProvider);
    final clothes = ref.watch(clothesListProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Rekomendasi Outfit')),
      body: recState.isLoading
          ? const LoadingWidget(message: 'Memilihkan outfit terbaik...')
          : recState.recommendation == null
              ? _buildError(recState.error)
              : _buildResult(recState.recommendation!, clothes),
      bottomNavigationBar: recState.recommendation == null
          ? null
          : _buildActions(context, clothes),
    );
  }

  Widget _buildResult(OutfitRecommendation rec, List<ClothModel> clothes) {
    // Cari detail cloth berdasarkan itemIds
    final items = rec.itemIds
        .map((id) => clothes.firstWhere(
              (c) => c.id == id,
              orElse: () => clothes.first,
            ))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          const Text(
            'Outfit Kamu Hari Ini',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acara: ${rec.occasion}',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Visual outfit
          _buildOutfitVisual(items),
          const SizedBox(height: 20),

          // Info style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rekomendasi berdasarkan acara, warna, dan rotasi pakaian kamu.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
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

  Widget _buildOutfitVisual(List<ClothModel> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Icon(Icons.arrow_downward,
                    size: 20, color: AppTheme.textHint),
              ),
            _buildOutfitItem(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildOutfitItem(ClothModel item) {
    final imageUrl = item.imageUrl ?? '';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                )
              : Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (c, u, e) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                '${item.category.label} • ${item.colorLabel}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(String? error) {
    if (error == 'Belum cukup') {
      return const EmptyState(
        icon: Icons.checkroom_outlined,
        title: 'Belum cukup pakaian',
        subtitle:
            'Tambahkan minimal 1 atasan, 1 bawahan, dan 1 sepatu (atau 1 one-piece dan 1 sepatu).',
      );
    }
    return ErrorWidgetPage(
      message: error ?? 'Gagal membuat rekomendasi.',
      onRetry: () =>
          ref.read(recommendationProvider.notifier).recommend(widget.occasion),
    );
  }

  Widget _buildActions(BuildContext context, List<ClothModel> clothes) {
    final rec = ref.watch(recommendationProvider).recommendation!;
    final items = rec.itemIds
        .map((id) => clothes.firstWhere(
              (c) => c.id == id,
              orElse: () => clothes.first,
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outfit summary card
            OutfitCard(
              items: items,
              occasion: rec.occasion,
              showOccasion: false,
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Pakai Hari Ini',
                    onPressed: () => _wearOutfit(rec),
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Simpan',
                    onPressed: () => _saveFavorite(rec),
                    variant: ButtonVariant.outline,
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Acak Ulang',
                onPressed: () =>
                    ref.read(recommendationProvider.notifier).reshuffle(
                          widget.occasion,
                        ),
                variant: ButtonVariant.text,
                icon: Icons.shuffle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _wearOutfit(OutfitRecommendation rec) async {
    final success = await ref
        .read(wearOutfitProvider.notifier)
        .wearOutfit(itemIds: rec.itemIds, occasion: rec.occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit tercatat. Tetap gaya!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      if (mounted) context.pop();
    }
  }

  Future<void> _saveFavorite(OutfitRecommendation rec) async {
    final success = await ref
        .read(saveOutfitProvider.notifier)
        .saveOutfit(itemIds: rec.itemIds, occasion: rec.occasion);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit tersimpan ke favorit.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
