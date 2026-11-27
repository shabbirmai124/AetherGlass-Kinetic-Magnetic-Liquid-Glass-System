import 'dart:collection';

/// Pre-allocated trailing pointer sample stored inside [WakeTrailBuffer].
final class AetherTrailPoint {
  /// Creates an inactive trail sample slot.
  AetherTrailPoint();

  /// Whether this point is still within its 280 ms fade window.
  bool active = false;

  /// Stage-local X coordinate.
  double x = 0.0;

  /// Stage-local Y coordinate.
  double y = 0.0;

  /// Elapsed age in seconds since capture.
  double age = 0.0;

  /// Maximum fade lifetime in seconds (default 280 ms).
  double maxAge = 0.28;

  /// Instantaneous pointer speed when sampled.
  double speed = 0.0;

  /// Normalized remaining opacity life in `[0.0, 1.0]`.
  double get life =>
      maxAge > 0.0 ? (1.0 - (age / maxAge)).clamp(0.0, 1.0) : 0.0;
}

/// Fixed 14-point zero-allocation ring buffer storing drag ribbon coordinates
/// that fade smoothly over `280 ms`.
final class WakeTrailBuffer {
  /// Creates a fixed ring buffer with [capacity] slots (default 14).
  WakeTrailBuffer({
    this.capacity = 14,
    this.fadeSeconds = 0.28,
  })  : assert(capacity >= 2 && capacity <= 32),
        _points = List<AetherTrailPoint>.generate(
          capacity,
          (_) => AetherTrailPoint(),
          growable: false,
        ) {
    _view = UnmodifiableListView<AetherTrailPoint>(_points);
  }

  /// Fixed point capacity (default 14 points).
  final int capacity;

  /// Fade duration in seconds (default 0.28 s / 280 ms).
  final double fadeSeconds;

  final List<AetherTrailPoint> _points;
  late final UnmodifiableListView<AetherTrailPoint> _view;
  int _head = 0;

  /// Unmodifiable zero-alloc view of buffer slots.
  UnmodifiableListView<AetherTrailPoint> get points => _view;

  /// Index of the most recently written slot.
  int get head => _head;

  /// Records a pointer coordinate in-place into the next ring slot.
  void push(double x, double y, {double speed = 0.0}) {
    _head = (_head + 1) % _points.length;
    final slot = _points[_head];
    slot.active = true;
    slot.x = x;
    slot.y = y;
    slot.age = 0.0;
    slot.maxAge = fadeSeconds;
    slot.speed = speed;
  }

  /// Advances sample ages by [dt] seconds and returns `true` while any point
  /// remains visible.
  bool step(double dt) {
    var anyActive = false;
    for (var i = 0; i < _points.length; i++) {
      final point = _points[i];
      if (!point.active) {
        continue;
      }
      point.age += dt;
      if (point.age >= point.maxAge) {
        point.active = false;
      } else {
        anyActive = true;
      }
    }
    return anyActive;
  }

  /// Deactivates all trail samples immediately.
  void clear() {
    for (var i = 0; i < _points.length; i++) {
      _points[i].active = false;
    }
  }
}
