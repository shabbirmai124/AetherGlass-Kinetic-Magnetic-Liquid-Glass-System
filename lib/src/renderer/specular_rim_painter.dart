import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'liquid_edge_clipper.dart';

/// Paints a razor-thin glossy specular border and inner surface refraction
/// sheen along the exact deformed Bezier outline of a liquid-glass card.
class SpecularRimPainter extends CustomPainter {
  /// Creates a [SpecularRimPainter] reacting to pointer angle and glow.
  SpecularRimPainter({
    required this.borderRadius,
    required this.edgePull,
    required this.flexAmount,
    required this.specularAlign,
    required this.hoverGlow,
    required this.baseBorderColor,
    required this.specularColor,
    required this.specularIntensity,
    this.strokeWidth = 1.2,
  });

  /// Corner curvature matched to [LiquidEdgeClipper].
  final BorderRadius borderRadius;

  /// Magnetic Bezier pull vector.
  final Offset edgePull;

  /// Maximum Bezier edge flex in logical pixels.
  final double flexAmount;

  /// Normalized `[-1.0, 1.0]` directional vector toward the active pointer.
  final Offset specularAlign;

  /// Dynamic glow boost `[0.0, 1.0]` from proximity or ripple impact.
  final double hoverGlow;

  /// Subtle resting glass edge color.
  final Color baseBorderColor;

  /// Specular highlight color sweeping across the rim.
  final Color specularColor;

  /// Theme specular intensity multiplier.
  final double specularIntensity;

  /// Rim stroke thickness in logical pixels.
  final double strokeWidth;

  final Path _outlinePath = Path();
  final Paint _baseRimPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _specularRimPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _sheenPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0.0 || size.height <= 0.0) {
      return;
    }

    AetherAdaptiveGeometry.buildPath(
      size: size,
      borderRadius: borderRadius,
      edgePull: edgePull,
      flexAmount: flexAmount,
      target: _outlinePath,
    );

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final highlightPos = Offset(
      center.dx + specularAlign.dx * size.width * 0.52,
      center.dy + specularAlign.dy * size.height * 0.52,
    );
    final oppositePos = Offset(
      center.dx - specularAlign.dx * size.width * 0.52,
      center.dy - specularAlign.dy * size.height * 0.52,
    );

    final intensity = (0.35 + hoverGlow * 0.65) * specularIntensity;

    // 1. Subtle inner glass light refraction sheen sweeping across the surface.
    _sheenPaint.shader = ui.Gradient.linear(
      highlightPos,
      oppositePos,
      <Color>[
        specularColor.withValues(alpha: (0.14 * intensity).clamp(0.0, 0.35)),
        specularColor.withValues(alpha: (0.03 * intensity).clamp(0.0, 0.15)),
        specularColor.withValues(alpha: 0.0),
      ],
      const <double>[0.0, 0.42, 1.0],
    );
    canvas.drawPath(_outlinePath, _sheenPaint);

    // 2. Resting frosted rim stroke.
    _baseRimPaint
      ..strokeWidth = strokeWidth
      ..color = baseBorderColor;
    canvas.drawPath(_outlinePath, _baseRimPaint);

    // 3. Moving directional specular highlight along the curved edge.
    _specularRimPaint
      ..strokeWidth = strokeWidth + hoverGlow * 0.75
      ..shader = ui.Gradient.linear(
        highlightPos,
        oppositePos,
        <Color>[
          specularColor.withValues(alpha: (0.95 * intensity).clamp(0.0, 1.0)),
          specularColor.withValues(alpha: (0.28 * intensity).clamp(0.0, 0.6)),
          specularColor.withValues(alpha: 0.02),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.drawPath(_outlinePath, _specularRimPaint);
  }

  @override
  bool shouldRepaint(covariant SpecularRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.flexAmount != flexAmount ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.baseBorderColor != baseBorderColor ||
        oldDelegate.specularColor != specularColor ||
        oldDelegate.specularIntensity != specularIntensity ||
        (oldDelegate.hoverGlow - hoverGlow).abs() > 0.005 ||
        (oldDelegate.edgePull - edgePull).distanceSquared > 0.00008 ||
        (oldDelegate.specularAlign - specularAlign).distanceSquared > 0.0004;
  }
}
