import 'package:flutter/material.dart';

/// A subtle, full-bleed noise/grain texture overlay (~2% opacity) that gives
/// the scaffold a premium, tactile feel — matching the Stitch design system's
/// `noise-overlay` layer.
///
/// Place it as the first child of a `Stack` (or wrap the scaffold body) so it
/// sits above the background colour but below real content. It ignores
/// pointers and is wrapped in a `RepaintBoundary` so the static noise is
/// painted once and cheaply cached.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, this.opacity = 0.025});

  /// Overall opacity of the noise. The design system uses 0.02–0.03.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(opacity: opacity),
          willChange: false,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic pseudo-noise: stamp a low-alpha dot on a 6px grid using a
    // hash of the cell coordinates. Cheap, static, and reproducible.
    const double step = 6;
    final Paint paint = Paint();
    final int cols = (size.width / step).ceil();
    final int rows = (size.height / step).ceil();
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final int h = _hash(x, y);
        if ((h & 7) != 0) {
          continue; // keep ~12% of cells, sparse -> light texture.
        }
        final double a = ((h >> 3) & 0xFF) / 0xFF * opacity;
        paint.color = Color.fromRGBO(15, 15, 18, a);
        canvas.drawCircle(
          Offset(x * step + (h % 5), y * step + ((h >> 5) % 5)),
          0.6,
          paint,
        );
      }
    }
  }

  static int _hash(int x, int y) {
    int n = x * 374761393 + y * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    return (n ^ (n >> 16)) & 0x7FFFFFFF;
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.opacity != opacity;
}
