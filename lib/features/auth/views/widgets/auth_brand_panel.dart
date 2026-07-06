import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:alumni_mentorship_platform/shared/widgets/grain_overlay.dart';
import 'package:alumni_mentorship_platform/shared/widgets/nalum_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A trust bullet shown on the desktop auth brand panel. [subtitle] is optional
/// (login uses a single-line bullet; register adds a description).
class AuthTrustBullet {
  const AuthTrustBullet({
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
}

/// The teal brand panel used on the desktop (≥720px) auth screens.
///
/// Full-bleed teal gradient with a NALUM wordmark, a hero headline, supporting
/// copy, and a column of trust bullets. Shared by the login and register
/// screens so the brand voice stays consistent.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    super.key,
    required this.hero,
    required this.subtitle,
    required this.bullets,
    this.footer = '© 2024 NALUM Mentorship Network',
  });

  final String hero;
  final String subtitle;
  final List<AuthTrustBullet> bullets;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDeep],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: GrainOverlay(opacity: 0.03)),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBright.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -48,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const NalumLogo(size: 40, onColor: true),
                    const SizedBox(width: 12),
                    Text(
                      'NALUM',
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: text.headlineSmall,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  hero,
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: text.displaySmall,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: text.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                for (final AuthTrustBullet b in bullets) ...<Widget>[
                  _TrustBullet(bullet: b),
                  if (b != bullets.last) const SizedBox(height: 20),
                ],
                const Spacer(),
                Text(
                  footer,
                  style: text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBullet extends StatelessWidget {
  const _TrustBullet({required this.bullet});

  final AuthTrustBullet bullet;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: bullet.subtitle != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: bullet.subtitle != null ? 48 : 40,
          height: bullet.subtitle != null ? 48 : 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(bullet.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                bullet.label,
                style: text.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
              ),
              if (bullet.subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  bullet.subtitle!,
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
