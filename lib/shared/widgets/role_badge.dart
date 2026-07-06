import 'package:flutter/material.dart';

/// Small badge showing the user's role (student / alumni / admin).
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
          background: Color(0xFFD1C4E9),
          foreground: Color(0xFF311B92),
        );
      case 'admin':
        return const _RoleSpec(
          label: 'Admin',
          icon: Icons.shield_outlined,
          background: Color(0xFFFFCDD2),
          foreground: Color(0xFFB71C1C),
        );
      case 'student':
      default:
        return const _RoleSpec(
          label: 'Student',
          icon: Icons.school_outlined,
          background: Color(0xFFB3E5FC),
          foreground: Color(0xFF01579B),
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
