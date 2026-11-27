# Security Policy

## Supported Versions

| Version | Supported | Security Maintenance |
| :--- | :---: | :--- |
| `1.0.x` | Yes | Active security fixes and stability patches |

---

## Zero-Dependency & Pure-Dart Security Posture

**AetherGlass** is intentionally engineered with a minimal, auditable attack surface that executes **100% inside the Dart/Flutter runtime**:

- **Zero Third-Party Runtime Dependencies:** Root `pubspec.yaml` `dependencies` contains strictly `flutter: sdk: flutter`. This eliminates transitive third-party supply-chain risk from production app binaries.
- **Zero Native Code or Foreign-Language Bridges:** The package contains no C/C++ FFI modules, Kotlin/Java plugins, Swift/Objective-C bindings, platform method channels, custom GPU fragment shaders (`.frag`/`.glsl`), or custom JavaScript bridges—avoiding native memory-safety vulnerabilities and cross-boundary serialization flaws.
- **Zero I/O, Telemetry Egress, or Device Permissions:** At runtime, AetherGlass performs zero network requests, zero filesystem reads/writes, zero analytics/telemetry uploads, zero dynamic code evaluation, and requests zero OS permissions (using only Flutter's built-in `HapticFeedback` system service when enabled).
- **Bounded Memory & Numerical Safety Invariants:** All simulation buffers have compile-time fixed capacities (`RippleWavePool[6]`, `AmbientMotePool[50]`, `WakeTrailBuffer[14]`, `FrameMetricsTracker[120]`), frame deltas are clamped (`0.0001s <= dt <= 0.033s`), `SpringSolver` guards against `NaN`/`Infinity` divergence, and `LiquidEdgeClipper` guards against degenerate or empty `Size` rects—preventing unbounded memory growth or UI denial-of-service from malformed pointer streams or rapid viewport resizes.

---

## Reporting a Vulnerability

If you discover a security concern, crash, memory leak, floating-point instability (such as `NaN`/`Infinity` divergence on malformed pointer timestamps or zero-area layouts), or UI denial-of-service vector, please report it privately to the maintainer rather than opening a public issue:

- **Maintainer:** Md Shabbir Mia
- **Email:** [shabbirmia520@gmail.com](mailto:shabbirmia520@gmail.com)
- **Repository:** [https://github.com/mdshabbirmia/aether_glass](https://github.com/mdshabbirmia/aether_glass)

### What to Include
1. Minimal reproduction steps or a focused Flutter unit/widget test case.
2. Expected behavior vs. observed behavior (including stack trace or frame timing anomalies if applicable).
3. Your environment details (`flutter --version` and target platform: Android, iOS, Desktop, or Web/Wasm).

### Disclosure & Response Commitment
- **Initial Acknowledgment:** Within **48 hours** of receiving your report.
- **Triage & Fix:** Confirmed issues are prioritized for a clean pure-Dart fix with regression test coverage and coordinated release in `CHANGELOG.md`.
