import 'dart:ui';

import 'package:aether_glass/aether_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AetherFieldController lifecycle, haptics & wave propagation', () {
    test('wakes on touch, propagates 3D wavefront tilt, and auto-sleeps', () {
      var wakes = 0;
      var sleeps = 0;
      final controller = AetherFieldController(
        theme: AetherPresets.bioluminescent,
      )
        ..onWakeRequested = () {
          wakes++;
        }
        ..onSleepRequested = () {
          sleeps++;
        }
        ..setViewportSize(const Size(600, 800));

      final cardToken = Object();
      final card = controller.registerCard(
        cardToken,
        const Rect.fromLTWH(200, 200, 160, 120),
      );

      expect(controller.isSleeping, isTrue);

      controller.handlePointerDown(const Offset(60, 260));
      controller.handlePointerUp(const Offset(60, 260));
      expect(controller.isSleeping, isFalse);
      expect(wakes, 1);

      var sawWaveTilt = false;
      for (var frame = 1; frame <= 260; frame++) {
        controller.stepSimulation(1.0 / 60.0);
        if (card.tiltY.value.abs() > 0.001 || card.tiltX.value.abs() > 0.001) {
          sawWaveTilt = true;
        }
        if (controller.isSleeping) {
          break;
        }
      }

      expect(sawWaveTilt, isTrue);
      expect(controller.isSleeping, isTrue);
      expect(sleeps, greaterThanOrEqualTo(1));
    });

    test('HapticPulseGuard enforces 60ms cooldown between triggers', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0, 0);
      var clicks = 0;
      var impacts = 0;
      final guard = HapticPulseGuard(
        cooldown: const Duration(milliseconds: 60),
        onSelectionClick: () => clicks++,
        onLightImpact: () => impacts++,
        clock: () => now,
      );

      expect(guard.triggerSelection(enabled: true), isTrue);
      expect(clicks, 1);

      now = now.add(const Duration(milliseconds: 30));
      expect(guard.triggerImpact(enabled: true), isFalse);
      expect(impacts, 0);

      now = now.add(const Duration(milliseconds: 35));
      expect(guard.triggerImpact(enabled: true), isTrue);
      expect(impacts, 1);
    });
  });
}
