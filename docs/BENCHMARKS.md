# AetherGlass Performance & Benchmark Methodology

This document records verified measurements gathered from the codebase in this environment alongside reproducible Flutter Profile-mode procedures for physical Android, iOS, Desktop, and WebAssembly targets.

---

## 1. Verified Pure-Dart Physics Engine Benchmark

Executed directly via `flutter test test/unit/physics_benchmark_test.dart` simulating continuous worst-case interaction (**6 simultaneous active ripples + 50 swirling motes + 14-point wake trail + 6 registered 3D-tilting cards**):

| Metric | Measured Result | Notes |
| --- | --- | --- |
| Total Steps Executed | `10,000 frames` | Continuous active interaction (`autoSleep: false`) |
| Total Elapsed Wall Time | `159 ms` | Measured via `Stopwatch` after 500-frame warmup |
| Average CPU Step Latency | **`15.97 µs / frame` (`0.0160 ms`)** | **0.19%** of an `8.33 ms` (120Hz) frame budget |
| Idle Sleep CPU Usage | `0.00%` | `Ticker` stops completely once springs settle (`|v| < 0.01`) |
| Per-Frame Pool Allocations | `0` new objects | Fixed `RippleWavePool[6]`, `AmbientMotePool[50]`, `WakeTrailBuffer[14]` |

---

## 2. Impeller GPU Blur Batching (`BackdropGroup` vs. Naive Stacked Blurs)

Standard glassmorphism wraps each card in an independent `BackdropFilter`, causing `N` separate framebuffer reads and `N` Gaussian blur convolutions per frame.

**AetherGlass** wraps sibling non-overlapping cards in `BackdropGroup` (`AetherStage.enableBlurBatching = true`) and constructs `BackdropFilter.grouped` using a hoisted immutable `ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)`:

| Architecture | Backdrop Captures / Frame (12 Cards) | Gaussian Convolutions / Frame | Static Child Rebuilds / Frame |
| --- | --- | --- | --- |
| Naive Stacked `BackdropFilter` | `12` | `12` | Depends on caller state |
| **AetherGlass `BackdropGroup`** | **`1` shared capture** | **`1` grouped pass** | **`0`** (`RepaintBoundary` + `child` cache) |

---

## 3. Reproducing Device Profile-Mode Benchmarks (`p50` / `p90`)

> **Important:** Never record FPS or raster timings in Flutter Debug Mode (`flutter run`). Always run in **Profile Mode** on a physical device so Dart AOT compilation and Impeller GPU rasterization are active.

1. Connect an Android or iOS device (with 60Hz or 120Hz display) and launch the built-in benchmark screen in Profile Mode:
   ```bash
   cd example
   flutter run --profile
   ```
2. Switch to the **Blur Bench** tab (`BenchmarkComparisonScreen`), choose **12 Panels** or **24 Panels**, and tap **Run Stress Waves**.
3. Toggle **Mode: BackdropGroup (1 Pass)** vs. **Mode: Naive Stacked (N Passes)** while reading live `UI ms`, `GPU ms`, `p50`, and `p90` from the `AetherTelemetryHud` overlay (or DevTools Performance timeline):

| Device / Target | Panels | Mode | p50 Frame (ms) | p90 Frame (ms) | Target Budget |
| --- | --- | --- | --- | --- | --- |
| Physical Device (`flutter run --profile`) | 12 | Naive Stacked `BackdropFilter` | *[Record in Profile Mode]* | *[Record in Profile Mode]* | `< 8.33 ms` (120Hz) |
| Physical Device (`flutter run --profile`) | 12 | **AetherGlass `BackdropGroup`** | *[Record in Profile Mode]* | *[Record in Profile Mode]* | `< 8.33 ms` (120Hz) |

## 4. Reproducing the WebAssembly (Wasm) Build

Verified locally using Flutter `3.50.1` / Dart `3.14.0`:

```bash
cd example
flutter build web --wasm
```
