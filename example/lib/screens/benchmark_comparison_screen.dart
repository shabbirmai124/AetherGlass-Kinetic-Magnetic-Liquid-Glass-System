import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';

import 'showcase_dashboard_screen.dart';

/// Live stress-benchmark view toggling Impeller [BackdropGroup] single-pass
/// blur batching against naive per-card stacked `BackdropFilter` passes.
class BenchmarkComparisonScreen extends StatelessWidget {
  const BenchmarkComparisonScreen({
    super.key,
    required this.theme,
    required this.enableBlurBatching,
    required this.panelCount,
    required this.stressWaves,
    required this.onToggleBlurBatching,
    required this.onSelectPanelCount,
    required this.onToggleStressWaves,
    required this.onEmitBurst,
  });

  final AetherThemeData theme;
  final bool enableBlurBatching;
  final int panelCount;
  final bool stressWaves;
  final VoidCallback onToggleBlurBatching;
  final ValueChanged<int> onSelectPanelCount;
  final VoidCallback onToggleStressWaves;
  final VoidCallback onEmitBurst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 900.0
            ? 4
            : (constraints.maxWidth >= 600.0 ? 3 : 2);
        final rows = (panelCount / columns).ceil();

        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AetherGlassCard(
                    padding: const EdgeInsetsDirectional.all(22.0),
                    semanticLabel: 'Blur Benchmark Controls',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'IMPELLER COMPOSITOR STRESS BENCHMARK',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: theme.specularColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          enableBlurBatching
                              ? 'Mode: BackdropGroup (1 Shared Blur Pass)'
                              : 'Mode: Naive Stacked ($panelCount Individual Passes)',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            GlassToggleChip(
                              label: enableBlurBatching
                                  ? 'BackdropGroup ON'
                                  : 'Naive Stacked',
                              active: enableBlurBatching,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onToggleBlurBatching,
                            ),
                            GlassToggleChip(
                              label: 'Run Stress Waves',
                              active: stressWaves,
                              accentColor: theme.rippleSecondaryColor,
                              onTap: onToggleStressWaves,
                            ),
                            for (final count in const <int>[6, 12, 24])
                              GlassSegmentButton(
                                label: '$count Panels',
                                selected: panelCount == count,
                                accentColor: theme.ripplePrimaryColor,
                                onTap: () => onSelectPanelCount(count),
                              ),
                            AetherMagneticButton(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 18.0,
                                vertical: 10.0,
                              ),
                              semanticLabel: 'Emit Stress Wave',
                              onPressed: onEmitBurst,
                              child: const Text(
                                'Emit Wave',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  for (var r = 0; r < rows; r++) ...<Widget>[
                    Row(
                      children: <Widget>[
                        for (var c = 0; c < columns; c++) ...<Widget>[
                          Expanded(
                            child: (r * columns + c) < panelCount
                                ? _BenchPanelCard(
                                    index: r * columns + c + 1,
                                    grouped: enableBlurBatching,
                                    accentColor: theme.specularColor,
                                    onTap: onEmitBurst,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          if (c < columns - 1) const SizedBox(width: 14.0),
                        ],
                      ],
                    ),
                    if (r < rows - 1) const SizedBox(height: 14.0),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BenchPanelCard extends StatelessWidget {
  const _BenchPanelCard({
    required this.index,
    required this.grouped,
    required this.accentColor,
    required this.onTap,
  });

  final int index;
  final bool grouped;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = index.toString().padLeft(2, '0');
    return AetherGlassCard(
      padding: const EdgeInsetsDirectional.all(16.0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'PANEL $label',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontFamily: 'monospace',
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            grouped ? 'Grouped Blur' : 'Isolated Blur',
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            grouped ? '1 shared pass' : 'Pass #$label',
            style: TextStyle(
              fontSize: 12.0,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
