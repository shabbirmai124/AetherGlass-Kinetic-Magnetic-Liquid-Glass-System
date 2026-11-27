## 1.0.0

* Initial release of **AetherGlass**, a zero-dependency pure-Flutter kinetic liquid-glass UI and spatial physics engine.
* Single-`Ticker` centralized `AetherController` with delta-time clamping (`<= 33.3 ms`), framerate-independent symplectic spring solver, and automatic idle sleep/wake.
* Pre-allocated object pools for ripples, ambient motes, drag trail points, and reusable canvas `Paint` / `Path` objects.
* Dynamic Bezier `AetherGlassClipper`, Impeller-native `BackdropGroup` + `BackdropFilter.grouped` blur batching, hoisted `ImageFilter` cache, and 3D ripple-wavefront perspective tilt.
* Hardware-aware corner adaptation via `MediaQuery.maybeDisplayCornerRadiiOf`, `MediaQuery.maybeReduceMotionOf` accessibility dampening, and cooldown-guarded micro-haptics.
* Built-in `AetherPerformanceHud` telemetry overlay and three signature presets: `bioluminescentOcean`, `frostedObsidian`, and `acousticPulse`.
