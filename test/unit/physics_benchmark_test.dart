import 'dart:ui';

import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Physics engine step latency benchmark (6 waves, 50 motes, 6 cards)', () {
    final controller = AetherFieldController(
      theme: AetherPresets.bioluminescent,
      autoSleep: false,
    )..setViewportSize(const Size(420, 900));

    for (var i = 0; i < 6; i++) {
      controller.registerCard(
        i,
        Rect.fromLTWH(
          24.0 + (i % 2) * 190.0,
          80.0 + (i ~/ 2) * 200.0,
          172.0,
          140.0,
        ),
      );
    }

    // Warmup JIT & pre-allocated pools.
    for (var i = 0; i < 500; i++) {
      if (i % 30 == 0) {
        controller.emitRipple(origin: const Offset(210, 420), maxRadius: 460);
      }
      controller.step(Duration(microseconds: i * 8333));
    }

    const iterations = 10000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      if (i % 45 == 0) {
        controller.emitRipple(origin: const Offset(210, 420), maxRadius: 460);
      }
      controller.handlePointerMove(
        Offset(120.0 + (i % 180), 300.0 + (i % 120)),
        const Offset(2.0, 1.5),
      );
      controller.step(Duration(microseconds: (500 + i) * 8333));
    }
    sw.stop();

    final avgMicros = sw.elapsedMicroseconds / iterations;
    debugPrint(
      'BENCHMARK: $iterations steps in ${sw.elapsedMilliseconds}ms '
      '(${avgMicros.toStringAsFixed(2)} us/frame = '
      '${(avgMicros / 1000.0).toStringAsFixed(4)} ms/frame)',
    );

    // Must comfortably stay well under the 8.33 ms (8333 us) 120Hz frame budget.
    expect(avgMicros, lessThan(2000.0));
  });
}
