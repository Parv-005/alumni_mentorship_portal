import 'package:alumni_mentorship_platform/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Small badge showing the user's role (student / alumni / admin).
///
/// Refined to the NALUM tint set: alumni = teal tint, student = blue tint,
/// admin = red tint — low-alpha background with high-contrast text, pill
/// shaped (radius 999).
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final _RoleSpec spec = _specFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(spec.icon, size: 14, color: spec.foreground),
          const SizedBox(width: 4),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static _RoleSpec _specFor(String role) {
    switch (role) {
      case 'alumni':
        return const _RoleSpec(
          label: 'Alumni',
          icon: Icons.workspace_premium_outlined,
          background: AppColors.alumniBg,
          foreground: AppColors.alumniFg,
        );
      case 'admin':
        return const _RoleSpec(
          label: 'Admin',
          icon: Icons.shield_outlined,
          background: AppColors.adminBg,
          foreground: AppColors.adminFg,
        );
      case 'student':
      default:
        return const _RoleSpec(
          label: 'Student',
          icon: Icons.school_outlined,
          background: AppColors.studentBg,
          foreground: AppColors.studentFg,
        );
    }
  }
}

class _RoleSpec {
  const _RoleSpec({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}
