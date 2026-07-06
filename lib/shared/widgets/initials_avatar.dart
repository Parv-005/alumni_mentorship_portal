import 'package:flutter/material.dart';

/// A [CircleAvatar] that shows bold initials over a solid coloured background,
/// where the background is chosen deterministically from a short muted palette
/// keyed off the person's name. This keeps two users with the same initials
/// from colliding on colour, matching the NALUM avatar spec.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 14,
    this.background,
    this.foreground,
  });

  /// Display name to derive initials and colour from.
  final String name;

  /// Circle radius in logical pixels.
  final double radius;

  /// Override the deterministic background colour.
  final Color? background;

  /// Override the initials text colour.
  final Color? foreground;

  static const List<Color> _palette = <Color>[
    Color(0xFF0F766E), // teal
    Color(0xFFD97706), // amber
    Color(0xFF2563EB), // blue
    Color(0xFF7C3AED), // plum
    Color(0xFFDC2626), // red
    Color(0xFF0891B2), // cyan
  ];

  Color _colorFor(String n) {
    if (background != null) {
      return background!;
    }
    int hash = 0;
    for (final int c in n.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return _palette[hash % _palette.length];
  }

  String _initialsOf(String n) {
    final trimmed = n.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].characters.first.toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = _colorFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        _initialsOf(name),
        style: TextStyle(
          color: foreground ?? Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.85,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
