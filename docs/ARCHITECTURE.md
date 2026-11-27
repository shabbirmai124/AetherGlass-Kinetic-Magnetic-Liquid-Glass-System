# AetherGlass Technical Architecture

**Author:** Md Shabbir Mia (`shabbirmia520@gmail.com`)  
**Runtime Stack:** 100% Pure Flutter & Dart SDK (Zero Third-Party Runtime Dependencies, Zero Foreign Languages)

**AetherGlass** is a zero-dependency pure-Dart rendering and spatial physics engine built exclusively on Flutter SDK primitives (`flutter/widgets.dart`, `flutter/scheduler.dart`, `flutter/services.dart`, `flutter/foundation.dart`, `dart:ui`, `dart:math`, `dart:typed_data`). It replaces isolated per-widget animation controllers and redundant screen-buffer blurs with a single synchronized frame clock and Impeller-friendly backdrop compositing.

---

## 1. Four-Layer Unidirectional Data Flow

```text
  [Raw Pointer Events] ──> AetherSurfaceListener (HitTestBehavior.translucent)
                                 │  + VelocityTracker + HapticPulseGuard (60ms)
                                 ▼
                      AetherFieldController (Single Ticker, dt <= 0.033s, Auto-Sleep)
                       ├── SpringSolver (240Hz symplectic sub-stepping, NaN/Inf guards)
                       ├── RippleWavePool[6] (monotonic wavefront generation IDs)
                       ├── AmbientMotePool[50] (10 px/s drift, 0.94 drag)
                       ├── WakeTrailBuffer[14] (280 ms fade ring buffer)
                       └── SpatialCardNode Registry (scroll-aware bounds & 3D tilt springs)
                                 │  notifyListeners()
               ┌─────────────────┴──────────────────┐
               ▼                                    ▼
      AetherFieldPainter                  AetherGlassCard / MagneticButton
   (RepaintBoundary isolated)         (RepaintBoundary + ListenableBuilder)
   • Reused Paint/MaskFilter/Path     • Matrix4 3D tilt (<= ±7.0°)
   • Background, Motes, Ripples       • LiquidEdgeClipper (4 arcs + 4 Beziers)
   • 14px -> 0px Wake Ribbon          • SpecularRimPainter (1.2px pointer-tracked)
                                      • BackdropFilter.grouped in BackdropGroup
```

---

## 2. Layer Responsibilities & Invariants

### Layer 1: Passive Input & Guarded Haptics (`lib/src/input/`)
- **`AetherSurfaceListener`**: Wraps the stage in `Listener(behavior: HitTestBehavior.translucent)` with a reusable `VelocityTracker`. Because it never competes in Flutter's gesture arena, nested `ListView` scrolling, sliders, text selection, and buttons behave identically to vanilla Flutter.
- **`HapticPulseGuard`**: Enforces a strict `60 ms` minimum cooldown between `HapticFeedback.selectionClick()` / `HapticFeedback.lightImpact()` dispatches with an injectable clock for deterministic unit testing and global theme opt-out.

### Layer 2: Single-Ticker Physics & Pre-Allocated Pools (`lib/src/physics/`)
- **`SpringSolver`**: Uses semi-implicit (symplectic) Euler sub-stepping capped at `maxSubStep = 1/240s`, clamps incoming frame intervals to `0.0001s <= dt <= 0.033s`, guards against `NaN`/`Infinity`, and snaps cleanly to `target` with `velocity = 0.0` once `|velocity| < 0.01` and `|displacement| < epsilon`.
- **Zero-Allocation Pools**:
  - `RippleWavePool`: `6` fixed `AetherRipple` slots; recycles the weakest slot when saturated.
  - `AmbientMotePool`: `50` fixed `AetherMote` slots anchored to normalized coordinates (`Random(42)` deterministic seed).
  - `WakeTrailBuffer`: `14` fixed `AetherTrailPoint` ring slots fading over `280 ms` (`14.0 px` head to `0.0 px` tail).
  - `SpatialCardNode`: Pre-allocated per-card spring bundle (`tiltX`, `tiltY`, `depression`, `edgePullX`, `edgePullY`, `hoverGlow`, `suction`, `offsetX`, `offsetY`) + `Int32List(rippleCapacity)` wavefront deduplication buffer.
- **Zero-CPU Auto-Sleep**: When no pointer is active, all ripples complete, wake samples expire, and all card/mote springs settle, `AetherFieldController` stops its `Ticker` (`onSleepRequested`) until the next pointer interaction or programmatic `emitRipple()`.

### Layer 3: Canvas & Impeller Rendering (`lib/src/renderer/`)
- **`AetherFieldPainter`**: Pre-allocates every `Paint`, `MaskFilter.blur`, and `Path` once. `paint()` mutates colors/widths and resets `_ribbonPath.reset()` in place.
- **`LiquidEdgeClipper`**: Connects four corner circular arcs (`arcToPoint`) with four quadratic Bezier sides whose midpoints deflect up to `edgeFlexDistance` (`8.0 px` default) inside the `140.0 px` activation radius, guarding strictly against degenerate zero/empty sizes.
- **`SpecularRimPainter`**: Reuses a single `_outlinePath` to stroke the exact deformed contour with a `1.2 px` linear-gradient highlight tracking the pointer's stage angle.

### Layer 4: Isolated Widgets, Accessibility & Telemetry (`lib/src/widgets/`, `lib/src/telemetry/`)
- **`AetherStage`**: Hosts the single `Ticker`, `InheritedNotifier<AetherFieldController>` scope (`AetherStageScope`), optional `BackdropGroup` wrapper, hoisted static `ui.ImageFilter.blur` cache, `MediaQuery.maybeDisplayCornerRadiiOf` hardware corner adaptation, RTL-aware `AlignmentDirectional`/`EdgeInsetsDirectional`, and `MediaQuery.disableAnimationsOf` reduced-motion compliance.
- **`AetherGlassCard` & `AetherMagneticButton`**: Wrap static child subtrees inside `RepaintBoundary` passed via `ListenableBuilder.child` so text and icons are never rebuilt or repainted on physics ticks. `AetherMagneticButton` enforces `>= 48x48` logical px accessibility touch constraints and keyboard `FocusableActionDetector` activation.
- **`FrameMetricsTracker` & `AetherTelemetryHud`**: Observe `SchedulerBinding.addTimingsCallback` with a pre-allocated `Float64List(120)` ring buffer to compute rolling FPS, UI build ms, GPU raster ms, `p50`, and `p90` frame durations.
