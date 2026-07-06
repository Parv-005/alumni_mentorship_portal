import 'package:flutter/material.dart';

/// Colored pill that maps a booking `status` to a color + label.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final _StatusSpec spec = _specFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static _StatusSpec _specFor(String status) {
    switch (status) {
      case 'pending':
        return const _StatusSpec(
          label: 'Pending',
          background: Color(0xFFFFE082),
          foreground: Color(0xFF6B4E00),
        );
      case 'accepted':
        return const _StatusSpec(
          label: 'Accepted',
          background: Color(0xFFA5D6A7),
          foreground: Color(0xFF1B5E20),
        );
      case 'declined':
        return const _StatusSpec(
          label: 'Declined',
          background: Color(0xFFEF9A9A),
          foreground: Color(0xFFB71C1C),
        );
      case 'rescheduled':
        return const _StatusSpec(
          label: 'Rescheduled',
          background: Color(0xFF90CAF9),
          foreground: Color(0xFF0D47A1),
        );
      case 'completed':
        return const _StatusSpec(
          label: 'Completed',
          background: Color(0xFFCE93D8),
          foreground: Color(0xFF4A148C),
        );
      default:
        return _StatusSpec(
          label: status,
          background: const Color(0xFFE0E0E0),
          foreground: const Color(0xFF424242),
        );
    }
  }
}

class _StatusSpec {
  const _StatusSpec({
    required this.label,
    required this.background,
    required this.foreground,
  });
  final String label;
  final Color background;
  final Color foreground;
}
