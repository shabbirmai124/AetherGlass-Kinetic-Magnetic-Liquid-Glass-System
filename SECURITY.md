# Security Policy

## Supported Versions

| Version | Supported |
| :--- | :--- |
| `1.0.x` | Yes |

## Architecture & Zero-Dependency Security Posture

**AetherGlass** executes 100% inside the Dart/Flutter runtime with:
- Zero third-party runtime package dependencies (`flutter: sdk: flutter` only)
- Zero native platform channels or foreign-language code (no Kotlin, Swift, Objective-C, C/C++, GLSL shaders, or custom JavaScript bridges)
- Zero network I/O, runtime filesystem access, or dynamic code evaluation

## Reporting a Vulnerability

If you discover a crash, memory leak, floating-point instability (such as `NaN`/`Infinity` physics divergence on malformed pointer timestamps or degenerate viewport rects), or denial-of-service vector, please report it responsibly to the maintainer:

- **Maintainer:** Md Shabbir Mia
- **Email:** `shabbirmia520@gmail.com`

Include minimal reproduction steps, expected vs. actual behavior, and your Flutter/Dart SDK version (`flutter --version`).
