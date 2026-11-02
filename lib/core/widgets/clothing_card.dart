import 'package:flutter/material.dart';

import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/data/models/cloth_model.dart';

class ClothingCard extends StatelessWidget {
  final ClothModel cloth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool isWashing;
  final VoidCallback? onStatusToggle;

  const ClothingCard({
    super.key,
    required this.cloth,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.isWashing = false,
    this.onStatusToggle,
  });

  String _getCategoryLabel() {
    switch (cloth.category) {
      case ClothCategory.top:
        return 'Atasan ${cloth.colorLabel}';
      case ClothCategory.bottom:
        return 'Celana ${cloth.colorLabel}';
      case ClothCategory.outer:
        return 'Outerwear';
      case ClothCategory.shoes:
        return 'Alas Kaki';
      case ClothCategory.accessory:
        return 'Aksesoris';
      case ClothCategory.onepiece:
        return 'One-piece';
    }
  }

  String _getStyleLabel() {
    if (cloth.styles.isNotEmpty) {
      return cloth.styles.first.label;
    }
    return 'Casual';
  }

  String _getWornText() {
    if (cloth.lastWornAt != null) {
      final diff = DateTime.now().difference(cloth.lastWornAt!);
      if (diff.inDays == 0) return 'Dipakai hari ini';
      if (diff.inDays == 1) return 'Pakai kemarin';
      if (diff.inDays < 7) return 'Pakai ${diff.inDays} hari lalu';
      if (diff.inDays < 30) return 'Pakai ${(diff.inDays / 7).floor()} minggu lalu';
    }
    if (cloth.wearCount > 0) {
      return 'Dipakai ${cloth.wearCount}× bln ini';
    }
    return 'Siap dipakai';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Badge & Favorite Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge (Siap / Dicuci)
                    GestureDetector(
                      onTap: onStatusToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isWashing
                              ? const Color(0xFFEEF3FB)
                              : const Color(0xFFE6F6ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isWashing
                                    ? const Color(0xFF3B5998)
                                    : const Color(0xFF1E8E3E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isWashing ? 'Dicuci' : 'Siap',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isWashing
                                    ? const Color(0xFF3B5998)
                                    : const Color(0xFF1E8E3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Heart Favorite Button
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEEF0F2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorite
                                ? AppTheme.primaryColor
                                : const Color(0xFF8E959E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Cloth Image View
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFF9FAFB),
                        child: ClothImageView(
                          imageUrl: cloth.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Category & Style Subtitle Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getCategoryLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStyleLabel(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // 4. Cloth Name
                Text(
                  cloth.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // 5. Last Worn & History Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getWornText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
