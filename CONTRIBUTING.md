# Contributing to AetherGlass

Thank you for contributing to **AetherGlass**. Because this package is engineered as a 100% pure-Flutter, zero-dependency, 60–120Hz kinetic liquid-glass rendering and spatial physics engine, all contributions must uphold strict architectural, performance, accessibility, and code-quality invariants.

## Maintainer Information

- **Maintainer:** Md Shabbir Mia
- **Email:** [shabbirmia520@gmail.com](mailto:shabbirmia520@gmail.com)
- **Repository:** [https://github.com/mdshabbirmia/aether_glass](https://github.com/mdshabbirmia/aether_glass)
- **Issue Tracker:** [https://github.com/mdshabbirmia/aether_glass/issues](https://github.com/mdshabbirmia/aether_glass/issues)

---

## Engineering Guidelines

1. **Zero Third-Party Runtime Dependencies:** Root `pubspec.yaml` `dependencies` must contain strictly `flutter: sdk: flutter`. `dev_dependencies` are restricted to `flutter_test: sdk: flutter` and `flutter_lints`.
2. **100% Pure Dart & Flutter SDK Only:** Do not introduce `.frag`/`.glsl` shaders, native platform directories (`android/`, `ios/`, `macos/`, `windows/`, `linux/`), Kotlin, Java, Swift, Objective-C, C/C++, Python, shell scripts, or custom JavaScript anywhere in the repository.
3. **Zero Per-Frame Heap Allocations & Dirty Checking:** Never allocate `Paint`, `Path`, `MaskFilter`, `List`, `Map`, or particle/wave objects inside `AetherFieldController.stepSimulation()` or `CustomPainter.paint()`. Mutate pre-allocated fixed-capacity pools (`RippleWavePool[6]`, `AmbientMotePool[50]`, `WakeTrailBuffer[14]`) and reuse `Path` objects via `path.reset()`. Keep `shouldRepaint` and `shouldReclip` strict so idle frames do zero redundant work.
4. **Impeller 60–120Hz Compositing Discipline:** Never call `setState()` during animation ticks. Route frame updates through `Listenable` / `ChangeNotifier` (`ListenableBuilder` with static UI hoisted into `child`) and `RepaintBoundary` isolation. Keep `ui.ImageFilter.blur` hoisted and constant (never animate blur sigma per frame), and group sibling glass panels inside `BackdropGroup` with `BackdropFilter.grouped`.
5. **Gesture Arena Non-Interference:** Observe pointer streams passively via `Listener(behavior: HitTestBehavior.translucent)` and `VelocityTracker` without entering or winning Flutter's gesture arena. Nested `ListView` scrolls, sliders, text selection, and buttons must behave identically to vanilla Flutter.
6. **Numerical Stability, Accessibility & RTL Readiness:**
   - Guard all physics and geometry paths against `Size.isEmpty`, zero dimensions, `NaN`, `Infinity`, and extreme frame delta spikes (`0.0001s <= dt <= 0.033s`).
   - Preserve `>= 48x48` logical px hit targets, `Semantics`, keyboard focus (`FocusableActionDetector`), `EdgeInsetsDirectional` / `AlignmentDirectional`, and OS reduced-motion preferences (`MediaQuery.disableAnimationsOf` / `MediaQuery.maybeReduceMotionOf`).
7. **Zero Analyzer Silencing & Public API Docs:** Maintain full `dartdoc` comments on all public APIs (`public_member_api_docs: true`) and never add `// ignore:` or `// ignore_for_file:` directives unless strictly unavoidable for an SDK compatibility shim.

---

## Local Verification Workflow

Run every gate below before opening a pull request—all checks must exit with **0 issues**:

```bash
# Root package checks
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze --fatal-infos --fatal-warnings
flutter test
dart pub publish --dry-run

# Example showcase & WebAssembly build checks
cd example
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build web --wasm
```

---

## Updating Golden Snapshots & Visual Assets

If a pull request intentionally changes rendered visuals, regenerate both the Golden baselines and the 10 high-DPI README PNG assets in pure Flutter and visually inspect every diff before committing:

```bash
flutter test --update-goldens test/golden/
flutter test test/tools/generate_readme_assets_test.dart
```

---

## Pull Request Checklist

- [ ] Root `pubspec.yaml` has zero third-party runtime dependencies (`flutter: sdk: flutter` only).
- [ ] Repository remains 100% pure Dart/Flutter with zero foreign-language scripts, shaders, or native platform boilerplate.
- [ ] `dart format`, `flutter analyze --fatal-infos --fatal-warnings`, all unit/widget/Golden tests, and `example/` Wasm build pass cleanly.
- [ ] New public symbols include clear `dartdoc` documentation and corresponding tests.

For architectural proposals or maintainer inquiries, contact **Md Shabbir Mia** at [shabbirmia520@gmail.com](mailto:shabbirmia520@gmail.com).
