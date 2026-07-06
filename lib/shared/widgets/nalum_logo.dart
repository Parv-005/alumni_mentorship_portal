import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The NALUM monogram: a rounded-square tile with a graduation-cap icon.
///
/// Re-creates the Stitch "NALUM Monogram Logo" asset as a vector widget so it
/// scales crisply and respects the colour mode. [onColor] renders the tile
/// as a white outline (for use on the teal brand panel); otherwise it renders
/// as a solid teal tile with a white icon (the default used on form panels).
class NalumLogo extends StatelessWidget {
  const NalumLogo({
    super.key,
    this.size = 56,
    this.onColor = false,
    this.radius = 12,
  });

  /// Edge length of the tile in logical pixels.
  final double size;

  /// When `true`, the tile is drawn as a white outline + white icon, suitable
  /// for placement on a teal (brand) background.
  final bool onColor;

  /// Corner radius of the tile.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color stroke = onColor
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.primary.withValues(alpha: 0.2);
    final Color bg = onColor ? Colors.transparent : AppColors.primary;
    final Color iconColor = Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: stroke, width: 1),
      ),
      child: Icon(Icons.school_outlined, size: size * 0.54, color: iconColor),
    );
  }
}
