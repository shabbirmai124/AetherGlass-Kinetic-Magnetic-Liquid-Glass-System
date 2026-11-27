import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../input/haptic_pulse_guard.dart';
import '../theme/aether_presets.dart';
import '../theme/aether_theme_data.dart';
import 'ambient_mote_pool.dart';
import 'ripple_wave_pool.dart';
import 'spring_solver.dart';
import 'wake_trail_buffer.dart';

/// Per-card or per-button spatial spring deformation state.
final class AetherCardForceState {
  /// Creates a force state slot for a glass surface identified by [id].
  AetherCardForceState({
    required this.id,
    required this.bounds,
    required int rippleCapacity,
  }) : reactedRippleGenerations = Int32List(rippleCapacity);

  /// Unique token identifying the registered card or button state.
  final Object id;

  /// Current bounding rectangle in stage-local coordinates.
  Rect bounds;

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

/// Centralized single-Ticker physics controller driving AetherGlass.
///
/// Manages pre-allocated pools ([RippleWavePool], [AmbientMotePool],
/// [WakeTrailBuffer]), delta-time clamping (`<= 0.033s`), automatic idle
/// sleep, and registered card 3D wave reactions.
class AetherFieldController extends ChangeNotifier {
  /// Creates an [AetherFieldController] with zero per-frame allocations.
  AetherFieldController({
    AetherThemeData? theme,
    int maxRipples = 6,
    int particleCount = 50,
    int maxTrailPoints = 14,
    this.autoSleep = true,
    this.animateParticlesWhenIdle = false,
    this._reducedMotion = false,
    HapticPulseGuard? hapticGuard,
  })  : _theme = theme ?? AetherPresets.bioluminescent,
        _ripplePool = RippleWavePool(capacity: maxRipples),
        _motePool = AmbientMotePool(capacity: particleCount),
        _trailBuffer = WakeTrailBuffer(capacity: maxTrailPoints),
        _hapticGuard = hapticGuard ?? HapticPulseGuard();

  /// Maximum safe delta time (33 ms) preventing physics divergence after pauses.
  static const double maxDeltaSeconds = SpringSolver.maxFrameDeltaSeconds;

  /// Maximum 3D tilt angle in radians (7.0 degrees).
  static const double maxTiltRadiansCap = 7.0 * math.pi / 180.0;

  /// Automatically stops the frame Ticker once velocities settle below 0.01
  /// and no ripples or touches remain active.
  final bool autoSleep;

  /// Keeps ambient motes drifting continuously even without touch input.
  final bool animateParticlesWhenIdle;

  final RippleWavePool _ripplePool;
  final AmbientMotePool _motePool;
  final WakeTrailBuffer _trailBuffer;
  final HapticPulseGuard _hapticGuard;
  final List<AetherCardForceState> _cards = <AetherCardForceState>[];

  AetherThemeData _theme;
  bool _reducedMotion;
  Size _viewportSize = const Size(400, 800);

  // Raw pointer & suction state.
  bool _hasPointer = false;
  bool _isPointerDown = false;
  double _pointerX = 0.0;
  double _pointerY = 0.0;
  double _pointerDownX = 0.0;
  double _pointerDownY = 0.0;
  double _pointerTravelDistance = 0.0;
  double _pointerHoldSeconds = 0.0;
  double _pointerVx = 0.0;
  double _pointerVy = 0.0;
  double _lastRecordedTrailX = 0.0;
  double _lastRecordedTrailY = 0.0;
  bool _hasRecordedTrailOrigin = false;

  // Smoothed trailing pointer magnet springs.
  final AetherSpringState _trailingX = AetherSpringState();
  final AetherSpringState _trailingY = AetherSpringState();

  // Screenshot-mode touch indicator ring.
  bool _showTouchIndicator = false;
  Offset? _pinnedTouchIndicator;

  // Ticker lifecycle metrics.
  Duration? _lastTickElapsed;
  bool _isSleeping = true;
  int _stepCount = 0;
  int _sleepCount = 0;
  int _wakeCount = 0;

  /// Callback invoked when the controller wakes from zero-CPU idle sleep.
  VoidCallback? onWakeRequested;

  /// Callback invoked when all springs settle and the Ticker can pause.
  VoidCallback? onSleepRequested;

  /// Active physics & visual theme configuration.
  AetherThemeData get theme => _theme;

  /// Applies a new [AetherThemeData] and wakes briefly to update visuals.
  set theme(AetherThemeData value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    _hapticGuard.cooldown = value.hapticCooldown;
    wake();
    notifyListeners();
  }

  /// Whether OS reduced-motion dampening is enabled.
  bool get reducedMotion => _reducedMotion;

  /// Updates reduced-motion mode and wakes briefly to settle active transforms.
  set reducedMotion(bool value) {
    if (_reducedMotion == value) {
      return;
    }
    _reducedMotion = value;
    wake();
    notifyListeners();
  }

  /// Whether screenshot-mode translucent touch ring is shown.
  bool get showTouchIndicator => _showTouchIndicator;

  /// Toggles screenshot-mode translucent touch ring visibility.
  set showTouchIndicator(bool value) {
    if (_showTouchIndicator == value) {
      return;
    }
    _showTouchIndicator = value;
    notifyListeners();
  }

  /// Optional pinned touch marker coordinate for deterministic documentation.
  Offset? get pinnedTouchIndicator => _pinnedTouchIndicator;

  /// Pins or clears a touch marker coordinate for deterministic captures.
  set pinnedTouchIndicator(Offset? value) {
    if (_pinnedTouchIndicator == value) {
      return;
    }
    _pinnedTouchIndicator = value;
    notifyListeners();
  }

  /// Current stage viewport size in logical pixels.
  Size get viewportSize => _viewportSize;

  /// Pre-allocated 6-slot ripple wave pool.
  RippleWavePool get ripplePool => _ripplePool;

  /// Pre-allocated 50-slot ambient mote pool.
  AmbientMotePool get motePool => _motePool;

  /// Pre-allocated 14-point fluid wake ribbon buffer.
  WakeTrailBuffer get trailBuffer => _trailBuffer;

  /// Cooldown-guarded haptic pulse coordinator.
  HapticPulseGuard get hapticGuard => _hapticGuard;

  /// True while a touch or mouse button is pressed on stage.
  bool get isPointerDown => _isPointerDown;

  /// True while a pointer is hovering or pressed within the stage.
  bool get hasPointer => _hasPointer;

  /// Active pointer position, or `null` when no pointer is active on stage.
  Offset? get activePointer =>
      _hasPointer ? Offset(_pointerX, _pointerY) : null;

  /// Raw pointer coordinates in stage space.
  Offset get pointerPosition => Offset(_pointerX, _pointerY);

  /// Spring-interpolated trailing pointer magnet coordinates.
  Offset get trailingPointer => Offset(_trailingX.value, _trailingY.value);

  /// Alias for [trailingPointer].
  Offset get smoothedPointer => trailingPointer;

  /// Current pointer velocity vector in logical pixels per second.
  Offset get pointerVelocity => Offset(_pointerVx, _pointerVy);

  /// Whether ambient motes keep drifting gently when otherwise idle.
  bool get idleAmbientDrift => animateParticlesWhenIdle;

  /// Current pointer speed magnitude in logical pixels per second.
  double get pointerSpeed =>
      math.sqrt(_pointerVx * _pointerVx + _pointerVy * _pointerVy);

  /// Elapsed duration of the current press-and-hold in seconds.
  double get pointerHoldSeconds => _pointerHoldSeconds;

  /// True while the central Ticker is paused in idle sleep.
  bool get isSleeping => _isSleeping;

  /// Total simulation steps executed.
  int get stepCount => _stepCount;

  /// Total transitions into idle sleep.
  int get sleepCount => _sleepCount;

  /// Total wakes from idle sleep.
  int get wakeCount => _wakeCount;

  /// Current expanding ripple count.
  int get activeRippleCount => _ripplePool.activeCount;

  /// Pre-allocated ripple pool capacity (default 6).
  int get maxRipples => _ripplePool.capacity;

  /// Pre-allocated ambient mote pool capacity (default 50).
  int get particleCount => _motePool.capacity;

  /// Pre-allocated wake trail point capacity (default 14).
  int get maxTrailPoints => _trailBuffer.capacity;

  /// Currently registered glass cards and magnetic buttons.
  int get registeredCardCount => _cards.length;

  /// Read-only view of pre-allocated ripple slots.
  UnmodifiableListView<AetherRipple> get ripples => _ripplePool.slots;

  /// Read-only view of pre-allocated ambient mote slots.
  UnmodifiableListView<AetherMote> get particles => _motePool.motes;

  /// Read-only view of the pre-allocated wake trail ring buffer.
  UnmodifiableListView<AetherTrailPoint> get trailPoints => _trailBuffer.points;

  /// Index of the newest sample inside [trailPoints].
  int get trailHead => _trailBuffer.head;

  /// Updates viewport dimensions and seeds ambient motes cleanly.
  void setViewportSize(Size size) {
    if (size.width <= 0.0 || size.height <= 0.0) {
      return;
    }
    final changed = (_viewportSize.width - size.width).abs() > 0.5 ||
        (_viewportSize.height - size.height).abs() > 0.5;
    if (!changed) {
      return;
    }
    _viewportSize = size;
    _motePool.resize(size);
    if (!_hasPointer) {
      _pointerX = size.width * 0.5;
      _pointerY = size.height * 0.5;
      _trailingX.reset(_pointerX);
      _trailingY.reset(_pointerY);
    }
  }

  /// Registers a glass surface with its stage-local [bounds].
  AetherCardForceState registerCard(
    Object id,
    Rect bounds, {
    double maxMagneticOffset = 0.0,
  }) {
    for (var i = 0; i < _cards.length; i++) {
      if (identical(_cards[i].id, id) || _cards[i].id == id) {
        _cards[i].bounds = bounds;
        _cards[i].maxMagneticOffset = maxMagneticOffset;
        return _cards[i];
      }
    }
    final state = AetherCardForceState(
      id: id,
      bounds: bounds,
      rippleCapacity: _ripplePool.capacity,
    )..maxMagneticOffset = maxMagneticOffset;
    _cards.add(state);
    return state;
  }

  /// Updates a registered card's bounds after layout or scroll changes.
  void updateCardBounds(Object id, Rect bounds) {
    for (var i = 0; i < _cards.length; i++) {
      if (identical(_cards[i].id, id) || _cards[i].id == id) {
        _cards[i].bounds = bounds;
        return;
      }
    }
  }

  /// Unregisters a glass surface on widget disposal.
  void unregisterCard(Object id) {
    _cards.removeWhere(
      (AetherCardForceState card) => identical(card.id, id) || card.id == id,
    );
  }

  /// Looks up a registered surface's force state by [id].
  AetherCardForceState? cardStateFor(Object id) {
    for (var i = 0; i < _cards.length; i++) {
      if (identical(_cards[i].id, id) || _cards[i].id == id) {
        return _cards[i];
      }
    }
    return null;
  }

  /// Spawns an expanding ripple wave from the pre-allocated pool.
  void emitRipple({
    required Offset origin,
    double maxRadius = 380.0,
    double? speed,
    double intensity = 1.0,
    double strokeWidth = 3.0,
    AetherRippleKind kind = AetherRippleKind.tap,
  }) {
    final effectiveSpeed = speed ?? _theme.waveSpeed;
    final scaledIntensity =
        _reducedMotion ? (intensity * 0.20).clamp(0.0, 0.25) : intensity;
    if (scaledIntensity <= 0.01) {
      return;
    }
    final spawned = _ripplePool.spawn(
      originX: origin.dx,
      originY: origin.dy,
      maxRadius: maxRadius,
      speed: effectiveSpeed,
      intensity: scaledIntensity,
      strokeWidth: strokeWidth,
      kind: kind,
    );
    if (spawned != null) {
      wake();
    }
  }

  /// Passive raw pointer-down handler.
  void handlePointerDown(Offset position) {
    final hadPointer = _hasPointer;
    _hasPointer = true;
    _isPointerDown = true;
    _pointerX = position.dx;
    _pointerY = position.dy;
    _pointerDownX = position.dx;
    _pointerDownY = position.dy;
    _pointerTravelDistance = 0.0;
    _pointerHoldSeconds = 0.0;
    _pointerVx = 0.0;
    _pointerVy = 0.0;
    _lastRecordedTrailX = position.dx;
    _lastRecordedTrailY = position.dy;
    _hasRecordedTrailOrigin = true;

    if (!hadPointer) {
      _trailingX.reset(position.dx);
      _trailingY.reset(position.dy);
    }

    for (var i = 0; i < _cards.length; i++) {
      _cards[i].hapticPeakFired = false;
    }

    emitRipple(
      origin: position,
      maxRadius: 210.0,
      speed: _theme.waveSpeed * 0.92,
      intensity: 0.55,
      strokeWidth: 2.2,
      kind: AetherRippleKind.suction,
    );
    wake();
  }

  /// Passive raw pointer-move handler capturing velocity and wake trail.
  void handlePointerMove(
    Offset position,
    Offset delta, {
    Offset? trackedVelocity,
  }) {
    _hasPointer = true;
    _pointerX = position.dx;
    _pointerY = position.dy;
    _pointerTravelDistance += delta.distance;

    if (trackedVelocity != null) {
      _pointerVx = trackedVelocity.dx.clamp(-2600.0, 2600.0);
      _pointerVy = trackedVelocity.dy.clamp(-2600.0, 2600.0);
    } else {
      final instVx = (delta.dx * 60.0).clamp(-2600.0, 2600.0);
      final instVy = (delta.dy * 60.0).clamp(-2600.0, 2600.0);
      _pointerVx = _pointerVx * 0.45 + instVx * 0.55;
      _pointerVy = _pointerVy * 0.45 + instVy * 0.55;
    }

    final distFromLastTrail = _hasRecordedTrailOrigin
        ? _hypot(
            position.dx - _lastRecordedTrailX,
            position.dy - _lastRecordedTrailY,
          )
        : 999.0;
    if (!_reducedMotion && distFromLastTrail >= 5.5) {
      _trailBuffer.push(position.dx, position.dy, speed: pointerSpeed);
      _lastRecordedTrailX = position.dx;
      _lastRecordedTrailY = position.dy;
      _hasRecordedTrailOrigin = true;
    }

    if (!_reducedMotion && delta.distanceSquared > 0.25) {
      _motePool.applyPointerWake(
        px: position.dx,
        py: position.dy,
        dx: delta.dx,
        dy: delta.dy,
      );
    }

    wake();
  }

  /// Passive hover handler for desktop/web magnetic attraction and specular light.
  void handlePointerHover(Offset position) {
    final hadPointer = _hasPointer;
    _hasPointer = true;
    _pointerX = position.dx;
    _pointerY = position.dy;
    if (!hadPointer) {
      _trailingX.reset(position.dx);
      _trailingY.reset(position.dy);
    }
    wake();
  }

  /// Passive pointer-up handler distinguishing taps, suction holds, and swipes.
  void handlePointerUp(Offset position, {Offset? releaseVelocity}) {
    _pointerX = position.dx;
    _pointerY = position.dy;
    if (releaseVelocity != null) {
      _pointerVx = releaseVelocity.dx.clamp(-2600.0, 2600.0);
      _pointerVy = releaseVelocity.dy.clamp(-2600.0, 2600.0);
    }

    final speed = pointerSpeed;
    final netDisp = _hypot(
      position.dx - _pointerDownX,
      position.dy - _pointerDownY,
    );
    final wasQuickTap = _pointerHoldSeconds < 0.24 &&
        _pointerTravelDistance < 18.0 &&
        netDisp < 14.0;
    final wasFastSwipe = speed > 420.0 || _pointerTravelDistance > 42.0;

    if (wasQuickTap) {
      emitRipple(
        origin: position,
        maxRadius: math.max(_viewportSize.longestSide * 0.55, 320.0),
        speed: _theme.waveSpeed * 1.15,
        intensity: 0.95,
        strokeWidth: 3.2,
        kind: AetherRippleKind.tap,
      );
      _applyDirectTapDepression(position);
    } else if (wasFastSwipe) {
      final energy = (speed / 1500.0).clamp(0.58, 1.0);
      emitRipple(
        origin: position,
        maxRadius: math.max(_viewportSize.longestSide * 0.68, 390.0),
        speed: _theme.waveSpeed + energy * 180.0,
        intensity: energy,
        strokeWidth: 3.8,
        kind: AetherRippleKind.release,
      );
      if (energy >= 0.72) {
        _hapticGuard.triggerImpact(
          enabled: _theme.enableHaptics && !_reducedMotion,
        );
      }
    } else {
      emitRipple(
        origin: position,
        maxRadius: 270.0,
        speed: _theme.waveSpeed * 0.88,
        intensity: 0.68,
        strokeWidth: 2.6,
        kind: AetherRippleKind.release,
      );
    }

    _isPointerDown = false;
    _pointerHoldSeconds = 0.0;
    _pointerVx = 0.0;
    _pointerVy = 0.0;
    _hasRecordedTrailOrigin = false;
    wake();
  }

  /// Resets pointer pressure cleanly on cancel or cursor exit.
  void handlePointerCancel() {
    _isPointerDown = false;
    _hasPointer = false;
    _pointerHoldSeconds = 0.0;
    _pointerVx = 0.0;
    _pointerVy = 0.0;
    _hasRecordedTrailOrigin = false;
    wake();
  }

  /// Wakes the central Ticker immediately if currently sleeping.
  void wake() {
    if (_isSleeping) {
      _isSleeping = false;
      _lastTickElapsed = null;
      _wakeCount++;
      onWakeRequested?.call();
    }
  }

  /// Advances the full physics simulation by one Ticker frame with clamped
  /// `dt <= 0.033s`.
  void step(Duration elapsed) {
    final dt = _computeClampedDt(elapsed);
    stepSimulation(dt);
  }

  /// Deterministic physics simulation step advancing by [dt] seconds
  /// (clamped to `0.0001 <= dt <= 0.033` seconds).
  void stepSimulation(double rawDt) {
    final dt = rawDt <= 0.0
        ? 0.0001
        : (rawDt > maxDeltaSeconds ? maxDeltaSeconds : rawDt);
    _stepCount++;

    if (_isPointerDown) {
      _pointerHoldSeconds += dt;
    }

    // 1. Update trailing pointer magnet.
    var pointerSettled = true;
    if (_hasPointer) {
      pointerSettled &= SpringSolver.step(
        state: _trailingX,
        target: _pointerX,
        stiffness: _theme.pointerStiffness,
        damping: _theme.pointerDamping,
        dt: dt,
        positionEpsilon: 0.25,
        velocityEpsilon: 0.01,
      );
      pointerSettled &= SpringSolver.step(
        state: _trailingY,
        target: _pointerY,
        stiffness: _theme.pointerStiffness,
        damping: _theme.pointerDamping,
        dt: dt,
        positionEpsilon: 0.25,
        velocityEpsilon: 0.01,
      );
    }

    final velocityDecay = math.exp(-10.0 * dt);
    _pointerVx *= velocityDecay;
    _pointerVy *= velocityDecay;

    // 2. Step pre-allocated ripples and wake trail.
    final anyRippleActive = _ripplePool.step(dt);
    final anyTrailActive = _trailBuffer.step(dt);

    // 3. Step pre-allocated 50-mote ambient pool.
    final applyDrift =
        animateParticlesWhenIdle || _isPointerDown || anyRippleActive;
    final anyMoteMoving = _motePool.step(
      dt: dt,
      viewportSize: _viewportSize,
      ripples: _ripplePool.slots,
      reducedMotion: _reducedMotion,
      applyAmbientDrift: applyDrift,
    );

    // 4. Step registered glass cards & magnetic buttons.
    final allCardsSettled = _stepCards(dt);

    // 5. Auto-sleep when idle to drop CPU consumption to zero.
    if (autoSleep &&
        !_isPointerDown &&
        !animateParticlesWhenIdle &&
        !anyRippleActive &&
        !anyTrailActive &&
        !anyMoteMoving &&
        pointerSettled &&
        allCardsSettled) {
      _isSleeping = true;
      _sleepCount++;
      onSleepRequested?.call();
    }

    notifyListeners();
  }

  double _computeClampedDt(Duration elapsed) {
    final prev = _lastTickElapsed;
    _lastTickElapsed = elapsed;
    if (prev == null) {
      return 1.0 / 60.0;
    }
    final rawSeconds = (elapsed - prev).inMicroseconds / 1000000.0;
    if (rawSeconds <= 0.0) {
      return 1.0 / 120.0;
    }
    return rawSeconds > maxDeltaSeconds ? maxDeltaSeconds : rawSeconds;
  }

  void _applyDirectTapDepression(Offset position) {
    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      if (!card.bounds.contains(position)) {
        continue;
      }
      card.depression.velocity += _reducedMotion ? 0.0 : 5.2;
      final center = card.bounds.center;
      final halfW = math.max(card.bounds.width * 0.5, 1.0);
      final halfH = math.max(card.bounds.height * 0.5, 1.0);
      final nx = ((position.dx - center.dx) / halfW).clamp(-1.0, 1.0);
      final ny = ((position.dy - center.dy) / halfH).clamp(-1.0, 1.0);
      if (!_reducedMotion) {
        card.tiltY.velocity += nx * 0.62;
        card.tiltX.velocity -= ny * 0.62;
      }
    }
  }

  bool _stepCards(double dt) {
    var allSettled = true;
    final motionScale = _reducedMotion ? 0.0 : 1.0;
    final stiffness = _theme.stiffness;
    final damping = _theme.damping;
    final maxTilt =
        math.min(_theme.maxTiltRadians, maxTiltRadiansCap) * motionScale;
    final activationRadius = math.max(_theme.activationRadius, 1.0);
    final halfBand = math.max(_theme.wavefrontBand * 0.5, 8.0);
    final suctionBoost =
        _isPointerDown ? (_pointerHoldSeconds / 0.45).clamp(0.0, 1.0) : 0.0;
    final ripples = _ripplePool.slots;

    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      final rect = card.bounds;
      if (rect.width <= 0.0 || rect.height <= 0.0) {
        continue;
      }

      final center = rect.center;

      // Wavefront crossing: inject directional 3D tilt impulse once per pass.
      if (!_reducedMotion) {
        for (var r = 0; r < ripples.length; r++) {
          final ripple = ripples[r];
          if (!ripple.active) {
            continue;
          }
          if (card.reactedRippleGenerations[r] == ripple.generation) {
            continue;
          }
          final dx = center.dx - ripple.originX;
          final dy = center.dy - ripple.originY;
          final dist = _hypot(dx, dy);
          if ((ripple.radius - dist).abs() <= halfBand ||
              ripple.radius >= dist - halfBand) {
            card.reactedRippleGenerations[r] = ripple.generation;
            final distAtten =
                (1.0 - (dist / math.max(ripple.maxRadius, 1.0)) * 0.62)
                    .clamp(0.22, 1.0);
            final strength = ripple.intensity * distAtten * 0.94;
            if (dist > 6.0) {
              final invDist = 1.0 / dist;
              card.tiltX.velocity += (dy * invDist) * strength;
              card.tiltY.velocity -= (dx * invDist) * strength;
            }
            card.depression.velocity += strength * 0.45;
            card.hoverGlow.velocity += strength * 1.35;
          }
        }
      }

      var targetEdgeX = 0.0;
      var targetEdgeY = 0.0;
      var targetTiltX = 0.0;
      var targetTiltY = 0.0;
      var targetDepression = 0.0;
      var targetGlow = 0.0;
      var targetSuction = 0.0;
      var targetOffsetX = 0.0;
      var targetOffsetY = 0.0;

      if (_hasPointer) {
        final px = _trailingX.value;
        final py = _trailingY.value;
        final closestX = px.clamp(rect.left, rect.right);
        final closestY = py.clamp(rect.top, rect.bottom);
        final distToBox = _hypot(px - closestX, py - closestY);
        final prox = (1.0 - distToBox / activationRadius).clamp(0.0, 1.0);

        if (prox > 0.001) {
          final smoothProx = prox * prox * (3.0 - 2.0 * prox);
          final halfW = math.max(rect.width * 0.5, 1.0);
          final halfH = math.max(rect.height * 0.5, 1.0);
          final nx = ((px - center.dx) / (halfW + 24.0)).clamp(-1.25, 1.25);
          final ny = ((py - center.dy) / (halfH + 24.0)).clamp(-1.25, 1.25);

          card.specularAlignX = nx.clamp(-1.0, 1.0);
          card.specularAlignY = ny.clamp(-1.0, 1.0);

          final inside = rect.contains(Offset(_pointerX, _pointerY));
          final pressScale = (_isPointerDown && inside) ? 1.0 : 0.64;
          final holdMultiplier = 1.0 + suctionBoost * 0.45;

          targetEdgeX =
              nx * smoothProx * pressScale * holdMultiplier * motionScale;
          targetEdgeY =
              ny * smoothProx * pressScale * holdMultiplier * motionScale;
          targetGlow = smoothProx * (_isPointerDown ? 1.0 : 0.72);
          targetSuction = (_isPointerDown && inside) ? suctionBoost : 0.0;

          if (_isPointerDown && inside && !_reducedMotion) {
            targetDepression = 0.48 + suctionBoost * 0.35;
          }

          if (card.maxMagneticOffset > 0.0 && !_reducedMotion) {
            final offFactor = (_isPointerDown && inside) ? 1.0 : 0.48;
            final magLen = _hypot(nx, ny);
            if (magLen > 0.001) {
              final clampedScale = math.min(magLen, 1.0) / magLen;
              targetOffsetX = nx *
                  clampedScale *
                  card.maxMagneticOffset *
                  smoothProx *
                  offFactor;
              targetOffsetY = ny *
                  clampedScale *
                  card.maxMagneticOffset *
                  smoothProx *
                  offFactor;
            }
          }

          targetTiltY = (nx * 0.68 + (_pointerVx / 1600.0) * 0.35)
                  .clamp(-1.0, 1.0) *
              maxTilt *
              smoothProx;
          targetTiltX = (-ny * 0.68 - (_pointerVy / 1600.0) * 0.35)
                  .clamp(-1.0, 1.0) *
              maxTilt *
              smoothProx;
        }
      }

      var cardSettled = true;
      cardSettled &= SpringSolver.step(
        state: card.tiltX,
        target: targetTiltX,
        stiffness: stiffness,
        damping: damping,
        dt: dt,
        positionEpsilon: 0.0005,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.tiltY,
        target: targetTiltY,
        stiffness: stiffness,
        damping: damping,
        dt: dt,
        positionEpsilon: 0.0005,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.depression,
        target: targetDepression,
        stiffness: stiffness * 1.15,
        damping: damping * 1.05,
        dt: dt,
        positionEpsilon: 0.001,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.edgePullX,
        target: targetEdgeX,
        stiffness: stiffness,
        damping: damping,
        dt: dt,
        positionEpsilon: 0.001,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.edgePullY,
        target: targetEdgeY,
        stiffness: stiffness,
        damping: damping,
        dt: dt,
        positionEpsilon: 0.001,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.hoverGlow,
        target: targetGlow,
        stiffness: stiffness * 0.9,
        damping: damping * 1.1,
        dt: dt,
        positionEpsilon: 0.002,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.suction,
        target: targetSuction,
        stiffness: stiffness * 0.75,
        damping: damping,
        dt: dt,
        positionEpsilon: 0.002,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.offsetX,
        target: targetOffsetX,
        stiffness: stiffness * 1.25,
        damping: damping * 0.95,
        dt: dt,
        positionEpsilon: 0.01,
        velocityEpsilon: 0.01,
      );
      cardSettled &= SpringSolver.step(
        state: card.offsetY,
        target: targetOffsetY,
        stiffness: stiffness * 1.25,
        damping: damping * 0.95,
        dt: dt,
        positionEpsilon: 0.01,
        velocityEpsilon: 0.01,
      );

      final stretchMag = _hypot(card.edgePullX.value, card.edgePullY.value);
      if (!card.hapticPeakFired && _isPointerDown && stretchMag >= 0.76) {
        card.hapticPeakFired = true;
        _hapticGuard.triggerSelection(
          enabled: _theme.enableHaptics && !_reducedMotion,
        );
      } else if (stretchMag < 0.35) {
        card.hapticPeakFired = false;
      }

      if (!cardSettled) {
        allSettled = false;
      }
    }

    return allSettled;
  }

  static double _hypot(double dx, double dy) => math.sqrt(dx * dx + dy * dy);
}
