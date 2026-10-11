import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';

/// Antigravity Splash Screen
/// Mensimulasikan pakaian flat lay (baju, celana, sepatu) melayang bebas melawan gravitasi,
/// lalu menyatu secara presisi menjadi outfit lengkap & logo aplikasi PakeAja.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Fase 1: Muncul & Float acak (Antigravity)
  late final Animation<double> _fadeIn;
  late final Animation<double> _floatProgress;

  // Fase 2: Menyatu ke pusat
  late final Animation<double> _combineProgress;

  // Fase 3: Snap & Pulse logo lengkap
  late final Animation<double> _snapPulse;
  late final Animation<double> _badgeGlow;
  late final Animation<double> _textFade;

  // Fase 4: Transisi keluar
  late final Animation<double> _screenFadeOut;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // 0.0 - 0.15: Fade in pakaian
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );

    // 0.0 - 0.40: Floating acak melawan gravitasi
    _floatProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
    );

    // 0.40 - 0.72: Menyatu ke pusat
    _combineProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.72, curve: Curves.easeInOutCubicEmphasized),
    );

    // 0.72 - 0.85: Snap & Pulse logo
    _snapPulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.85),
      ),
    );

    // 0.72 - 0.90: Glow & badge
    _badgeGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.90, curve: Curves.easeOutBack),
    );

    // 0.75 - 0.90: Nama brand & tagline fade in
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 0.90, curve: Curves.easeOut),
    );

    // 0.92 - 1.0: Transisi keluar (fade out halus)
    _screenFadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onAnimationComplete();
      }
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache gambar pakaian agar render instan tanpa flicker
    precacheImage(const AssetImage('assets/images/anim_shirt.png'), context);
    precacheImage(const AssetImage('assets/images/anim_pants.png'), context);
    precacheImage(const AssetImage('assets/images/anim_shoes.png'), context);
  }

  void _onAnimationComplete() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final user = ref.read(authStateProvider).value ??
        ref.read(authServiceProvider).currentUser;

    if (user != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenOpacity = 1.0 - _screenFadeOut.value;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Opacity(
            opacity: screenOpacity.clamp(0.0, 1.0),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background ambient radial gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.9,
                          colors: [
                            AppTheme.primaryColor.withValues(
                              alpha: 0.08 * _badgeGlow.value,
                            ),
                            AppTheme.backgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Area Animasi Tengah
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Container Outfit Flat Lay
                        _buildAntigravityOutfit(),

                        const SizedBox(height: 28),

                        // Logo Teks & Brand Info
                        _buildBrandInfo(),
                      ],
                    ),
                  ),

                  // Indikator Loading Bawah yang Minimalis
                  Positioned(
                    bottom: 28,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: (_fadeIn.value * (1.0 - _badgeGlow.value))
                            .clamp(0.0, 1.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menyiapkan gaya...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Membangun 3 elemen pakaian yang melayang secara acak, kemudian menyatu
  Widget _buildAntigravityOutfit() {
    // Ukuran stage outfit
    const double stageWidth = 260;
    const double stageHeight = 330;

    // Nilai progress
    final floatVal = _floatProgress.value;
    final combineVal = _combineProgress.value;
    final pulseScale = _snapPulse.value;

    // Nilai osilasi floating (sine wave) saat fase 1
    final wave1 = math.sin(floatVal * math.pi * 2) * 12.0;
    final wave2 = math.cos(floatVal * math.pi * 2 + 1.0) * 10.0;
    final wave3 = math.sin(floatVal * math.pi * 2 + 2.5) * 8.0;

    // Rotasi: mulai miring, lalu menuju 0 saat menyatu
    final shirtAngle = (-0.14 * (1.0 - combineVal)) + (0.02 * math.sin(floatVal * 6));
    final pantsAngle = (0.12 * (1.0 - combineVal)) - (0.02 * math.cos(floatVal * 6));
    final shoesAngle = (-0.10 * (1.0 - combineVal)) + (0.015 * math.sin(floatVal * 5));

    // Posisi Shirt (Atas):
    // Target akhir: center-x, top: 0
    final shirtOffset = Offset(
      (-65.0 * (1.0 - combineVal)),
      (-50.0 * (1.0 - combineVal)) + (wave1 * (1.0 - combineVal)),
    );

    // Posisi Pants (Tengah):
    // Target akhir: center-x, top: 110
    final pantsOffset = Offset(
      (60.0 * (1.0 - combineVal)),
      (35.0 * (1.0 - combineVal)) + (wave2 * (1.0 - combineVal)),
    );

    // Posisi Shoes (Bawah):
    // Target akhir: center-x, top: 275
    final shoesOffset = Offset(
      (-40.0 * (1.0 - combineVal)),
      (55.0 * (1.0 - combineVal)) + (wave3 * (1.0 - combineVal)),
    );

    return Transform.scale(
      scale: pulseScale,
      child: Container(
        width: stageWidth,
        height: stageHeight,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Lingkaran latar / aura logo saat outfit menyatu
            if (_badgeGlow.value > 0.01)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 250 * _badgeGlow.value,
                    height: 250 * _badgeGlow.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(
                        alpha: 0.05 * _badgeGlow.value,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(
                          alpha: 0.15 * _badgeGlow.value,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // 1. ELEMEN SEPATU (Layer paling bawah / z-index 1)
            Positioned(
              top: 275,
              child: Opacity(
                opacity: _fadeIn.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: shoesOffset,
                  child: Transform.rotate(
                    angle: shoesAngle,
                    child: Image.asset(
                      'assets/images/anim_shoes.png',
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // 2. ELEMEN CELANA (Layer tengah / z-index 2)
            Positioned(
              top: 108,
              child: Opacity(
                opacity: _fadeIn.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: pantsOffset,
                  child: Transform.rotate(
                    angle: pantsAngle,
                    child: Image.asset(
                      'assets/images/anim_pants.png',
                      height: 175,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // 3. ELEMEN KEMEJA & KAOS (Layer atas / z-index 3)
            Positioned(
              top: 0,
              child: Opacity(
                opacity: _fadeIn.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: shirtOffset,
                  child: Transform.rotate(
                    angle: shirtAngle,
                    child: Image.asset(
                      'assets/images/anim_shirt.png',
                      height: 118,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun tulisan merek PakeAja yang muncul saat outfit menyatu
  Widget _buildBrandInfo() {
    final textOpacity = _textFade.value.clamp(0.0, 1.0);
    final slideY = (1.0 - textOpacity) * 12.0;

    return Opacity(
      opacity: textOpacity,
      child: Transform.translate(
        offset: Offset(0, slideY),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'OUTFIT LENGKAP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.appTagline,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
