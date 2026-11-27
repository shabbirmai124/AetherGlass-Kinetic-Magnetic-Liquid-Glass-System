import 'dart:typed_data';
import 'dart:ui';

import 'spring_solver.dart';

/// Spatial registration node tracking a glass card or magnetic button's
/// stage-local bounds, center, and pre-allocated spring deformation states.
final class SpatialCardNode {
  /// Creates a [SpatialCardNode] for a glass surface identified by [id].
  SpatialCardNode({
    required this.id,
    required this.bounds,
    required int rippleCapacity,
  }) : reactedRippleGenerations = Int32List(rippleCapacity);

  /// Unique token identifying the registered card or button state.
  final Object id;

  /// Current bounding rectangle in stage-local coordinates.
  Rect bounds;

  /// Geometric center of [bounds] in stage-local coordinates.
  Offset get center => bounds.center;

  /// 3D X-axis tilt spring in radians (capped at 7.0 degrees).
  final AetherSpringState tiltX = AetherSpringState();

  /// 3D Y-axis tilt spring in radians (capped at 7.0 degrees).
  final AetherSpringState tiltY = AetherSpringState();

  /// Inward scale depression spring (`0..1`).
  final AetherSpringState depression = AetherSpringState();

  /// Horizontal magnetic Bezier edge pull (`-1..1`).
  final AetherSpringState edgePullX = AetherSpringState();

  /// Vertical magnetic Bezier edge pull (`-1..1`).
  final AetherSpringState edgePullY = AetherSpringState();

  /// Specular rim glow intensity spring (`0..1`).
  final AetherSpringState hoverGlow = AetherSpringState();

  /// Press-and-hold magnetic suction spring (`0..1`).
  final AetherSpringState suction = AetherSpringState();

  /// Physical horizontal elastic translation in pixels (used by magnetic buttons).
  final AetherSpringState offsetX = AetherSpringState();

  /// Physical vertical elastic translation in pixels (used by magnetic buttons).
  final AetherSpringState offsetY = AetherSpringState();

  /// Maximum magnetic translation distance in logical pixels (`0` for cards).
  double maxMagneticOffset = 0.0;

  /// Tracks latest ripple generation applied per slot so each passing wave
  /// delivers a single clean angular impulse inside the 40 px wavefront band.
  final Int32List reactedRippleGenerations;

  /// Normalized specular gradient alignment X in `[-1.0, 1.0]`.
  double specularAlignX = -0.55;

  /// Normalized specular gradient alignment Y in `[-1.0, 1.0]`.
  double specularAlignY = -0.55;

  /// Whether the peak-stretch haptic snap has fired during the current press.
  bool hapticPeakFired = false;
}

/// Alias preserving compatibility for callers referencing [AetherCardForceState].
typedef AetherCardForceState = SpatialCardNode;
