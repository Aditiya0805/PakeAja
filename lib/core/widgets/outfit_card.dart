import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';

/// Menampilkan outfit: daftar item (foto) secara vertikal dengan "+"
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

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showOccasion) ...[
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Acara: $occasion',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isFavorite)
                      const Icon(Icons.favorite,
                          size: 18, color: AppTheme.accentColor),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              // Item list
              Row(
                children: [
                  Expanded(
                    child: _buildItemList(),
                  ),
                  const SizedBox(width: 12),
                  // Actions
                  Column(
                    children: [
                      if (onFavoriteToggle != null)
                        IconButton(
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppTheme.accentColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      if (onWear != null)
                        IconButton(
                          onPressed: onWear,
                          icon: const Icon(Icons.check_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          color: AppTheme.errorColor,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Icon(Icons.add, size: 14, color: AppTheme.textHint),
            ),
          _buildItemRow(items[i]),
        ],
      ],
    );
  }

  Widget _buildItemRow(ClothModel cloth) {
    return Row(
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: cloth.imageUrl.isEmpty
              ? Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                )
              : CachedNetworkImage(
                  imageUrl: cloth.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (c, u, e) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 18),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cloth.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                cloth.category.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
