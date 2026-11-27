import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';
import '../theme/aether_theme_data.dart';

/// Single-pass background canvas painter rendering drifting ambient motes,
/// expanding luminous ripple rings, pointer aura, and the 14-point tapered
/// fluid wake ribbon (`14.0` px head to `0.0` px tail over `280` ms).
///
/// Pre-allocates all [Paint], [MaskFilter], and [Path] instances once so zero
/// garbage-collection pressure occurs inside [paint].
class AetherFieldPainter extends CustomPainter {
  /// Creates an [AetherFieldPainter] repainting directly from [controller].
  AetherFieldPainter({
    required this.controller,
    this.paintBackground = true,
  }) : super(repaint: controller);

  /// Centralized physics engine providing zero-allocation pool snapshots.
  final AetherFieldController controller;

  /// Whether to paint the atmospheric preset gradient backdrop.
  final bool paintBackground;

  final Paint _bgPaint = Paint();
  final Paint _auraPaint = Paint();
  final Paint _rippleGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  final Paint _rippleCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _moteGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
  final Paint _moteCorePaint = Paint()..style = PaintingStyle.fill;
  final Paint _ribbonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _ribbonGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

  final Path _ribbonPath = Path();

  Size _cachedBgSize = Size.zero;
  AetherThemeData? _cachedTheme;
  Offset _cachedAuraCenter = const Offset(-9999, -9999);
  Color? _cachedAuraColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0.0 || size.height <= 0.0) {
      return;
    }
    final theme = controller.theme;

    if (paintBackground) {
      _paintBackground(canvas, size, theme);
    }
    _paintPointerAura(canvas, theme);
    _paintMotes(canvas, theme);
    _paintRipples(canvas, theme);
    _paintWakeRibbon(canvas, theme);
  }

  void _paintBackground(Canvas canvas, Size size, AetherThemeData theme) {
    if (_cachedBgSize != size || _cachedTheme != theme) {
      _cachedBgSize = size;
      _cachedTheme = theme;
      _bgPaint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width * 0.45, size.height),
        theme.backgroundColors,
        _evenStops(theme.backgroundColors.length),
      );
    }
    canvas.drawRect(Offset.zero & size, _bgPaint);
  }

  void _paintPointerAura(Canvas canvas, AetherThemeData theme) {
    if (!controller.hasPointer) {
      return;
    }
    final ptr = controller.trailingPointer;
    final radius = math.max(theme.activationRadius * 1.15, 130.0);
    final alpha = controller.isPointerDown ? 0.22 : 0.11;
    final inner = theme.ripplePrimaryColor.withValues(alpha: alpha);
    final outer = theme.ripplePrimaryColor.withValues(alpha: 0.0);

    if ((_cachedAuraCenter - ptr).distanceSquared > 1.0 ||
        _cachedAuraColor != inner) {
      _cachedAuraCenter = ptr;
      _cachedAuraColor = inner;
      _auraPaint.shader = ui.Gradient.radial(
        ptr,
        radius,
        <Color>[inner, outer],
      );
    }
    canvas.drawCircle(ptr, radius, _auraPaint);
  }

  void _paintMotes(Canvas canvas, AetherThemeData theme) {
    final motes = controller.particles;
    final alphaFactor = controller.reducedMotion ? 0.40 : 1.0;

    for (var i = 0; i < motes.length; i++) {
      final m = motes[i];
      if (!m.seeded) {
        continue;
      }
      final base = m.colorWeight < 0.5
          ? theme.particlePrimaryColor
          : theme.particleSecondaryColor;
      final alpha = (m.opacity * alphaFactor).clamp(0.0, 1.0);
      if (alpha <= 0.01) {
        continue;
      }

      _moteGlowPaint.color = base.withValues(alpha: alpha * 0.42);
      _moteCorePaint.color = base.withValues(alpha: alpha);

      final center = Offset(m.x, m.y);
      canvas.drawCircle(center, m.radius * 2.1, _moteGlowPaint);
      canvas.drawCircle(center, m.radius, _moteCorePaint);
    }
  }

  void _paintRipples(Canvas canvas, AetherThemeData theme) {
    final ripples = controller.ripples;
    for (var i = 0; i < ripples.length; i++) {
      final r = ripples[i];
      if (!r.active || r.intensity <= 0.01) {
        continue;
      }
      final progress = r.progress;
      final stroke =
          (r.strokeWidth * (1.0 - progress * 0.72)).clamp(0.6, r.strokeWidth);
      final alpha = r.intensity.clamp(0.0, 1.0);
      final center = Offset(r.originX, r.originY);

      _rippleGlowPaint
        ..strokeWidth = stroke * 2.4
        ..color = theme.rippleSecondaryColor.withValues(alpha: alpha * 0.48);
      canvas.drawCircle(center, r.radius, _rippleGlowPaint);

      _rippleCorePaint
        ..strokeWidth = stroke
        ..color = theme.ripplePrimaryColor.withValues(alpha: alpha * 0.92);
      canvas.drawCircle(center, r.radius, _rippleCorePaint);
    }
  }

  void _paintWakeRibbon(Canvas canvas, AetherThemeData theme) {
    if (controller.reducedMotion) {
      return;
    }
    final trail = controller.trailPoints;
    final len = trail.length;
    final head = controller.trailHead;

    var prevX = 0.0;
    var prevY = 0.0;
    var prevLife = 0.0;
    var hasPrev = false;

    for (var step = 0; step < len; step++) {
      final idx = (head - step + len) % len;
      final pt = trail[idx];
      if (!pt.active || pt.life <= 0.01) {
        continue;
      }
      // Taper cleanly from 14.0 px head width down to 0.0 px tail width.
      final taper = 1.0 - (step / math.max(len - 1, 1));
      final life = pt.life * taper;

      if (hasPrev) {
        final midX = (prevX + pt.x) * 0.5;
        final midY = (prevY + pt.y) * 0.5;
        final segAlpha = ((prevLife + life) * 0.5).clamp(0.0, 1.0);
        final segWidth = 14.0 * segAlpha;
        if (segWidth > 0.05) {
          _ribbonPath
            ..reset()
            ..moveTo(prevX, prevY)
            ..quadraticBezierTo(prevX, prevY, midX, midY);

          _ribbonGlowPaint
            ..strokeWidth = segWidth * 1.65
            ..color = theme.ribbonEndColor.withValues(alpha: segAlpha * 0.36);
          canvas.drawPath(_ribbonPath, _ribbonGlowPaint);

          _ribbonPaint
            ..strokeWidth = segWidth
            ..color = theme.ribbonStartColor.withValues(alpha: segAlpha * 0.84);
          canvas.drawPath(_ribbonPath, _ribbonPaint);
        }

        prevX = midX;
        prevY = midY;
        prevLife = life;
      } else {
        prevX = pt.x;
        prevY = pt.y;
        prevLife = life;
        hasPrev = true;
      }
    }
  }

  static List<double>? _evenStops(int count) {
    if (count == 2) {
      return const <double>[0.0, 1.0];
    }
    if (count == 3) {
      return const <double>[0.0, 0.52, 1.0];
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant AetherFieldPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.paintBackground != paintBackground;
  }
}
