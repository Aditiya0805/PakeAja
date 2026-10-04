import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/date_formatter.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class ClothDetailScreen extends ConsumerStatefulWidget {
  final String clothId;

  const ClothDetailScreen({super.key, required this.clothId});

  @override
  ConsumerState<ClothDetailScreen> createState() => _ClothDetailScreenState();
}

class _ClothDetailScreenState extends ConsumerState<ClothDetailScreen> {
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
          ),
        ],
      ),
      body: StreamBuilder(
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: cloth.imageUrl.isEmpty
                      ? Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image,
                              size: 64, color: Colors.grey),
                        )
                      : CachedNetworkImage(
                          imageUrl: cloth.imageUrl,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            height: 300,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (c, u, e) => Container(
                            height: 300,
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.broken_image, size: 64),
                          ),
                        ),
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

  void _confirmDelete(cloth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pakaian'),
        content: Text(
            'Yakin hapus "${cloth.name}"? Tindakan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              context.pop();
              final user = ref.read(authStateProvider).value;
              if (user == null) return;

              final success = await ref
                  .read(deleteClothProvider.notifier)
                  .deleteCloth(
                    uid: user.uid,
                    clothId: cloth.id,
                    imageUrl: cloth.imageUrl,
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pakaian berhasil dihapus.')),
                );
                if (mounted) context.pop();
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
