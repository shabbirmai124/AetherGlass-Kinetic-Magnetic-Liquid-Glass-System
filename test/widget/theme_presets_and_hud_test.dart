import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Switches all 3 presets and renders AetherTelemetryHud & button',
    (WidgetTester tester) async {
      final controller = AetherFieldController(
        theme: AetherPresets.bioluminescent,
      );
      addTearDown(controller.dispose);
      var ctaClicks = 0;

      Widget buildHarness(AetherThemeData theme) {
        return WidgetsApp(
          color: theme.backgroundColors.first,
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? _) {
            return AetherStage(
              controller: controller,
              theme: theme,
              showPerformanceHud: true,
              child: Center(
                child: AetherMagneticButton(
                  semanticLabel: 'Action CTA',
                  onPressed: () => ctaClicks++,
                  child: Text(theme.name),
                ),
              ),
            );
          },
        );
      }

      await tester.pumpWidget(buildHarness(AetherPresets.bioluminescent));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.text('Bioluminescent'), findsOneWidget);
      expect(find.text('AETHER HUD'), findsOneWidget);
      expect(find.text('SLEEPING'), findsOneWidget);
      expect(find.textContaining('Motes 50'), findsOneWidget);

      await tester.tap(find.text('Bioluminescent'));
      await tester.pump(const Duration(milliseconds: 32));
      expect(ctaClicks, 1);
      expect(find.text('ACTIVE'), findsOneWidget);

      await tester.pumpWidget(buildHarness(AetherPresets.obsidianFrost));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.text('Obsidian Frost'), findsOneWidget);
      expect(controller.theme.stiffness, 340.0);

      await tester.pumpWidget(buildHarness(AetherPresets.solarAmber));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.text('Solar Amber'), findsOneWidget);
      expect(controller.theme.stiffness, 250.0);
    },
  );
}
