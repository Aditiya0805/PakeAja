import 'package:flutter/material.dart';

import 'package:pakeaja/core/widgets/cloth_image_view.dart';

import '../../../core/theme/app_theme.dart';
import 'package:pakeaja/data/models/cloth_model.dart';

class ClothingCard extends StatelessWidget {
  final ClothModel cloth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClothingCard({
    super.key,
    required this.cloth,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: _buildImage(),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cloth.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cloth.category.label} • ${cloth.colorLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
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
  }

  Widget _buildImage() {
    return ClothImageView(
      imageUrl: cloth.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}
