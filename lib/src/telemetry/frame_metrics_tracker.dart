import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';

/// Immutable snapshot of live rendering, frame-budget, and pool telemetry.
@immutable
class AetherTelemetrySnapshot {
  /// Creates a telemetry snapshot.
  const AetherTelemetrySnapshot({
    required this.fps,
    required this.uiMillis,
    required this.rasterMillis,
    required this.p50Millis,
    required this.p90Millis,
    required this.sampleCount,
    required this.activeRipples,
    required this.maxRipples,
    required this.moteCount,
    required this.registeredCards,
    required this.isSleeping,
    required this.blurBatched,
  });

  /// Estimated display frames per second.
  final double fps;

  /// Latest UI thread build duration in milliseconds.
  final double uiMillis;

  /// Latest GPU thread rasterization duration in milliseconds.
  final double rasterMillis;

  /// Rolling 50th-percentile total frame time in milliseconds.
  final double p50Millis;

  /// Rolling 90th-percentile total frame time in milliseconds.
  final double p90Millis;

  /// Number of frame samples in the rolling window (max 120).
  final int sampleCount;

  /// Currently active ripple wave slots.
  final int activeRipples;

  /// Pre-allocated ripple pool capacity.
  final int maxRipples;

  /// Pre-allocated ambient mote pool capacity.
  final int moteCount;

  /// Number of currently registered glass cards/buttons.
  final int registeredCards;

  /// Whether the central physics Ticker is currently in idle sleep.
  final bool isSleeping;

  /// Whether Impeller [BackdropGroup] blur batching is active.
  final bool blurBatched;
}

/// Zero-allocation rolling frame-timing tracker observing
/// [SchedulerBinding.addTimingsCallback] and [AetherFieldController].
class FrameMetricsTracker extends ChangeNotifier {
  /// Creates a [FrameMetricsTracker] attached to [controller].
  FrameMetricsTracker({
    required this.controller,
    this._blurBatched = true,
  });

  static const int _windowCapacity = 120;

  /// Physics controller whose pool and sleep state are monitored.
  final AetherFieldController controller;

  final Float64List _totalMsRing = Float64List(_windowCapacity);
  final Float64List _sortScratch = Float64List(_windowCapacity);
  int _ringCursor = 0;
  int _ringCount = 0;

  double _latestUiMs = 0.0;
  double _latestRasterMs = 0.0;
  double _latestTotalMs = 0.0;
  double _p50Ms = 0.0;
  double _p90Ms = 0.0;
  double _fps = 60.0;

  int _lastWallMicros = 0;
  int _frameDeltaCount = 0;
  double _frameDeltaAccumMs = 0.0;
  Timer? _refreshTimer;
  bool _attached = false;
  bool _blurBatched;
  bool _lastSleeping = true;

  /// Whether Impeller blur batching is active for the observed stage.
  bool get blurBatched => _blurBatched;

  /// Updates the blur batching indicator flag.
  set blurBatched(bool value) {
    if (_blurBatched == value) {
      return;
    }
    _blurBatched = value;
    notifyListeners();
  }

  /// Current immutable telemetry snapshot.
  AetherTelemetrySnapshot get snapshot => AetherTelemetrySnapshot(
        fps: _fps,
        uiMillis: _latestUiMs,
        rasterMillis: _latestRasterMs,
        p50Millis: _p50Ms,
        p90Millis: _p90Ms,
        sampleCount: _ringCount,
        activeRipples: controller.activeRippleCount,
        maxRipples: controller.maxRipples,
        moteCount: controller.particleCount,
        registeredCards: controller.registeredCardCount,
        isSleeping: controller.isSleeping,
        blurBatched: _blurBatched,
      );

  /// Starts listening to engine frame timings and controller ticks.
  void start() {
    if (_attached) {
      return;
    }
    _attached = true;
    _lastSleeping = controller.isSleeping;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    controller.addListener(_onControllerTick);
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _recompute();
      notifyListeners();
    });
  }

  /// Detaches frame timing callbacks and stops timers.
  void stop() {
    if (!_attached) {
      return;
    }
    _attached = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    controller.removeListener(_onControllerTick);
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
  }

  /// Records a synthetic or measured [FrameTiming] sample directly (useful for
  /// tests and custom benchmark harnesses).
  void recordTiming(FrameTiming timing) {
    _latestUiMs = timing.buildDuration.inMicroseconds / 1000.0;
    _latestRasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
    _latestTotalMs = timing.totalSpan.inMicroseconds / 1000.0;
    _recordSample(_latestTotalMs);
    _recompute();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (var i = 0; i < timings.length; i++) {
      final t = timings[i];
      _latestUiMs = t.buildDuration.inMicroseconds / 1000.0;
      _latestRasterMs = t.rasterDuration.inMicroseconds / 1000.0;
      _latestTotalMs = t.totalSpan.inMicroseconds / 1000.0;
      _recordSample(_latestTotalMs);
    }
  }

  void _onControllerTick() {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    if (_lastWallMicros > 0) {
      final deltaMs = (nowMicros - _lastWallMicros) / 1000.0;
      if (deltaMs >= 2.0 && deltaMs <= 120.0) {
        _frameDeltaAccumMs += deltaMs;
        _frameDeltaCount++;
        if (_ringCount == 0) {
          _recordSample(deltaMs);
        }
      }
    }
    _lastWallMicros = nowMicros;
    if (_lastSleeping != controller.isSleeping) {
      _lastSleeping = controller.isSleeping;
      notifyListeners();
    }
  }

  void _recordSample(double totalMs) {
    _totalMsRing[_ringCursor] = totalMs;
    _ringCursor = (_ringCursor + 1) % _windowCapacity;
    if (_ringCount < _windowCapacity) {
      _ringCount++;
    }
  }

  void _recompute() {
    if (_frameDeltaCount > 0 && _frameDeltaAccumMs > 0.0) {
      final avgMs = _frameDeltaAccumMs / _frameDeltaCount;
      _fps = (1000.0 / math.max(avgMs, 1.0)).clamp(1.0, 240.0);
      _frameDeltaCount = 0;
      _frameDeltaAccumMs = 0.0;
    } else if (_latestTotalMs > 0.0) {
      _fps = (1000.0 / math.max(_latestTotalMs, 8.33)).clamp(1.0, 240.0);
    }

    if (_ringCount == 0) {
      return;
    }
    for (var i = 0; i < _ringCount; i++) {
      _sortScratch[i] = _totalMsRing[i];
    }
    for (var i = 1; i < _ringCount; i++) {
      final key = _sortScratch[i];
      var j = i - 1;
      while (j >= 0 && _sortScratch[j] > key) {
        _sortScratch[j + 1] = _sortScratch[j];
        j--;
      }
      _sortScratch[j + 1] = key;
    }
    _p50Ms = _sortScratch[((_ringCount - 1) * 0.50).round()];
    _p90Ms = _sortScratch[((_ringCount - 1) * 0.90).round()];
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
