# Changelog

All notable changes to **AetherGlass** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-27

### Added
* Initial enterprise release of **AetherGlass** by **Md Shabbir Mia** (`shabbirmia520@gmail.com`), a 100% pure-Flutter, zero-dependency kinetic liquid-glass UI and spatial physics engine.
* Single-`Ticker` centralized `AetherFieldController` with delta-time clamping (`<= 0.033s`), framerate-independent symplectic sub-stepped `SpringSolver`, deterministic `stepSimulation(dt)`, and zero-CPU automatic idle sleep/wake.
* Pre-allocated zero-allocation object pools: `RippleWavePool` (`6` slots), `AmbientMotePool` (`50` motes), `WakeTrailBuffer` (`14` points), `SpatialCardNode` registry, and cached canvas `Paint` / `Path` instances.
* Passive `AetherSurfaceListener` (`HitTestBehavior.translucent` + `VelocityTracker`) and `60 ms` cooldown-guarded `HapticPulseGuard`.
* Dynamic Bezier `LiquidEdgeClipper`, pointer-tracked `SpecularRimPainter`, Impeller-native `BackdropGroup` + `BackdropFilter.grouped` blur batching, hoisted `ui.ImageFilter.blur` cache, and wavefront-propagated 3D perspective tilt (`±7.0°` cap).
* Accessible `AetherMagneticButton` (`>= 48x48` logical px minimum hit target, keyboard `FocusableActionDetector`, `Semantics`, elastic `10.0 px` magnetic pull, snap haptics, and release wave).
* Hardware-aware corner adaptation via `MediaQuery.maybeDisplayCornerRadiiOf`, reduced-motion accessibility via `MediaQuery.disableAnimationsOf` / `MediaQuery.maybeReduceMotionOf`, and RTL-aware layouts.
* Built-in `AetherTelemetryHud` + `FrameMetricsTracker` (`FPS`, `UI ms`, `GPU ms`, `p50`, `p90`, active pools, `ACTIVE`/`SLEEPING`) and three immutable presets with `lerp` and `debugFillProperties`: `AetherPresets.bioluminescent`, `AetherPresets.obsidianFrost`, and `AetherPresets.solarAmber`.
* Multi-screen pure-Flutter `example/` showcase app (`ShowcaseDashboardScreen`, `BenchmarkComparisonScreen`, `CaptureStudioScreen`), Golden regression suite, and automated 10-image high-DPI README PNG generator.
