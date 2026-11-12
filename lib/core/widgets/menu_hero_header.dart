import 'package:flutter/material.dart';

/// Palet warna terpadu yang konsisten dengan tampilan Beranda (`HomeScreen`).
abstract final class MenuUiColors {
  static const crimson = Color(0xFFC4202F);
  static const crimsonMid = Color(0xFFE8392A);
  static const crimsonLight = Color(0xFFEF5537);
  static const surface = Color(0xFFF6F7FA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFEDF0F3);

  static const heroGradient = LinearGradient(
    colors: [crimson, crimsonMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ctaGradient = LinearGradient(
    colors: [crimson, crimsonLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Header hero bergradasi crimson dengan lingkaran dekoratif, baris judul,
/// dan baris stat chip yang mengikuti desain `HomeScreen`.
class MenuHeroHeader extends StatelessWidget {
  final Widget? leading;
  final String subtitle;
  final bool uppercaseSubtitle;
  final String title;
  final String? caption;
  final List<Widget> actions;
  final List<Widget> statChips;
  final Widget? bottomContent;
  final EdgeInsetsGeometry? padding;

  const MenuHeroHeader({
    super.key,
    this.leading,
    required this.subtitle,
    this.uppercaseSubtitle = false,
    required this.title,
    this.caption,
    this.actions = const [],
    this.statChips = const [],
    this.bottomContent,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          width: double.infinity,
          padding: padding ??
              EdgeInsets.fromLTRB(
                20,
                topInset + 18,
                20,
                26,
              ),
          decoration: const BoxDecoration(
            gradient: MenuUiColors.heroGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 13),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: uppercaseSubtitle ? 11.5 : 13,
                            fontWeight: uppercaseSubtitle
                                ? FontWeight.bold
                                : FontWeight.w400,
                            letterSpacing: uppercaseSubtitle ? 0.8 : 0,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (caption != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          actions[i],
                        ],
                      ],
                    ),
                  ],
                ],
              ),
              if (bottomContent != null) ...[
                const SizedBox(height: 16),
                bottomContent!,
              ],
              if (statChips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: statChips,
                ),
              ],
            ],
          ),
        ),

        // Lingkaran dekoratif transparan di kanan seperti pada HomeScreen
        Positioned(
          right: -30,
          top: -20 + topInset * 0.3,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        Positioned(
          right: 30,
          bottom: 10,
          child: IgnorePointer(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol ikon melingkar transparan di atas hero header bergradasi.
class HeroGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const HeroGlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Chip statistik transparan di dalam hero header.
class HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const HeroStatChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol aksi utama dengan gradasi crimson-coral seperti tombol utama HomeScreen.
class PakeAjaGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final double height;
  final double borderRadius;

  const PakeAjaGradientButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.height = 44,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: MenuUiColors.ctaGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: MenuUiColors.crimson.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null
              ? Icon(icon, size: 17, color: Colors.white)
              : const SizedBox.shrink(),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ),
    );
  }
}

