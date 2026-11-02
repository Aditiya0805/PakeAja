import 'package:flutter/material.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/data/models/cloth_model.dart';

class OutfitCard extends StatelessWidget {
  final List<ClothModel> items;
  final String occasion;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final bool showOccasion;
  final VoidCallback? onWear;

  const OutfitCard({
    super.key,
    required this.items,
    required this.occasion,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.showOccasion = true,
    this.onWear,
  });

  IconData _getOccasionIcon(String occ) {
    final lower = occ.toLowerCase();
    if (lower.contains('kuliah')) return Icons.school_rounded;
    if (lower.contains('santai')) return Icons.coffee_outlined;
    if (lower.contains('formal')) return Icons.work_outline_rounded;
    if (lower.contains('semi')) return Icons.badge_outlined;
    if (lower.contains('olahraga')) return Icons.directions_run_rounded;
    if (lower.contains('organisasi')) return Icons.groups_outlined;
    return Icons.event_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar: Occasion Badge & Actions
                if (showOccasion) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getOccasionIcon(occasion),
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              occasion,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (onFavoriteToggle != null)
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? const Color(0xFFFDE8E8)
                                  : const Color(0xFFF4F5F7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              size: 17,
                              color: isFavorite
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF8E959E),
                            ),
                          ),
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4F5F7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. Horizontal Clothes Thumbnails Preview
                SizedBox(
                  height: 95,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        width: 130,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEF0F2)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: Colors.white,
                                child: ClothImageView(
                                  imageUrl: item.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.category.label,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 3. Bottom Action Row (Pakai Lagi)
                if (onWear != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onWear,
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16, color: AppTheme.primaryColor),
                      label: const Text(
                        'Pakai Outfit Ini',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
