import 'package:aether_glass_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example showcase switches presets and engineering screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AetherExampleApp());
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.text('Kinetic Magnetic Liquid-Glass UI'), findsOneWidget);
    expect(find.text('AETHER HUD'), findsOneWidget);

    await tester.tap(find.text('Obsidian Frost'));
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('340 N/m'), findsNWidgets(2));

    await tester.tap(find.text('Blur Bench'));
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('IMPELLER COMPOSITOR STRESS BENCHMARK'), findsOneWidget);

    await tester.tap(find.text('Capture Studio'));
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('DETERMINISTIC CAPTURE STUDIO'), findsOneWidget);
  });
}
