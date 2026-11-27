import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapApp(Widget child) {
  return WidgetsApp(
    color: const Color(0xFF030A17),
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? _) => child,
  );
}

void main() {
  testWidgets('AetherStage preserves ListView scrolling & nested taps',
      (WidgetTester tester) async {
    final controller = AetherFieldController();
    addTearDown(controller.dispose);
    var tapped = 0;

    await tester.pumpWidget(
      _wrapApp(
        AetherStage(
          controller: controller,
          child: ListView.builder(
            itemCount: 30,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: AetherGlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Row $index'),
                      if (index == 0)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => tapped++,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Native Tap'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.registeredCardCount, greaterThan(0));

    await tester.tap(find.text('Native Tap'));
    await tester.pump(const Duration(milliseconds: 32));
    expect(tapped, 1);
    expect(controller.activeRippleCount, greaterThan(0));

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('Row 0'), findsNothing);
  });

  testWidgets('BackdropGroup blur batching toggles cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const AetherStage(
          enableBlurBatching: true,
          child: Center(
            child: AetherGlassCard(child: Text('Grouped')),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(BackdropGroup), findsOneWidget);

    await tester.pumpWidget(
      _wrapApp(
        const AetherStage(
          enableBlurBatching: false,
          child: Center(
            child: AetherGlassCard(child: Text('Ungrouped')),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(BackdropGroup), findsNothing);
  });
}
