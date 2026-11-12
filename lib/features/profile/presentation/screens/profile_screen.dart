import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/menu_hero_header.dart';
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
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final displayName = ref.watch(effectiveUserNameProvider);
    final email = (user?.email.isNotEmpty ?? false)
        ? user!.email
        : (authUser?.email ?? '');
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: MenuUiColors.surface,
      body: RefreshIndicator(
        color: MenuUiColors.crimson,
        onRefresh: () async {
          ref.invalidate(userDataProvider);
          ref.invalidate(userStatsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Hero Header Profil gradasi crimson mengikuti HomeScreen
            SliverToBoxAdapter(
              child: _buildHeroHeader(user, displayName, email),
            ),

            // 2. Konten Profil
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Statistik Lemari & Outfit
                  _buildStats(stats),
                  const SizedBox(height: 24),

                  // Menu & Pengaturan
                  const Text(
                    'PENGATURAN & LAINNYA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: MenuUiColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMenu(context),
                  const SizedBox(height: 20),

                  // Tentang Aplikasi
                  _buildAboutCard(),
                  const SizedBox(height: 20),

                  // Danger Zone (Logout & Hapus Akun)
                  _buildDangerZone(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1. HERO HEADER ====================
  Widget _buildHeroHeader(dynamic user, String displayName, String email) {
    return MenuHeroHeader(
      subtitle: 'Akun Pengguna',
      title: 'Profil Saya',
      actions: [
        HeroGlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun Anda aktif dan terlindungi.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
      bottomContent: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person,
                            size: 30, color: Colors.white)
                        : null,
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 13, color: MenuUiColors.crimson),
                          SizedBox(width: 5),
                          Text(
                            'Ubah Profil',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: MenuUiColors.crimson,
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
      ),
      statChips: const [
        HeroStatChip(
          icon: Icons.verified_user_outlined,
          label: 'Akun Aktif',
        ),
        HeroStatChip(
          icon: Icons.auto_awesome,
          label: 'AI Stylist',
        ),
      ],
    );
  }

  // ==================== 2. STATISTIK ====================
  Widget _buildStats(AsyncValue<Map<String, int>> stats) {
    final data = stats.valueOrNull ??
        {'totalClothes': 0, 'totalFavorites': 0, 'totalWorn': 0};

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: MenuUiColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MenuUiColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            icon: Icons.checkroom_outlined,
            accentColor: MenuUiColors.crimson,
            value: '${data['totalClothes'] ?? 0}',
            label: 'Pakaian',
          ),
          Container(height: 36, width: 1, color: MenuUiColors.divider),
          _statItem(
            icon: Icons.favorite_border_rounded,
            accentColor: const Color(0xFFE91E63),
            value: '${data['totalFavorites'] ?? 0}',
            label: 'Favorit',
          ),
          Container(height: 36, width: 1, color: MenuUiColors.divider),
          _statItem(
            icon: Icons.history_rounded,
            accentColor: const Color(0xFF1565C0),
            value: '${data['totalWorn'] ?? 0}',
            label: 'Dipakai',
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required Color accentColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MenuUiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: MenuUiColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==================== 3. MENU ====================
  Widget _buildMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MenuUiColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MenuUiColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _menuTile(
              icon: Icons.person_outline_rounded,
              iconColor: MenuUiColors.crimson,
              title: 'Edit Nama Profil',
              onTap: _showEditProfileDialog,
            ),
            const Divider(height: 1, indent: 60, color: MenuUiColors.divider),
            _menuTile(
              icon: Icons.tune_rounded,
              iconColor: const Color(0xFF6C63FF),
              title: 'Preferensi Gaya Busana',
              onTap: () => _showComingSoon('Preferensi Gaya Busana'),
            ),
            const Divider(height: 1, indent: 60, color: MenuUiColors.divider),
            _menuTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF00897B),
              title: 'Tentang PakeAja',
              onTap: _showAboutDialog,
            ),
            const Divider(height: 1, indent: 60, color: MenuUiColors.divider),
            _menuTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF1565C0),
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
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MenuUiColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFBDBDBD), size: 20),
      onTap: onTap,
    );
  }

  // ==================== 4. TENTANG APLIKASI ====================
  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MenuUiColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MenuUiColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: MenuUiColors.ctaGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PakeAja AI v1.0.0',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: MenuUiColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 12,
                    color: MenuUiColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 5. DANGER ZONE ====================
  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MenuUiColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE8E8)),
        boxShadow: [
          BoxShadow(
            color: MenuUiColors.crimson.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
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
            const Divider(height: 1, indent: 60, color: Color(0xFFFEECEC)),
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
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
    final currentName = ref.read(effectiveUserNameProvider);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditProfileDialog(
        initialName: currentName == 'Pengguna PakeAja' ? '' : currentName,
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      if (newName.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nama terlalu pendek (minimal 2 karakter).'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      final success = await ref
          .read(updateProfileProvider.notifier)
          .updateName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Nama berhasil diubah menjadi "$newName".'
                  : 'Gagal memperbarui nama. Coba lagi.',
            ),
            backgroundColor:
                success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
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

class _EditProfileDialog extends StatefulWidget {
  final String initialName;

  const _EditProfileDialog({required this.initialName});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nama Lengkap',
          hintText: 'Masukkan nama kamu',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
