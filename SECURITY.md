# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| `1.0.x` | Yes |

## Architecture & Attack Surface

**AetherGlass** executes 100% inside the Dart/Flutter runtime with:
- Zero third-party package dependencies
- Zero native platform channels (no Kotlin, Swift, C++, or JavaScript FFI bridges)
- Zero network I/O, filesystem access, or dynamic code execution

## Reporting a Vulnerability

If you discover a crash, memory leak, integer/floating-point instability (such as `NaN` physics divergence on malformed pointer timestamps), or denial-of-service vector, please report it responsibly by opening a private security advisory on GitHub or contacting the maintainer with reproduction steps and Flutter SDK version (`flutter --version`).
