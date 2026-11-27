import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Adapts card radius from hardware displayCornerRadii', (
    WidgetTester tester,
  ) async {
    late BorderRadius resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 860),
          displayCornerRadii: BorderRadius.all(Radius.circular(44.0)),
        ),
        child: Builder(
          builder: (BuildContext context) {
            resolved = AetherAdaptiveGeometry.resolveCardRadius(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.topLeft, const Radius.elliptical(28.0, 28.0));
    expect(resolved.bottomRight, const Radius.elliptical(28.0, 28.0));
  });

  testWidgets('Honors MediaQuery.disableAnimations reduced-motion preference', (
    WidgetTester tester,
  ) async {
    final controller = AetherFieldController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF030A17),
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? _) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AetherStage(
              controller: controller,
              child: const Center(
                child: AetherGlassCard(child: Text('Calm Surface')),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();

    expect(controller.reducedMotion, isTrue);

    // Even under drag, reduced motion keeps card Bezier edge deformation calm.
    await tester.drag(find.text('Calm Surface'), const Offset(40, 20));
    await tester.pump(const Duration(milliseconds: 32));
    expect(controller.reducedMotion, isTrue);
  });
}
