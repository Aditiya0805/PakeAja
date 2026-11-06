import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDataProvider).valueOrNull;
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(userDataProvider);
            ref.invalidate(userStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Profil
                _buildHeader(),
                const SizedBox(height: 20),

                // 2. Kartu Profil Pengguna
                _buildUserProfileCard(user),
                const SizedBox(height: 18),

                // 3. Statistik Lemari & Outfit
                _buildStats(stats),
                const SizedBox(height: 22),

                // 4. Menu & Pengaturan
                const Text(
                  'PENGATURAN & LAINNYA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMenu(context),
                const SizedBox(height: 22),

                // 5. Tentang Aplikasi
                _buildAboutCard(),
                const SizedBox(height: 22),

                // 6. Danger Zone (Logout & Hapus Akun)
                _buildDangerZone(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 1. HEADER ====================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun Pengguna',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A626A),
              ),
            ),
            Text(
              'Profil Saya',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEEF0F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akun Anda aktif dan terlindungi.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 2. KARTU PROFIL ====================
  Widget _buildUserProfileCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto Profil dengan status badge hijau
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                backgroundImage: user?.photoUrl != null
                    ? CachedNetworkImageProvider(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 34, color: AppTheme.primaryColor)
                    : null,
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Nama & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Pengguna PakeAja',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 13, color: AppTheme.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Ubah Profil',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 3. STATISTIK ====================
  Widget _buildStats(AsyncValue<Map<String, int>> stats) {
    final data = stats.valueOrNull ??
        {'totalClothes': 0, 'totalFavorites': 0, 'totalWorn': 0};

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            icon: Icons.checkroom_outlined,
            value: '${data['totalClothes'] ?? 0}',
            label: 'Pakaian',
          ),
          Container(height: 32, width: 1, color: const Color(0xFFF0F0F2)),
          _statItem(
            icon: Icons.favorite_border_rounded,
            value: '${data['totalFavorites'] ?? 0}',
            label: 'Favorit',
          ),
          Container(height: 32, width: 1, color: const Color(0xFFF0F0F2)),
          _statItem(
            icon: Icons.history_rounded,
            value: '${data['totalWorn'] ?? 0}',
            label: 'Dipakai',
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  // ==================== 4. MENU ====================
  Widget _buildMenu(BuildContext context) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _menuTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Nama Profil',
              onTap: _showEditProfileDialog,
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F2)),
            _menuTile(
              icon: Icons.tune_rounded,
              title: 'Preferensi Gaya Busana',
              onTap: () => _showComingSoon('Preferensi Gaya Busana'),
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F2)),
            _menuTile(
              icon: Icons.info_outline_rounded,
              title: 'Tentang PakeAja',
              onTap: _showAboutDialog,
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F2)),
            _menuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              onTap: () => _showComingSoon('Kebijakan Privasi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4A5056), size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFBDBDBD), size: 20),
      onTap: onTap,
    );
  }

  // ==================== 5. TENTANG APLIKASI ====================
  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PakeAja AI v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6. DANGER ZONE ====================
  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE8E8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.errorColor, size: 18),
              ),
              title: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: _confirmLogout,
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFFEECEC)),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: AppTheme.errorColor, size: 18),
              ),
              title: const Text(
                'Hapus Akun Permanen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS & ACTIONS ====================
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Yakin ingin keluar dari akun PakeAja kamu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _confirmDeleteAccount() async {
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
              'Tindakan ini akan menghapus semua data pakaian, outfit, favorit, dan riwayat kamu secara permanen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password verifikasi',
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
            child: const Text('Hapus Permanen'),
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
    final user = ref.read(userDataProvider).valueOrNull;
    final nameController = TextEditingController(text: user?.name ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
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
          'PakeAja adalah aplikasi asisten fashion harian berbasis AI yang memadukan pakaian terbaik langsung dari lemarimu.\n\n'
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
