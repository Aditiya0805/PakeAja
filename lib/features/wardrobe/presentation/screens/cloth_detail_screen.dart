import 'package:flutter/material.dart';

import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/date_formatter.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class ClothDetailScreen extends ConsumerStatefulWidget {
  final String clothId;

  const ClothDetailScreen({super.key, required this.clothId});

  @override
  ConsumerState<ClothDetailScreen> createState() => _ClothDetailScreenState();
}

class _ClothDetailScreenState extends ConsumerState<ClothDetailScreen> {
  ClothModel? _currentCloth;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pakaian'),
        actions: [
          IconButton(
            onPressed: () => context.push('/cloth/${widget.clothId}/edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Pakaian',
          ),
          IconButton(
            onPressed: () {
              if (_currentCloth != null) {
                _confirmDelete(_currentCloth!);
              }
            },
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            tooltip: 'Hapus Pakaian',
          ),
        ],
      ),
      body: StreamBuilder<ClothModel?>(
        stream: ref
            .read(clothRepositoryProvider)
            .watchCloth(user.uid, widget.clothId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const ErrorWidgetPage(
              message: 'Pakaian tidak ditemukan.',
            );
          }

          final cloth = snapshot.data!;
          _currentCloth = cloth;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto
                ClothImageView(
                  imageUrl: cloth.imageUrl,
                  height: 300,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 20),

                // Nama
                Text(
                  cloth.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                        onPressed: () =>
                            context.push('/cloth/${cloth.id}/edit'),
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
        },
      ),
    );
  }

  Widget _buildInfoCard(cloth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _infoRow('Kategori', cloth.category.label),
          const Divider(),
          _infoRow('Warna', cloth.colorLabel),
          const Divider(),
          _infoRow(
            'Gaya',
            cloth.styles.map((s) => s.label).join(', '),
          ),
          const Divider(),
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
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(cloth) {
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
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
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
              final user = ref.read(authStateProvider).value;
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
                context.pop();
              } else {
                final err = ref.read(deleteClothProvider).error?.toString() ??
                    'Gagal menghapus pakaian.';
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
