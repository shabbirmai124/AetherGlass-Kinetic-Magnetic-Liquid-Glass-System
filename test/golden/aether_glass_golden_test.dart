import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildPresetHarness(AetherPreset preset) {
  final theme = AetherPresets.fromPreset(preset);
  final controller = AetherFieldController(theme: theme);
  return WidgetsApp(
    color: theme.backgroundColors.first,
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? _) {
      return DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontFamily: 'sans-serif',
          decoration: TextDecoration.none,
        ),
        child: SizedBox(
          width: 420,
          height: 760,
          child: AetherStage(
            controller: controller,
            theme: theme,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AetherGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          theme.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                            color: theme.specularColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kinetic Liquid-Glass',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AetherMagneticButton(
                          onPressed: () {},
                          child: const Text(
                            'Launch Wave',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: AetherGlassCard(
                          child: Text(
                            'Spring Solver',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: AetherGlassCard(
                          child: Text(
                            'Impeller Blur',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void main() {
  testWidgets(
    'Golden regression across Bioluminescent, ObsidianFrost, SolarAmber',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final preset in AetherPreset.values) {
        await tester.pumpWidget(_buildPresetHarness(preset));
        await tester.pump(const Duration(milliseconds: 40));

        await expectLater(
          find.byType(AetherStage),
          matchesGoldenFile('goldens/preset_${preset.name}.png'),
        );
      }
    },
  );
}
