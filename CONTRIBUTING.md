# Contributing to AetherGlass

Thank you for contributing to **AetherGlass**, maintained by **Md Shabbir Mia** (`shabbirmia520@gmail.com`). Because this package is engineered as a 100% pure-Flutter, zero-dependency, 60–120Hz rendering and physics engine, all pull requests must maintain strict architectural boundaries and performance discipline.

## Engineering Rules

1. **Zero Third-Party Runtime Dependencies:** Root `pubspec.yaml` `dependencies` must contain strictly `flutter: sdk: flutter`.
2. **100% Pure Dart / Flutter SDK Only:** No `.frag` GLSL shaders, no Kotlin, Swift, Objective-C, C/C++, JavaScript, Python, or shell scripts anywhere in the repository.
3. **Zero Per-Frame Heap Allocations:** Never allocate `Paint`, `Path`, `List`, `Map`, or particle/ripple objects inside `AetherFieldController.stepSimulation()` or `CustomPainter.paint()`. Reuse pre-allocated pools and `path.reset()`.
4. **Impeller Blur Discipline:** Keep `ui.ImageFilter.blur` instances hoisted and constant; never animate blur sigma frame-by-frame. Group sibling glass surfaces inside `BackdropGroup` with `BackdropFilter.grouped`.
5. **Strict Formatting, Static Analysis & Tests:** Ensure `dart format --output=none --set-exit-if-changed .` and `flutter analyze --fatal-infos` report **0 issues** across both the root package and `example/`, and all unit, widget, and Golden regression tests pass.

## Local Development Workflow

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
cd example
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --wasm
```

## Updating Golden Snapshots & Visual Assets

If you intentionally modify visual rendering behavior, regenerate Golden baselines and README PNG assets cleanly and review diffs before opening a PR:

```bash
flutter test --update-goldens test/golden/
flutter test test/tools/generate_readme_assets_test.dart
```

## Contact

For architectural proposals or maintainer questions, reach out to **Md Shabbir Mia** at `shabbirmia520@gmail.com`.
