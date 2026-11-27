import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'AetherThemeData immutability, equality, copyWith, lerp, diagnostics',
    () {
      test('presets satisfy value equality and stable hashCode', () {
        final copy = AetherPresets.bioluminescent.copyWith();
        expect(copy, equals(AetherPresets.bioluminescent));
        expect(copy.hashCode, equals(AetherPresets.bioluminescent.hashCode));
        expect(
          AetherPresets.bioluminescent,
          isNot(equals(AetherPresets.obsidianFrost)),
        );
        expect(
          AetherPresets.obsidianFrost,
          isNot(equals(AetherPresets.solarAmber)),
        );
      });

      test('copyWith selectively overrides physics and optical values', () {
        final tuned = AetherPresets.solarAmber.copyWith(
          stiffness: 310.0,
          damping: 22.0,
          edgeFlexDistance: 10.0,
          enableHaptics: false,
        );
        expect(tuned.stiffness, 310.0);
        expect(tuned.damping, 22.0);
        expect(tuned.edgeFlexDistance, 10.0);
        expect(tuned.enableHaptics, isFalse);
        expect(tuned.preset, AetherPreset.solarAmber);
        expect(tuned.blurSigma, AetherPresets.solarAmber.blurSigma);
      });

      test('lerp interpolates smoothly at t = 0, 0.5, and 1', () {
        const a = AetherPresets.bioluminescent;
        const b = AetherPresets.obsidianFrost;

        expect(AetherThemeData.lerp(a, b, 0.0), equals(a));
        expect(AetherThemeData.lerp(a, b, 1.0), equals(b));

        final mid = AetherThemeData.lerp(a, b, 0.5);
        expect(
          mid.stiffness,
          closeTo((a.stiffness + b.stiffness) * 0.5, 0.001),
        );
        expect(mid.damping, closeTo((a.damping + b.damping) * 0.5, 0.001));
        expect(mid.backgroundColors.length, a.backgroundColors.length);
      });

      test('debugFillProperties exposes physics diagnostics', () {
        final builder = DiagnosticPropertiesBuilder();
        AetherPresets.bioluminescent.debugFillProperties(builder);
        final names = builder.properties.map((DiagnosticsNode n) => n.name);
        expect(names, containsAll(<String>['preset', 'stiffness', 'damping']));
      });
    },
  );
}
