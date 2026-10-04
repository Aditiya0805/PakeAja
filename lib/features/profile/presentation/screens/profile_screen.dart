import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider).value;
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userDataProvider);
          ref.invalidate(userStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Foto profil
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: user?.photoUrl != null
                    ? CachedNetworkImageProvider(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 48, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(height: 16),

              // Nama & email
              Text(
                user?.name ?? 'Pengguna',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Statistik
              _buildStats(stats),
              const SizedBox(height: 24),

              // Menu
              _buildMenu(context),
              const SizedBox(height: 24),

              // Tentang
              _buildAbout(),
              const SizedBox(height: 24),

              // Logout & Hapus Akun
              _buildDangerZone(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(AsyncValue<Map<String, int>> stats) {
    final data = stats.value ?? {'totalClothes': 0, 'totalFavorites': 0, 'totalWorn': 0};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            Icons.checkroom,
            '${data['totalClothes'] ?? 0}',
            'Pakaian',
          ),
          _statItem(
            Icons.favorite,
            '${data['totalFavorites'] ?? 0}',
            'Favorit',
          ),
          _statItem(
            Icons.history,
            '${data['totalWorn'] ?? 0}',
            'Dipakai',
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            onTap: () => _showEditProfileDialog(),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            onTap: () => _showComingSoon('Pengaturan'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.info_outline,
            title: 'Tentang PakeAja',
            onTap: () => _showAboutDialog(),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showComingSoon('Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }

  Widget _buildAbout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.checkroom,
              color: AppTheme.primaryColor, size: 32),
          const SizedBox(height: 8),
          const Text(
            'PakeAja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Versi 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () => _confirmLogout(),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.delete_forever,
                color: AppTheme.errorColor),
            title: const Text(
              'Hapus Akun',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () => _confirmDeleteAccount(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(authControllerProvider.notifier).logout();
      if (success && mounted) {
        // Navigation akan otomatis redirect ke /login via router
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Minta password untuk verifikasi
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan ini akan menghapus semua data kamu secara permanen (pakaian, outfit, favorit, dan riwayat).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password untuk verifikasi',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      final success = await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(passwordController.text);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus akun. Cek password kamu.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
    passwordController.dispose();
  }

  Future<void> _showEditProfileDialog() async {
    final user = ref.read(userDataProvider).value;
    final nameController = TextEditingController(text: user?.name ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(updateProfileProvider.notifier)
          .updateName(nameController.text);
    }
    nameController.dispose();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang PakeAja'),
        content: const Text(
          'PakeAja adalah aplikasi rekomendasi outfit harian yang membantu kamu menentukan pakaian berdasarkan pakaian yang sudah kamu miliki.\n\n'
          'Bingung mau pake apa? PakeAja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir.'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }
}
