import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';

/// Optional screenshot-mode translucent touch-ring overlay rendered above an
/// [AetherStage] so static README visuals clearly show where a pointer is
/// pulling, holding, or swiping.
class CaptureTouchIndicator extends StatelessWidget {
  /// Creates a [CaptureTouchIndicator] observing [controller].
  const CaptureTouchIndicator({
    super.key,
    required this.controller,
    this.radius = 22.0,
  });

  /// Physics controller supplying live or pinned touch indicator coordinates.
  final AetherFieldController controller;

  /// Outer ring radius in logical pixels.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CaptureTouchPainter(controller: controller, radius: radius),
        ),
      ),
    );
  }
}

class _CaptureTouchPainter extends CustomPainter {
  _CaptureTouchPainter({required this.controller, required this.radius})
    : super(repaint: controller);

  final AetherFieldController controller;
  final double radius;

  final Paint _outerGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _corePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.showTouchIndicator) {
      return;
    }
    final pos =
        controller.pinnedTouchIndicator ??
        (controller.hasPointer ? controller.pointerPosition : null);
    if (pos == null) {
      return;
    }

    final color = controller.theme.specularColor;
    _outerGlowPaint.color = controller.theme.ripplePrimaryColor.withValues(
      alpha: 0.28,
    );
    _fillPaint.color = color.withValues(alpha: 0.14);
    _ringPaint.color = color.withValues(alpha: 0.85);
    _corePaint.color = color.withValues(alpha: 0.95);

    canvas.drawCircle(pos, radius * 1.35, _outerGlowPaint);
    canvas.drawCircle(pos, radius, _fillPaint);
    canvas.drawCircle(pos, radius, _ringPaint);
    canvas.drawCircle(pos, 4.5, _corePaint);
  }

  @override
  bool shouldRepaint(covariant _CaptureTouchPainter oldDelegate) {
    return oldDelegate.controller != controller || oldDelegate.radius != radius;
  }
}
