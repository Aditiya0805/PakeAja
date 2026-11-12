import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/widgets/menu_hero_header.dart';
import 'package:pakeaja/features/home/presentation/screens/home_screen.dart';
import 'package:pakeaja/features/outfits/presentation/screens/favorites_history_screen.dart';
import 'package:pakeaja/features/profile/presentation/screens/profile_screen.dart';
import 'package:pakeaja/features/recommendation/presentation/screens/recommendation_screen.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/wardrobe_screen.dart';

/// Provider untuk mengontrol index tab utama
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _pages = const [
    HomeScreen(),
    WardrobeScreen(),
    RecommendationScreen(),
    FavoritesHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: MenuUiColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  label: 'Beranda',
                  selectedIcon: Icons.home_rounded,
                  unselectedIcon: Icons.home_outlined,
                ),
                _buildNavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  label: 'Lemari',
                  selectedIcon: Icons.checkroom_rounded,
                  unselectedIcon: Icons.checkroom_outlined,
                ),
                _buildNavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'Rekomendasi',
                  selectedIcon: Icons.auto_awesome_rounded,
                  unselectedIcon: Icons.auto_awesome_outlined,
                ),
                _buildNavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'Favorit',
                  selectedIcon: Icons.favorite_rounded,
                  unselectedIcon: Icons.favorite_border_rounded,
                ),
                _buildNavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  label: 'Profil',
                  selectedIcon: Icons.person_rounded,
                  unselectedIcon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String label,
    required IconData selectedIcon,
    required IconData unselectedIcon,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        ref.read(mainTabIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isSelected ? 56 : 40,
            height: 32,
            decoration: BoxDecoration(
              gradient: isSelected ? MenuUiColors.ctaGradient : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: MenuUiColors.crimson.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? Colors.white : MenuUiColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? MenuUiColors.crimson
                  : MenuUiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
