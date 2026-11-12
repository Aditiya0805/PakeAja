import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/date_formatter.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/menu_hero_header.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class ClothDetailScreen extends ConsumerStatefulWidget {
  final String clothId;

  const ClothDetailScreen({super.key, required this.clothId});

  @override
  ConsumerState<ClothDetailScreen> createState() => _ClothDetailScreenState();
}

class _ClothDetailScreenState extends ConsumerState<ClothDetailScreen> {
  ClothModel? _findCachedCloth() {
    final clothes = ref.watch(clothesListProvider).valueOrNull ?? const [];
    for (final item in clothes) {
      if (item.id == widget.clothId) return item;
    }
    return null;
  }

  User? _resolveUser() {
    final streamUser = ref.watch(authStateProvider).valueOrNull;
    if (streamUser != null) return streamUser;
    try {
      return ref.read(authServiceProvider).currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final user = _resolveUser();

    if (user == null) {
      if (authAsync.isLoading) {
        return Scaffold(
          backgroundColor: MenuUiColors.surface,
          appBar: AppBar(
            title: const Text('Detail Pakaian'),
            backgroundColor: MenuUiColors.crimson,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: const LoadingWidget(message: 'Memuat detail pakaian...'),
        );
      }
      return Scaffold(
        backgroundColor: MenuUiColors.surface,
        appBar: AppBar(
          title: const Text('Detail Pakaian'),
          backgroundColor: MenuUiColors.crimson,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ErrorWidgetPage(
          message: 'Sesi pengguna belum siap. Silakan masuk ulang.',
          onRetry: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      );
    }

    final cachedCloth = _findCachedCloth();
    final detailAsync = ref.watch(clothDetailProvider(widget.clothId));
    final cloth = detailAsync.valueOrNull ?? cachedCloth;

    return Scaffold(
      backgroundColor: MenuUiColors.surface,
      appBar: AppBar(
        title: const Text('Detail Pakaian'),
        backgroundColor: MenuUiColors.crimson,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: cloth == null
                ? null
                : () => context.push('/cloth/${widget.clothId}/edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Pakaian',
          ),
          IconButton(
            onPressed: cloth == null ? null : () => _confirmDelete(cloth),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Pakaian',
          ),
        ],
      ),
      body: _buildBody(
        cloth: cloth,
        detailAsync: detailAsync,
      ),
    );
  }

  Widget _buildBody({
    required ClothModel? cloth,
    required AsyncValue<ClothModel?> detailAsync,
  }) {
    if (cloth == null) {
      if (detailAsync.isLoading) {
        return const LoadingWidget(message: 'Memuat detail pakaian...');
      }
      return ErrorWidgetPage(
        message: detailAsync.hasError
            ? ErrorHandler.handle(detailAsync.error!)
            : 'Pakaian tidak ditemukan.',
        onRetry: () {
          ref.invalidate(clothDetailProvider(widget.clothId));
          ref.invalidate(clothesListProvider);
        },
      );
    }

    final isWashing = ref.watch(washingClothIdsProvider).contains(cloth.id);
    final isFavorite = ref.watch(favoriteClothIdsProvider).contains(cloth.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto dalam frame bersih agar tidak terpotong
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MenuUiColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClothImageView(
              imageUrl: cloth.imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 18),

          // Nama & badge status cepat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cloth.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MenuUiColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isWashing
                      ? const Color(0xFFEEF3FB)
                      : const Color(0xFFE6F6ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isWashing ? 'Sedang Dicuci' : 'Siap Pakai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWashing
                        ? const Color(0xFF3B5998)
                        : const Color(0xFF1E8E3E),
                  ),
                ),
              ),
              if (isFavorite) ...[
                const SizedBox(width: 6),
                const Icon(Icons.favorite,
                    color: MenuUiColors.crimson, size: 22),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Info cards
          _buildInfoCard(cloth),
          const SizedBox(height: 16),

          // Stats
          _buildStats(cloth),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit',
                  onPressed: () => context.push('/cloth/${cloth.id}/edit'),
                  variant: ButtonVariant.outline,
                  icon: Icons.edit_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Hapus',
                  onPressed: () => _confirmDelete(cloth),
                  variant: ButtonVariant.danger,
                  icon: Icons.delete_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ClothModel cloth) {
    final styleText = cloth.styles.isNotEmpty
        ? cloth.styles.map((s) => s.label).join(', ')
        : 'Casual';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MenuUiColors.divider),
      ),
      child: Column(
        children: [
          _infoRow('Kategori', cloth.category.label),
          const Divider(height: 18),
          _infoRow('Warna', cloth.colorLabel),
          const Divider(height: 18),
          _infoRow('Gaya', styleText),
          const Divider(height: 18),
          _infoRow('Cuaca', cloth.weather.label),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: MenuUiColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: MenuUiColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ClothModel cloth) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.repeat,
            '${cloth.wearCount}x',
            'Dipakai',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            Icons.schedule,
            DateFormatter.relative(cloth.lastWornAt),
            'Terakhir',
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: MenuUiColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: MenuUiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ClothModel cloth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pakaian'),
        content: Text(
            'Yakin hapus "${cloth.name}"? Tindakan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final user = _resolveUser();
              if (user == null) return;

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Menghapus "${cloth.name}"...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              final success = await ref
                  .read(deleteClothProvider.notifier)
                  .deleteCloth(
                    uid: user.uid,
                    clothId: cloth.id,
                    imageUrl: cloth.imageUrl,
                  );

              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pakaian berhasil dihapus.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              } else {
                final rawErr = ref.read(deleteClothProvider).error;
                final err = rawErr != null
                    ? ErrorHandler.handle(rawErr)
                    : 'Gagal menghapus pakaian.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $err'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
