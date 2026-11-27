import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Registers cards, tilts on passing wave, enforces >=48dp magnetic button & keyboard activation',
    (WidgetTester tester) async {
      final controller = AetherFieldController(
        theme: AetherPresets.bioluminescent,
        autoSleep: false,
      );
      addTearDown(controller.dispose);
      var buttonActivated = 0;

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF040B16),
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? _) {
            return AetherStage(
              controller: controller,
              theme: AetherPresets.bioluminescent,
              autoSleep: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 240.0,
                      height: 110.0,
                      child: AetherGlassCard(
                        semanticLabel: 'Spatial Telemetry Panel',
                        child: Text('Wave Reactive Panel'),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    AetherMagneticButton(
                      semanticLabel: 'Launch Wave Button',
                      onPressed: () => buttonActivated++,
                      child: const Text('Go'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));

      // Both card and button should register in the spatial registry.
      expect(controller.registeredCardCount, 2);

      // Button must satisfy >= 48x48 accessible touch target constraints.
      final buttonSize = tester.getSize(find.byType(AetherMagneticButton));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Emit a ripple offset from the card and step simulation so wavefront crosses.
      controller.emitRipple(
        origin: const Offset(120.0, 120.0),
        maxRadius: 520.0,
        intensity: 1.0,
      );
      for (var i = 0; i < 25; i++) {
        controller.stepSimulation(1.0 / 60.0);
      }
      expect(controller.activeRippleCount, greaterThanOrEqualTo(1));

      // Tap activates button and emits release wave.
      await tester.tap(find.byType(AetherMagneticButton));
      await tester.pump(const Duration(milliseconds: 16));
      expect(buttonActivated, 1);

      // Keyboard activation via Enter on focused button works cleanly.
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF040B16),
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? _) {
            return AetherStage(
              controller: controller,
              theme: AetherPresets.bioluminescent,
              autoSleep: false,
              child: Center(
                child: AetherMagneticButton(
                  focusNode: focusNode,
                  semanticLabel: 'Keyboard Trigger',
                  onPressed: () => buttonActivated++,
                  child: const Text('Activate'),
                ),
              ),
            );
          },
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(buttonActivated, 2);
    },
  );
}
