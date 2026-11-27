import 'dart:collection';

/// Semantic classification of an expanding kinetic ripple wave.
enum AetherRippleKind {
  /// Fast-expanding ring emitted by a quick tap.
  tap,

  /// High-energy wave launched on swipe or magnetic button release.
  release,

  /// Gentle contact ring emitted when press-and-hold suction begins.
  suction,

  /// Programmatic or rhythmic shockwave pulse.
  pulse,
}

/// Pre-allocated mutable ripple slot owned by [RippleWavePool].
final class AetherRipple {
  /// Creates an inactive ripple slot.
  AetherRipple();

  /// Whether this wave is currently expanding across the stage.
  bool active = false;

  /// Stage-local X origin of the wave.
  double originX = 0.0;

  /// Stage-local Y origin of the wave.
  double originY = 0.0;

  /// Current expanding radius in logical pixels.
  double radius = 0.0;

  /// Maximum radius in logical pixels before deactivation.
  double maxRadius = 360.0;

  /// Radial expansion speed in logical pixels per second (default 520 px/s).
  double speed = 520.0;

  /// Current faded energy intensity in `[0.0, 1.0]`.
  double intensity = 0.0;

  /// Initial intensity recorded at spawn.
  double initialIntensity = 0.0;

  /// Elapsed lifetime in seconds.
  double age = 0.0;

  /// Base stroke width at spawn time.
  double strokeWidth = 3.0;

  /// Semantic wave type.
  AetherRippleKind kind = AetherRippleKind.tap;

  /// Monotonic generation ID used by cards to apply one impulse per pass.
  int generation = 0;

  /// Normalized expansion progress in `[0.0, 1.0]`.
  double get progress =>
      maxRadius > 0.0 ? (radius / maxRadius).clamp(0.0, 1.0) : 1.0;

  /// Activates and resets this slot in-place with zero heap allocations.
  void activate({
    required double originX,
    required double originY,
    required double maxRadius,
    required double speed,
    required double intensity,
    required double strokeWidth,
    required AetherRippleKind kind,
    required int generation,
  }) {
    active = true;
    this.originX = originX;
    this.originY = originY;
    radius = 6.0;
    this.maxRadius = maxRadius;
    this.speed = speed;
    this.intensity = intensity;
    initialIntensity = intensity;
    age = 0.0;
    this.strokeWidth = strokeWidth;
    this.kind = kind;
    this.generation = generation;
  }

  /// Marks this slot inactive for pool reuse.
  void deactivate() {
    active = false;
    intensity = 0.0;
  }
}

/// Fixed 6-slot pre-allocated ripple wave pool preventing per-frame allocation.
final class RippleWavePool {
  /// Creates a pool pre-allocated with [capacity] reusable slots (default 6).
  RippleWavePool({this.capacity = 6})
      : assert(capacity > 0 && capacity <= 16),
        _slots = List<AetherRipple>.generate(
          capacity,
          (_) => AetherRipple(),
          growable: false,
        ) {
    _view = UnmodifiableListView<AetherRipple>(_slots);
  }

  /// Fixed pool capacity (default 6 simultaneous active ripples).
  final int capacity;

  final List<AetherRipple> _slots;
  late final UnmodifiableListView<AetherRipple> _view;
  int _generation = 0;

  /// Read-only view of pre-allocated wave slots.
  UnmodifiableListView<AetherRipple> get slots => _view;

  /// Latest monotonic generation assigned to a spawned wave.
  int get generation => _generation;

  /// Number of currently expanding waves.
  int get activeCount {
    var count = 0;
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i].active) {
        count++;
      }
    }
    return count;
  }

  /// Spawns a wave in an inactive slot or recycles the weakest active slot.
  AetherRipple? spawn({
    required double originX,
    required double originY,
    required double maxRadius,
    double speed = 520.0,
    double intensity = 1.0,
    double strokeWidth = 3.0,
    AetherRippleKind kind = AetherRippleKind.tap,
  }) {
    var chosen = _slots[0];
    var foundIdle = false;
    var weakestIntensity = double.infinity;

    for (var i = 0; i < _slots.length; i++) {
      final candidate = _slots[i];
      if (!candidate.active) {
        chosen = candidate;
        foundIdle = true;
        break;
      }
      if (candidate.intensity < weakestIntensity) {
        weakestIntensity = candidate.intensity;
        chosen = candidate;
      }
    }

    if (!foundIdle && chosen.intensity > intensity * 1.45) {
      return null;
    }

    _generation++;
    chosen.activate(
      originX: originX,
      originY: originY,
      maxRadius: maxRadius,
      speed: speed,
      intensity: intensity.clamp(0.0, 1.0),
      strokeWidth: strokeWidth,
      kind: kind,
      generation: _generation,
    );
    return chosen;
  }

  /// Steps all active waves forward by [dt] seconds and returns `true` while
  /// any wave remains active.
  bool step(double dt) {
    var anyActive = false;
    for (var i = 0; i < _slots.length; i++) {
      final ripple = _slots[i];
      if (!ripple.active) {
        continue;
      }
      ripple.age += dt;
      ripple.radius += ripple.speed * dt;
      final progress = ripple.progress;
      ripple.intensity =
          ripple.initialIntensity * (1.0 - progress) * (1.0 - progress * 0.25);

      if (ripple.radius >= ripple.maxRadius || ripple.intensity <= 0.006) {
        ripple.deactivate();
      } else {
        anyActive = true;
      }
    }
    return anyActive;
  }

  /// Deactivates all wave slots immediately.
  void clear() {
    for (var i = 0; i < _slots.length; i++) {
      _slots[i].deactivate();
    }
  }
}
