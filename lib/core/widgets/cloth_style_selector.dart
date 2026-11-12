import 'package:flutter/material.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/services/recommendation_service.dart';

/// Pemilih gaya pakaian multi-select disertai pratinjau pengelompokan kategori agenda.
class ClothStyleSelector extends StatelessWidget {
  final List<ClothStyle> selectedStyles;
  final String clothName;
  final ClothCategory category;
  final ValueChanged<List<ClothStyle>> onChanged;

  const ClothStyleSelector({
    super.key,
    required this.selectedStyles,
    required this.clothName,
    required this.category,
    required this.onChanged,
  });

  static final RecommendationService _classifier = RecommendationService();

  void _toggleStyle(ClothStyle style, bool selected) {
    final next = List<ClothStyle>.from(selectedStyles);
    if (selected) {
      if (!next.contains(style)) next.add(style);
    } else if (next.length > 1) {
      next.remove(style);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final previewCloth = ClothModel(
      id: 'preview',
      name: clothName.trim(),
      category: category,
      color: ClothColor.black,
      styles: selectedStyles.isNotEmpty
          ? selectedStyles
          : const [ClothStyle.casual],
      weather: ClothWeather.cool,
      imageUrl: '',
      createdAt: DateTime.now(),
    );
    final suitableOccasions = _classifier.getSuitableOccasions(previewCloth);
    final summaryText = suitableOccasions.isNotEmpty
        ? 'Masuk kategori: ${suitableOccasions.join(', ')}'
        : 'Belum ada kategori yang cocok';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gaya (bisa pilih lebih dari 1)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothStyle.values.map((s) {
            final isSelected = selectedStyles.contains(s);
            return FilterChip(
              label: Text(s.label),
              selected: isSelected,
              onSelected: (val) => _toggleStyle(s, val),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summaryText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

