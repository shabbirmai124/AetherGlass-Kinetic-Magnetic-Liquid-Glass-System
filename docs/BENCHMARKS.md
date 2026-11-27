# AetherGlass Performance & Benchmark Methodology

**Maintainer:** Md Shabbir Mia ([shabbirmia520@gmail.com](mailto:shabbirmia520@gmail.com))  
**Repository:** [https://github.com/mdshabbirmia/aether_glass](https://github.com/mdshabbirmia/aether_glass)

This document records verified measurements gathered from the codebase in this environment alongside reproducible Flutter Profile-mode procedures for physical Android, iOS, Desktop, and WebAssembly targets.

---

## 1. Verified Pure-Dart Physics Engine Benchmark

Executed directly via `flutter test test/unit/physics_benchmark_test.dart` simulating continuous worst-case interaction (**6 simultaneous active ripples + 50 swirling motes + 14-point wake trail + 6 registered 3D-tilting cards**, `autoSleep: false`):

| Metric | Measured Result (This Environment) | Budget Context |
| :--- | :--- | :--- |
| **Toolchain** | Flutter `3.51.0-0.1.pre` / Dart `3.14.0-248.0.dev` (Linux x64) | Verified headless unit harness |
| **Total Steps Executed** | `10,000 frames` | After 500-frame JIT warmup |
| **Total Elapsed Wall Time** | `296 ms` | Measured via `Stopwatch` |
| **Average CPU Step Latency** | **`29.61 µs / frame` (`0.0296 ms`)** | **0.36%** of an `8.33 ms` (120Hz) frame budget |
| **Idle Sleep CPU Usage** | `0.00%` | `Ticker` stops completely once settled (`\|v\| < 0.01`) |
| **Per-Frame Pool Allocations** | `0` new objects | Fixed `RippleWavePool[6]`, `AmbientMotePool[50]`, `WakeTrailBuffer[14]` |

---

## 2. Impeller GPU Blur Batching (`BackdropGroup` vs. Naive Stacked Blurs)

Standard glassmorphism wraps each card in an independent `BackdropFilter`, causing `N` separate framebuffer reads and `N` Gaussian blur convolutions per frame.

**AetherGlass** wraps sibling non-overlapping cards in `BackdropGroup` (`AetherStage.enableBlurBatching = true`) and constructs `BackdropFilter.grouped` using a hoisted immutable `ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)`:

| Architecture | Backdrop Captures / Frame (12 Cards) | Gaussian Convolutions / Frame | Static Child Rebuilds / Frame |
| :--- | :--- | :--- | :--- |
| Naive Stacked `BackdropFilter` | `12` | `12` | Depends on caller state |
| **AetherGlass `BackdropGroup`** | **`1` shared capture** | **`1` grouped pass** | **`0`** (`RepaintBoundary` + `child` cache) |

---

## 3. Reproducing Physical Device Profile-Mode Benchmarks (`p50` / `p90`)

> **Important:** Never record FPS or raster timings in Flutter Debug Mode (`flutter run`). Always run in **Profile Mode** on physical hardware so Dart AOT compilation and Impeller GPU rasterization are active.

Because the repository stays 100% Pure Dart (no committed Kotlin/Swift/C++ boilerplate), generate local native runners on demand when profiling on physical mobile/desktop hardware:

1. Generate platform runners on demand inside `example/` and launch in Profile Mode:
   ```bash
   cd example
   flutter create --platforms=android,ios,macos,windows,linux .
   flutter run --profile
   ```
2. Open the **Blur Bench** tab (`BenchmarkComparisonScreen`), select **12 Panels** or **24 Panels**, and enable **Run Stress Waves**.
3. Toggle **BackdropGroup ON** vs. **Naive Stacked** while reading live `UI ms`, `GPU ms`, `p50`, and `p90` from `AetherTelemetryHud` or Flutter DevTools Performance timeline:

| Device / Target | Panels | Mode | p50 Frame (ms) | p90 Frame (ms) | Target Budget |
| :--- | :---: | :--- | :---: | :---: | :---: |
| Physical Device (`flutter run --profile`) | 12 | Naive Stacked `BackdropFilter` | Record locally in Profile Mode | Record locally in Profile Mode | `< 8.33 ms` (120Hz) |
| Physical Device (`flutter run --profile`) | 12 | **AetherGlass `BackdropGroup`** | Record locally in Profile Mode | Record locally in Profile Mode | `< 8.33 ms` (120Hz) |

---

## 4. Reproducing the WebAssembly (Wasm) Build

Verified locally using Flutter `3.51.0-0.1.pre` / Dart `3.14.0-248.0.dev`:

```bash
cd example
flutter pub get
flutter build web --wasm
```
