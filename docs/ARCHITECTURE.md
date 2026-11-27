# AetherGlass Technical Architecture

**AetherGlass** is a zero-dependency pure-Dart rendering and spatial physics engine built exclusively on Flutter SDK primitives (`flutter/widgets.dart`, `flutter/scheduler.dart`, `flutter/services.dart`, `dart:ui`, `dart:math`). It replaces isolated, per-widget animation controllers and redundant screen-buffer blurs with a single synchronized frame clock and Impeller-friendly backdrop compositing.

---

## 1. Four-Layer Unidirectional Data Flow

```text
  [Raw Pointer Events] ──> AetherSurfaceListener (HitTestBehavior.translucent)
                                 │  + VelocityTracker + HapticPulseGuard (60ms)
                                 ▼
                      AetherFieldController (Single Ticker, dt <= 33ms, Auto-Sleep)
                       ├── SpringSolver (240Hz symplectic sub-stepping)
                       ├── RippleWavePool[6] (monotonic wavefront generation IDs)
                       ├── AmbientMotePool[50] (10 px/s drift, 0.94 drag)
                       └── WakeTrailBuffer[14] (280 ms fade ring buffer)
                                 │  notifyListeners()
               ┌─────────────────┴──────────────────┐
               ▼                                    ▼
      AetherFieldPainter                  AetherGlassCard / Button
   (RepaintBoundary isolated)         (RepaintBoundary + ListenableBuilder)
   • Reused Paint/MaskFilter/Path     • Matrix4 3D tilt (<= 7°)
   • Background, Motes, Ripples       • LiquidEdgeClipper (4 arcs + 4 Beziers)
   • 14px -> 0px Wake Ribbon          • SpecularRimPainter (1.2px pointer-tracked)
                                      • BackdropFilter.grouped in BackdropGroup
```

---

## 2. Layer Responsibilities & Invariants

### Layer 1: Input & Guarded Haptics (`lib/src/input/`)
- **`AetherSurfaceListener`**: Wraps the stage in `Listener(behavior: HitTestBehavior.translucent)`. Because it never competes in Flutter's gesture arena, nested `ListView` scrolling, sliders, text selection, and buttons continue working with zero latency or dropped taps.
- **`HapticPulseGuard`**: Enforces a 60 ms minimum cooldown between `HapticFeedback.selectionClick()` / `HapticFeedback.lightImpact()` dispatches so fast pointer drags feel tactile rather than noisy.

### Layer 2: Single-Ticker Physics & Pre-Allocated Pools (`lib/src/physics/`)
- **`SpringSolver`**: Uses semi-implicit (symplectic) Euler sub-stepping capped at `maxSubStep = 1/240s` and clamps incoming frame intervals to `<= 0.033s` (33 ms). Springs settle cleanly to exact targets and zero velocity when `|velocity| < 0.01` and `|displacement| < epsilon`.
- **Zero-Allocation Pools**:
  - `RippleWavePool` (`6` fixed `AetherRipple` slots; recycles weakest slot when saturated)
  - `AmbientMotePool` (`50` fixed `AetherMote` slots anchored to normalized coordinates)
  - `WakeTrailBuffer` (`14` fixed `AetherTrailPoint` ring slots fading over `280 ms`)
- **Auto-Sleep**: When no pointer is down, active ripples drop to zero, trail samples fade out, and all card/mote springs settle, `AetherFieldController` halts its `Ticker` (`onSleepRequested`) until the next pointer interaction.

### Layer 3: Canvas & Impeller Rendering (`lib/src/renderer/`)
- **`AetherFieldPainter`**: Pre-allocates every `Paint`, `MaskFilter.blur`, and `Path` once. `paint()` mutates colors/widths and calls `_ribbonPath.reset()` in-place.
- **`LiquidEdgeClipper`**: Connects four corner circular arcs (`arcToPoint`) with four quadratic Bezier sides whose midpoints deflect up to `edgeFlexDistance` (`8.0 px` default) inside the `140.0 px` activation radius.
- **`SpecularRimPainter`**: Reuses a single `_outlinePath` to stroke the exact deformed contour with a `1.2 px` linear-gradient highlight tracking the pointer's stage vector.

### Layer 4: Isolated Widget Tree & Telemetry (`lib/src/widgets/`, `lib/src/telemetry/`)
- **`AetherStage`**: Hosts the single `Ticker`, `InheritedNotifier<AetherFieldController>` scope (`AetherStageScope`), optional `BackdropGroup` wrapper, `MediaQuery.maybeDisplayCornerRadiiOf` hardware adaptation, and `MediaQuery.disableAnimationsOf` reduced-motion compliance.
- **`AetherGlassCard` & `AetherMagneticButton`**: Wrap static inner child widgets in `RepaintBoundary` passed via `ListenableBuilder.child` so text and icons are never rebuilt or repainted on physics ticks. Blur filters (`ui.ImageFilter.blur`) are hoisted in a static sigma cache and applied via `BackdropFilter.grouped`.
- **`FrameMetricsTracker` & `AetherTelemetryHud`**: Observe `SchedulerBinding.addTimingsCallback` with a pre-allocated `Float64List(120)` ring buffer to compute real-time FPS, UI build ms, GPU raster ms, p50, and p90 frame budgets.
