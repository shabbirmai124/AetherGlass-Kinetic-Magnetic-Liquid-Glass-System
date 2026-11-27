import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'ripple_wave_pool.dart';

/// Pre-allocated ambient background light mote inside [AmbientMotePool].
final class AetherMote {
  /// Creates an ambient mote anchored at normalized home coordinates.
  AetherMote({
    required this.homeNormX,
    required this.homeNormY,
    required this.radius,
    required this.baseOpacity,
    required this.phase,
    required this.driftAngle,
    required this.colorWeight,
  });

  /// Normalized resting X coordinate (`0..1`).
  final double homeNormX;

  /// Normalized resting Y coordinate (`0..1`).
  final double homeNormY;

  /// Current stage-local X coordinate.
  double x = 0.0;

  /// Current stage-local Y coordinate.
  double y = 0.0;

  /// Current X velocity in logical pixels per second.
  double vx = 0.0;

  /// Current Y velocity in logical pixels per second.
  double vy = 0.0;

  /// Whether coordinates have been seeded into a concrete viewport size.
  bool seeded = false;

  /// Core circle radius in logical pixels.
  final double radius;

  /// Resting opacity in `[0.0, 1.0]`.
  final double baseOpacity;

  /// Dynamic current opacity boosted during pointer/ripple deflection.
  double opacity = 0.35;

  /// Orbital phase angle in radians.
  double phase;

  /// Base orbital direction/speed phase multiplier.
  final double driftAngle;

  /// Blend factor `[0.0, 1.0]` between primary and secondary mote colors.
  final double colorWeight;
}

/// Fixed 50-slot pre-allocated ambient light mote field with `10.0 px/s` drift
/// and `0.94` per-frame fluid drag (normalized across refresh rates).
final class AmbientMotePool {
  /// Creates a pool pre-allocated with [capacity] motes (default 50).
  AmbientMotePool({this.capacity = 50})
      : assert(capacity >= 0 && capacity <= 150),
        _motes = _buildPool(capacity) {
    _view = UnmodifiableListView<AetherMote>(_motes);
  }

  /// Ambient drift speed in logical pixels per second.
  static const double ambientDriftSpeed = 10.0;

  /// Per-60Hz-frame fluid drag factor.
  static const double fluidDragPerFrame = 0.94;

  /// Fixed pool capacity (default 50 motes).
  final int capacity;

  final List<AetherMote> _motes;
  late final UnmodifiableListView<AetherMote> _view;

  /// Read-only zero-allocation view of all pre-allocated motes.
  UnmodifiableListView<AetherMote> get motes => _view;

  /// Seeds or clamps mote coordinates cleanly when viewport dimensions change.
  void resize(Size viewportSize) {
    if (viewportSize.width <= 0.0 || viewportSize.height <= 0.0) {
      return;
    }
    for (var i = 0; i < _motes.length; i++) {
      final m = _motes[i];
      if (!m.seeded) {
        m.x = m.homeNormX * viewportSize.width;
        m.y = m.homeNormY * viewportSize.height;
        m.seeded = true;
      } else {
        m.x = m.x.clamp(0.0, viewportSize.width);
        m.y = m.y.clamp(0.0, viewportSize.height);
      }
    }
  }

  /// Deflects nearby motes outward in the wake of a pointer drag.
  void applyPointerWake({
    required double px,
    required double py,
    required double dx,
    required double dy,
  }) {
    const influenceRadius = 140.0;
    const influenceRadiusSq = influenceRadius * influenceRadius;
    for (var i = 0; i < _motes.length; i++) {
      final m = _motes[i];
      if (!m.seeded) {
        continue;
      }
      final rx = m.x - px;
      final ry = m.y - py;
      final distSq = rx * rx + ry * ry;
      if (distSq > influenceRadiusSq || distSq < 0.001) {
        continue;
      }
      final dist = math.sqrt(distSq);
      final falloff = 1.0 - dist / influenceRadius;
      final swirlSign = (rx * dy - ry * dx) >= 0.0 ? 1.0 : -1.0;
      final invDist = 1.0 / dist;
      m.vx += (dx * 5.2 + (-ry * invDist) * swirlSign * 82.0) * falloff;
      m.vy += (dy * 5.2 + (rx * invDist) * swirlSign * 82.0) * falloff;
      m.opacity = (m.baseOpacity + falloff * 0.45).clamp(0.0, 1.0);
    }
  }

  /// Steps ambient orbital drift, fluid drag (`0.94`), and ripple deflection.
  ///
  /// Returns `true` when any mote retains velocity >= `0.01` px/s.
  bool step({
    required double dt,
    required Size viewportSize,
    required List<AetherRipple> ripples,
    required bool reducedMotion,
    required bool applyAmbientDrift,
  }) {
    if (_motes.isEmpty) {
      return false;
    }
    final width = viewportSize.width;
    final height = viewportSize.height;
    final drag = math.pow(fluidDragPerFrame, dt * 60.0).toDouble();
    var anyMoving = false;

    for (var i = 0; i < _motes.length; i++) {
      final m = _motes[i];
      if (!m.seeded) {
        m.x = m.homeNormX * width;
        m.y = m.homeNormY * height;
        m.seeded = true;
      }

      if (applyAmbientDrift && !reducedMotion) {
        m.phase += 0.65 * dt;
        final driftX = math.cos(m.phase + m.driftAngle) * ambientDriftSpeed;
        final driftY = math.sin(m.phase * 0.85 + m.driftAngle) * ambientDriftSpeed;
        final orbitX = m.homeNormX * width + driftX * 1.6;
        final orbitY = m.homeNormY * height + driftY * 1.6;
        m.vx += (orbitX - m.x) * 1.45 * dt;
        m.vy += (orbitY - m.y) * 1.45 * dt;
      }

      if (!reducedMotion) {
        for (var r = 0; r < ripples.length; r++) {
          final ripple = ripples[r];
          if (!ripple.active) {
            continue;
          }
          final rx = m.x - ripple.originX;
          final ry = m.y - ripple.originY;
          final dist = math.sqrt(rx * rx + ry * ry);
          final bandDelta = (dist - ripple.radius).abs();
          if (bandDelta < 40.0 && dist > 1.0) {
            final push =
                (1.0 - bandDelta / 40.0) * ripple.intensity * 195.0 * dt;
            m.vx += (rx / dist) * push;
            m.vy += (ry / dist) * push;
            m.opacity = math.max(
              m.opacity,
              (m.baseOpacity + ripple.intensity * 0.35).clamp(0.0, 1.0),
            );
          }
        }
      }

      m.vx *= drag;
      m.vy *= drag;
      if (!applyAmbientDrift && m.vx.abs() < 0.01 && m.vy.abs() < 0.01) {
        m.vx = 0.0;
        m.vy = 0.0;
      } else {
        m.x = (m.x + m.vx * dt).clamp(0.0, width);
        m.y = (m.y + m.vy * dt).clamp(0.0, height);
        anyMoving = true;
      }
      m.opacity += (m.baseOpacity - m.opacity) * (1.0 - math.exp(-3.6 * dt));
    }

    return anyMoving;
  }

  static List<AetherMote> _buildPool(int count) {
    var seed = 0x5A17C0DE;
    double nextUnit() {
      seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
      return seed / 0x7FFFFFFF;
    }

    return List<AetherMote>.generate(
      count,
      (int index) => AetherMote(
        homeNormX: 0.05 + nextUnit() * 0.90,
        homeNormY: 0.05 + nextUnit() * 0.90,
        radius: 1.4 + nextUnit() * 2.3,
        baseOpacity: 0.22 + nextUnit() * 0.36,
        phase: nextUnit() * math.pi * 2.0,
        driftAngle: nextUnit() * math.pi * 2.0,
        colorWeight: nextUnit(),
      ),
      growable: false,
    );
  }
}
