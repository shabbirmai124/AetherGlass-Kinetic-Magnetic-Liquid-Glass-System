/// Pure-Dart framerate-independent spring-damper solver for AetherGlass.
library;

/// Mutable 1D spring state updated in-place to avoid per-frame allocations.
final class AetherSpringState {
  /// Creates a spring state initialized at [value], [velocity], and [target].
  AetherSpringState({
    this.value = 0.0,
    this.velocity = 0.0,
    this.target = 0.0,
  });

  /// Current position/value of the spring.
  double value;

  /// Current velocity in units per second.
  double velocity;

  /// Equilibrium target used by standalone spring callers.
  double target;

  /// Alias for [value] matching classical spring kinematics terminology.
  double get position => value;

  /// Updates [value].
  set position(double v) => value = v;

  /// Returns `true` when both displacement from [target] and [velocity] fall
  /// strictly below the settling thresholds.
  bool isSettled({
    double? target,
    double positionEpsilon = 0.01,
    double velocityEpsilon = 0.01,
  }) {
    final effectiveTarget = target ?? this.target;
    return (value - effectiveTarget).abs() < positionEpsilon &&
        velocity.abs() < velocityEpsilon;
  }

  /// Resets [value] and [target], snapping [velocity] to zero.
  void reset([double value = 0.0]) {
    this.value = value;
    target = value;
    velocity = 0.0;
  }
}

/// Symplectic sub-stepped spring-damper solver producing consistent curves across
/// 30Hz, 60Hz, 90Hz, and 120Hz displays with `dt <= 0.033s` clamping.
abstract final class SpringSolver {
  /// Maximum allowed frame delta time (33 ms) preventing jumps after pauses.
  static const double maxFrameDeltaSeconds = 0.033;

  /// Maximum integration substep (~240Hz) ensuring numerical stability even
  /// under high-stiffness presets and 30Hz frame intervals.
  static const double defaultMaxSubStep = 1.0 / 240.0;

  /// Advances [state] toward [target] over [dt] seconds in-place.
  ///
  /// Automatically snaps `state.velocity = 0.0` and `state.value = target`
  /// when `|velocity| < velocityEpsilon` and `|displacement| < positionEpsilon`.
  /// Returns `true` when settled.
  static bool step({
    required AetherSpringState state,
    required double target,
    required double stiffness,
    required double damping,
    required double dt,
    double maxSubStep = defaultMaxSubStep,
    double positionEpsilon = 0.01,
    double velocityEpsilon = 0.01,
  }) {
    if (dt <= 0.0 || !dt.isFinite) {
      return state.isSettled(
        target: target,
        positionEpsilon: positionEpsilon,
        velocityEpsilon: velocityEpsilon,
      );
    }

    var remaining = dt > maxFrameDeltaSeconds ? maxFrameDeltaSeconds : dt;
    while (remaining > 0.0) {
      final subDt = remaining > maxSubStep ? maxSubStep : remaining;
      final displacement = target - state.value;
      final acceleration = displacement * stiffness - state.velocity * damping;
      state.velocity += acceleration * subDt;
      state.value += state.velocity * subDt;
      remaining -= subDt;
    }

    if (state.isSettled(
      target: target,
      positionEpsilon: positionEpsilon,
      velocityEpsilon: velocityEpsilon,
    )) {
      state.value = target;
      state.velocity = 0.0;
      return true;
    }
    return false;
  }
}
