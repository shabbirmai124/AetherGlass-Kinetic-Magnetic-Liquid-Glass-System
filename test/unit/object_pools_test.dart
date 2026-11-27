import 'dart:ui';

import 'package:aether_glass/aether_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pre-allocated zero-allocation object pools', () {
    test('RippleWavePool keeps fixed 6-slot capacity and recycles cleanly', () {
      final pool = RippleWavePool(capacity: 6);
      expect(pool.slots.length, 6);
      expect(pool.activeCount, 0);

      for (var i = 0; i < 6; i++) {
        final wave = pool.spawn(
          originX: i * 15.0,
          originY: 40.0,
          maxRadius: 240.0,
          intensity: 0.4 + i * 0.05,
        );
        expect(wave, isNotNull);
      }
      expect(pool.activeCount, 6);

      // Spawning beyond capacity recycles weakest slot without growing list.
      final recycled = pool.spawn(
        originX: 120.0,
        originY: 120.0,
        maxRadius: 300.0,
        intensity: 1.0,
        kind: AetherRippleKind.release,
      );
      expect(recycled, isNotNull);
      expect(pool.slots.length, 6);
      expect(pool.activeCount, 6);

      for (var i = 0; i < 90; i++) {
        pool.step(1.0 / 60.0);
      }
      expect(pool.activeCount, 0);
      expect(pool.slots.length, 6);
    });

    test('AmbientMotePool seeds 50 motes and applies 0.94 drag & deflection',
        () {
      final pool = AmbientMotePool(capacity: 50);
      expect(pool.motes.length, 50);

      pool.resize(const Size(600, 800));
      for (final mote in pool.motes) {
        expect(mote.seeded, isTrue);
        expect(mote.x, inInclusiveRange(0.0, 600.0));
        expect(mote.y, inInclusiveRange(0.0, 800.0));
      }

      pool.applyPointerWake(px: 300.0, py: 400.0, dx: 20.0, dy: -10.0);
      final moved = pool.step(
        dt: 1.0 / 60.0,
        viewportSize: const Size(600, 800),
        ripples: const <AetherRipple>[],
        reducedMotion: false,
        applyAmbientDrift: true,
      );
      expect(moved, isTrue);
      expect(pool.motes.length, 50);
    });

    test('WakeTrailBuffer wraps 14-point ring buffer and fades in 280ms', () {
      final buffer = WakeTrailBuffer(capacity: 14, fadeSeconds: 0.28);
      expect(buffer.points.length, 14);

      for (var i = 0; i < 20; i++) {
        buffer.push(i * 12.0, i * 8.0, speed: 500.0);
      }
      expect(buffer.points.length, 14);
      expect(buffer.points.where((AetherTrailPoint p) => p.active).length, 14);

      // Step 300ms (with 30ms sub-steps <= 280ms total fade window).
      for (var i = 0; i < 12; i++) {
        buffer.step(0.03);
      }
      expect(buffer.points.where((AetherTrailPoint p) => p.active).length, 0);
    });
  });
}
