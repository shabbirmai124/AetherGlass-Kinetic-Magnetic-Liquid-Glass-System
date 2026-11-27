import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Hardware-aware display geometry utilities and dynamic Bezier glass path
/// constructor.
abstract final class AetherAdaptiveGeometry {
  /// Resolves concentric corner radii harmonized with the physical screen's
  /// [MediaQueryData.displayCornerRadii] when reported by the platform.
  ///
  /// Falls back cleanly to [fallback] on desktop, web, or square displays.
  static BorderRadius resolveCardRadius(
    BuildContext context, {
    BorderRadius fallback = const BorderRadius.all(Radius.circular(24.0)),
    double inset = 16.0,
    double minRadius = 14.0,
    double maxRadius = 40.0,
  }) {
    final displayRadii = MediaQuery.maybeDisplayCornerRadiiOf(context);
    if (displayRadii == null) {
      return fallback;
    }

    final hasCurve =
        displayRadii.topLeft.x > 0.0 ||
        displayRadii.topRight.x > 0.0 ||
        displayRadii.bottomLeft.x > 0.0 ||
        displayRadii.bottomRight.x > 0.0;
    if (!hasCurve) {
      return fallback;
    }

    Radius adaptCorner(Radius hw, Radius fb) {
      if (hw.x <= 0.0 && hw.y <= 0.0) {
        return fb;
      }
      final rx = (hw.x - inset).clamp(minRadius, maxRadius);
      final ry = (hw.y - inset).clamp(minRadius, maxRadius);
      return Radius.elliptical(rx, ry);
    }

    return BorderRadius.only(
      topLeft: adaptCorner(displayRadii.topLeft, fallback.topLeft),
      topRight: adaptCorner(displayRadii.topRight, fallback.topRight),
      bottomLeft: adaptCorner(displayRadii.bottomLeft, fallback.bottomLeft),
      bottomRight: adaptCorner(displayRadii.bottomRight, fallback.bottomRight),
    );
  }

  /// Resolves safe margins incorporating hardware [displayCornerRadii] and
  /// system view padding so magnetic Bezier stretch never clips awkwardly.
  static EdgeInsets resolveAdaptiveMargin(
    BuildContext context, {
    EdgeInsets base = const EdgeInsets.all(16.0),
    double magneticReserve = 6.0,
  }) {
    final displayRadii = MediaQuery.maybeDisplayCornerRadiiOf(context);
    final viewPadding = MediaQuery.maybePaddingOf(context) ?? EdgeInsets.zero;
    if (displayRadii == null) {
      return base + viewPadding;
    }

    final topCurve = math.max(displayRadii.topLeft.y, displayRadii.topRight.y);
    final bottomCurve = math.max(
      displayRadii.bottomLeft.y,
      displayRadii.bottomRight.y,
    );
    final extraTop = topCurve > 24.0 ? magneticReserve : 0.0;
    final extraBottom = bottomCurve > 24.0 ? magneticReserve : 0.0;

    return EdgeInsets.fromLTRB(
      base.left + viewPadding.left,
      base.top + viewPadding.top + extraTop,
      base.right + viewPadding.right,
      base.bottom + viewPadding.bottom + extraBottom,
    );
  }

  /// Returns `true` when reduced-motion accessibility is requested via OS or app.
  static bool isReducedMotion(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reduceMotion = MediaQuery.maybeReduceMotionOf(context) ?? false;
    return disableAnimations || reduceMotion;
  }

  /// Builds or updates [target] in-place with four rounded corner arcs joined
  /// by four dynamic quadratic Bezier edges flexed by [edgePull].
  static Path buildPath({
    required Size size,
    required BorderRadius borderRadius,
    required Offset edgePull,
    required double flexAmount,
    Path? target,
  }) {
    final path = (target ?? Path())..reset();
    final w = size.width;
    final h = size.height;
    if (w <= 0.0 || h <= 0.0) {
      return path;
    }

    final maxR = math.min(w, h) * 0.45;
    final tl = borderRadius.topLeft.x.clamp(0.0, maxR);
    final tr = borderRadius.topRight.x.clamp(0.0, maxR);
    final br = borderRadius.bottomRight.x.clamp(0.0, maxR);
    final bl = borderRadius.bottomLeft.x.clamp(0.0, maxR);

    final maxDeflect = flexAmount * 1.15;
    final topDy = _edgeDeflection(edgePull.dy, -1.0, flexAmount, maxDeflect);
    final bottomDy = _edgeDeflection(edgePull.dy, 1.0, flexAmount, maxDeflect);
    final leftDx = _edgeDeflection(edgePull.dx, -1.0, flexAmount, maxDeflect);
    final rightDx = _edgeDeflection(edgePull.dx, 1.0, flexAmount, maxDeflect);

    path.moveTo(tl, 0.0);
    path.quadraticBezierTo(w * 0.5, topDy, w - tr, 0.0);

    if (tr > 0.0) {
      path.arcToPoint(Offset(w, tr), radius: Radius.circular(tr));
    } else {
      path.lineTo(w, 0.0);
    }

    path.quadraticBezierTo(w + rightDx, h * 0.5, w, h - br);

    if (br > 0.0) {
      path.arcToPoint(Offset(w - br, h), radius: Radius.circular(br));
    } else {
      path.lineTo(w, h);
    }

    path.quadraticBezierTo(w * 0.5, h + bottomDy, bl, h);

    if (bl > 0.0) {
      path.arcToPoint(Offset(0.0, h - bl), radius: Radius.circular(bl));
    } else {
      path.lineTo(0.0, h);
    }

    path.quadraticBezierTo(leftDx, h * 0.5, 0.0, tl);

    if (tl > 0.0) {
      path.arcToPoint(Offset(tl, 0.0), radius: Radius.circular(tl));
    } else {
      path.lineTo(0.0, 0.0);
    }

    path.close();
    return path;
  }

  static double _edgeDeflection(
    double pull,
    double outwardSign,
    double flexAmount,
    double maxDeflect,
  ) {
    final towardEdge = pull * outwardSign > 0.0;
    final raw = towardEdge ? pull * flexAmount : pull * flexAmount * 0.28;
    return raw.clamp(-maxDeflect, maxDeflect);
  }
}

/// Custom clipper shaping liquid-glass panels with four corner arcs connected
/// by four finger-reactive Bezier edges.
class LiquidEdgeClipper extends CustomClipper<Path> {
  /// Creates a [LiquidEdgeClipper] flexing with [edgePull] and [flexAmount].
  LiquidEdgeClipper({
    required this.borderRadius,
    required this.edgePull,
    required this.flexAmount,
  });

  /// Base corner radii (resolved from hardware display corners or fallback).
  final BorderRadius borderRadius;

  /// Normalized magnetic pull vector from [AetherFieldController].
  final Offset edgePull;

  /// Maximum Bezier midpoint displacement in logical pixels.
  final double flexAmount;

  final Path _cachedPath = Path();

  @override
  Path getClip(Size size) {
    return AetherAdaptiveGeometry.buildPath(
      size: size,
      borderRadius: borderRadius,
      edgePull: edgePull,
      flexAmount: flexAmount,
      target: _cachedPath,
    );
  }

  @override
  bool shouldReclip(covariant LiquidEdgeClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.flexAmount != flexAmount ||
        (oldClipper.edgePull - edgePull).distanceSquared > 0.00008;
  }
}
