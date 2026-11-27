import 'package:aether_glass/aether_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpringSolver convergence & stability', () {
    test('converges consistently at 30Hz, 60Hz, 90Hz, and 120Hz', () {
      double simulate(double hz, double seconds) {
        final state = AetherSpringState(value: 0.0, velocity: 0.0);
        final dt = 1.0 / hz;
        final steps = (seconds * hz).round();
        for (var i = 0; i < steps; i++) {
          SpringSolver.step(
            state: state,
            target: 1.0,
            stiffness: 340.0, // Obsidian Frost high stiffness
            damping: 26.0,
            dt: dt,
          );
          expect(state.value.isFinite, isTrue);
          expect(state.velocity.isFinite, isTrue);
          expect(state.value.abs(), lessThan(2.5));
        }
        return state.value;
      }

      final v30 = simulate(30.0, 0.25);
      final v60 = simulate(60.0, 0.25);
      final v90 = simulate(90.0, 0.25);
      final v120 = simulate(120.0, 0.25);

      expect((v30 - v60).abs(), lessThan(0.015));
      expect((v60 - v90).abs(), lessThan(0.01));
      expect((v90 - v120).abs(), lessThan(0.01));

      expect(simulate(30.0, 1.5), 1.0);
      expect(simulate(60.0, 1.5), 1.0);
      expect(simulate(90.0, 1.5), 1.0);
      expect(simulate(120.0, 1.5), 1.0);
    });

    test('clamps extreme dt spikes <= 0.033s and snaps below rest threshold', () {
      final state = AetherSpringState(value: 0.0, velocity: 0.0);

      // Simulate a 10-second background resume spike.
      SpringSolver.step(
        state: state,
        target: 1.0,
        stiffness: 260.0,
        damping: 18.0,
        dt: 10.0,
      );
      expect(state.value.isFinite, isTrue);
      expect(state.value.abs(), lessThan(0.5));

      // Verify snap-to-rest when |velocity| < 0.01 and |displacement| < 0.01.
      final nearRest = AetherSpringState(value: 0.9998, velocity: 0.002);
      final settled = SpringSolver.step(
        state: nearRest,
        target: 1.0,
        stiffness: 260.0,
        damping: 18.0,
        dt: 1.0 / 60.0,
      );
      expect(settled, isTrue);
      expect(nearRest.value, 1.0);
      expect(nearRest.velocity, 0.0);
    });
  });
}
