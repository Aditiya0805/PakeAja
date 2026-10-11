import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget serbaguna untuk menampilkan gambar pakaian:
/// Mendukung String Base64 (tanpa Firebase Storage) dan Network URL.
class ClothImageView extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ClothImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isBase64 {
    if (imageUrl.isEmpty) return false;
    if (imageUrl.startsWith('data:image') || imageUrl.startsWith('data:application')) {
      return true;
    }
    // Jika tidak diawali http/https dan string cukup panjang, kemungkinan base64
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return imageUrl.length > 50;
    }
    return false;
  }

  Uint8List? _decodeBase64(String source) {
    try {
      String clean = source;
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl.isEmpty) {
      content = Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.checkroom_outlined, color: Colors.grey),
      );
    } else if (_isBase64) {
      final bytes = _decodeBase64(imageUrl);
      if (bytes != null) {
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _errorWidget(),
        );
      } else {
        content = _errorWidget();
      }
    } else {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey[100],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _errorWidget(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
