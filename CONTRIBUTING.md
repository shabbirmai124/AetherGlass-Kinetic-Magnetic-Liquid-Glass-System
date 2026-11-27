# Contributing to AetherGlass

Thank you for contributing to **AetherGlass**. Because this package is engineered as a zero-dependency, 60–120Hz pure-Flutter rendering and physics engine, all pull requests must maintain strict architectural boundaries and performance discipline.

## Engineering Rules

1. **Zero Third-Party Runtime Dependencies:** `pubspec.yaml` must depend strictly on `flutter: sdk: flutter`.
2. **100% Pure Dart / Flutter SDK Only:** No `.frag` GLSL shaders, no Kotlin/Swift/C++ bridges, and no external native plugins.
3. **Zero Per-Frame Heap Allocations:** Never allocate `Paint`, `Path`, `List`, `Map`, or particle/ripple objects inside `AetherFieldController.step()` or `CustomPainter.paint()`. Reuse pre-allocated pools and `path.reset()`.
4. **Impeller Blur Discipline:** Keep `ImageFilter` instances hoisted and constant; never animate blur sigma frame-by-frame. Group sibling glass surfaces inside `BackdropGroup` with `BackdropFilter.grouped`.
5. **Strict Static Analysis & Tests:** Ensure `flutter analyze` reports **0 issues** across both the root package and `example/`, and all unit, widget, and Golden regression tests pass.

## Local Development Workflow

```bash
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter analyze && flutter test
```

## Updating Golden Snapshots

If you intentionally modify visual rendering behavior, regenerate Golden images cleanly and inspect the diff before committing:

```bash
flutter test --update-goldens
```
