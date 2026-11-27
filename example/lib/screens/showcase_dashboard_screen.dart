import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';

/// Pure-widgets tactile glass slider for live physics and optical tuning.
class GlassSlider extends StatelessWidget {
  const GlassSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  void _updateFromDx(double dx, double width) {
    if (width <= 0.0) {
      return;
    }
    final t = (dx / width).clamp(0.0, 1.0);
    onChanged(min + t * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    final span = max - min;
    final fraction = span > 0.0 ? ((value - min) / span).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      slider: true,
      label: label,
      value: valueLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCBD5E1),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbOffset =
                  (trackWidth - 16.0).clamp(0.0, trackWidth) * fraction;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (TapDownDetails d) =>
                    _updateFromDx(d.localPosition.dx, trackWidth),
                onHorizontalDragUpdate: (DragUpdateDetails d) =>
                    _updateFromDx(d.localPosition.dx, trackWidth),
                child: SizedBox(
                  height: 24.0,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      Container(
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: thumbOffset,
                        child: Container(
                          width: 16.0,
                          height: 16.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pure-widgets tactile toggle chip for engine feature switches.
class GlassToggleChip extends StatelessWidget {
  const GlassToggleChip({
    super.key,
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: active
                ? accentColor.withValues(alpha: 0.18)
                : const Color(0x16FFFFFF),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: active
                  ? accentColor.withValues(alpha: 0.85)
                  : const Color(0x33FFFFFF),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? accentColor : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pure-widgets segmented selector button for presets, counts, and screens.
class GlassSegmentButton extends StatelessWidget {
  const GlassSegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.swatchColor,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final Color? swatchColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14.0,
            vertical: 9.0,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.20)
                : const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.90)
                  : const Color(0x2BFFFFFF),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (swatchColor != null) ...<Widget>[
                Container(
                  width: 9.0,
                  height: 9.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatchColor,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive hero dashboard showcasing presets, 2x2 wave-reactive glass
/// panels, live spring/optical sliders, and telemetry/accessibility switches.
class ShowcaseDashboardScreen extends StatelessWidget {
  const ShowcaseDashboardScreen({
    super.key,
    required this.controller,
    required this.theme,
    required this.enableBlurBatching,
    required this.reducedMotion,
    required this.showPerformanceHud,
    required this.rhythmicPulse,
    required this.showTouchMarker,
    required this.onSelectPreset,
    required this.onUpdateTheme,
    required this.onToggleBlurBatching,
    required this.onToggleReducedMotion,
    required this.onTogglePerformanceHud,
    required this.onToggleRhythmicPulse,
    required this.onToggleTouchMarker,
    required this.onLaunchWave,
  });

  final AetherFieldController controller;
  final AetherThemeData theme;
  final bool enableBlurBatching;
  final bool reducedMotion;
  final bool showPerformanceHud;
  final bool rhythmicPulse;
  final bool showTouchMarker;
  final ValueChanged<AetherPreset> onSelectPreset;
  final ValueChanged<AetherThemeData> onUpdateTheme;
  final VoidCallback onToggleBlurBatching;
  final VoidCallback onToggleReducedMotion;
  final VoidCallback onTogglePerformanceHud;
  final VoidCallback onToggleRhythmicPulse;
  final VoidCallback onToggleTouchMarker;
  final VoidCallback onLaunchWave;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = AetherAdaptiveGeometry.resolveCardRadius(context);
    final radiusLabel =
        '${resolvedRadius.topLeft.x.toStringAsFixed(0)} px adaptive';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final wide = constraints.maxWidth >= 820.0;

        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AetherGlassCard(
                    padding: EdgeInsetsDirectional.all(wide ? 26.0 : 20.0),
                    semanticLabel: 'AetherGlass Hero Panel',
                    child: Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: wide
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: wide ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'AETHERGLASS • PURE-FLUTTER KINETIC ENGINE',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: theme.specularColor,
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              const Text(
                                'Kinetic Magnetic Liquid-Glass UI',
                                style: TextStyle(
                                  fontSize: 28.0,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Hover, drag, or tap anywhere on the stage to flex Bezier edges, tilt sibling panels in 3D, and swirl ambient motes with zero per-frame allocations.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  height: 1.45,
                                  color: const Color(
                                    0xFFFFFFFF,
                                  ).withValues(alpha: 0.78),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                children: <Widget>[
                                  for (final preset in AetherPresets.all)
                                    GlassSegmentButton(
                                      label: preset.name,
                                      selected: theme.preset == preset.preset,
                                      accentColor: theme.ripplePrimaryColor,
                                      swatchColor: preset.ripplePrimaryColor,
                                      onTap: () =>
                                          onSelectPreset(preset.preset),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: wide ? 24.0 : 0.0,
                          height: wide ? 0.0 : 18.0,
                        ),
                        AetherMagneticButton(
                          semanticLabel: 'Launch Kinetic Wave',
                          onPressed: onLaunchWave,
                          child: const Text(
                            'Launch Kinetic Wave',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  _MetricGrid(
                    wide: wide,
                    theme: theme,
                    controller: controller,
                    enableBlurBatching: enableBlurBatching,
                    radiusLabel: radiusLabel,
                    onCardTap: onLaunchWave,
                  ),
                  const SizedBox(height: 18.0),
                  AetherGlassCard(
                    padding: const EdgeInsetsDirectional.all(22.0),
                    semanticLabel: 'Physics and Optical Tuning Panel',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'LIVE PHYSICS & OPTICAL TUNING',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: theme.specularColor,
                              ),
                            ),
                            Text(
                              theme.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Flex(
                          direction: wide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: wide ? 1 : 0,
                              child: Column(
                                children: <Widget>[
                                  GlassSlider(
                                    label: 'Spring Stiffness (k)',
                                    valueLabel:
                                        '${theme.stiffness.toStringAsFixed(0)} N/m',
                                    value: theme.stiffness,
                                    min: 100.0,
                                    max: 420.0,
                                    accentColor: theme.ripplePrimaryColor,
                                    onChanged: (double next) => onUpdateTheme(
                                      theme.copyWith(stiffness: next),
                                    ),
                                  ),
                                  const SizedBox(height: 14.0),
                                  GlassSlider(
                                    label: 'Spring Damping (c)',
                                    valueLabel: theme.damping.toStringAsFixed(
                                      1,
                                    ),
                                    value: theme.damping,
                                    min: 8.0,
                                    max: 34.0,
                                    accentColor: theme.ripplePrimaryColor,
                                    onChanged: (double next) => onUpdateTheme(
                                      theme.copyWith(damping: next),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: wide ? 28.0 : 0.0,
                              height: wide ? 0.0 : 14.0,
                            ),
                            Expanded(
                              flex: wide ? 1 : 0,
                              child: Column(
                                children: <Widget>[
                                  GlassSlider(
                                    label: 'Bezier Edge Flex',
                                    valueLabel:
                                        '${theme.edgeFlexDistance.toStringAsFixed(1)} px',
                                    value: theme.edgeFlexDistance,
                                    min: 0.0,
                                    max: 16.0,
                                    accentColor: theme.rippleSecondaryColor,
                                    onChanged: (double next) => onUpdateTheme(
                                      theme.copyWith(edgeFlexDistance: next),
                                    ),
                                  ),
                                  const SizedBox(height: 14.0),
                                  GlassSlider(
                                    label: 'Hoisted Blur Sigma',
                                    valueLabel:
                                        'σ ${theme.blurSigma.toStringAsFixed(1)}',
                                    value: theme.blurSigma,
                                    min: 0.0,
                                    max: 24.0,
                                    accentColor: theme.rippleSecondaryColor,
                                    onChanged: (double next) => onUpdateTheme(
                                      theme.copyWith(blurSigma: next),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18.0),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: <Widget>[
                            GlassToggleChip(
                              label: 'BackdropGroup',
                              active: enableBlurBatching,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onToggleBlurBatching,
                            ),
                            GlassToggleChip(
                              label: 'Reduced Motion',
                              active: reducedMotion,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onToggleReducedMotion,
                            ),
                            GlassToggleChip(
                              label: 'Telemetry HUD',
                              active: showPerformanceHud,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onTogglePerformanceHud,
                            ),
                            GlassToggleChip(
                              label: 'Rhythmic Pulse',
                              active: rhythmicPulse,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onToggleRhythmicPulse,
                            ),
                            GlassToggleChip(
                              label: 'Touch Marker',
                              active: showTouchMarker,
                              accentColor: theme.ripplePrimaryColor,
                              onTap: onToggleTouchMarker,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.wide,
    required this.theme,
    required this.controller,
    required this.enableBlurBatching,
    required this.radiusLabel,
    required this.onCardTap,
  });

  final bool wide;
  final AetherThemeData theme;
  final AetherFieldController controller;
  final bool enableBlurBatching;
  final String radiusLabel;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _MetricCard(
        eyebrow: 'SPRING SOLVER',
        headline: '${theme.stiffness.toStringAsFixed(0)} N/m',
        subtitle:
            'Symplectic 240Hz substep • c=${theme.damping.toStringAsFixed(1)}',
        accentColor: theme.specularColor,
        onTap: onCardTap,
      ),
      _MetricCard(
        eyebrow: 'ZERO-ALLOC POOLS',
        headline:
            '${controller.maxRipples} Waves • ${controller.particleCount} Motes',
        subtitle: '${controller.maxTrailPoints}-pt wake ribbon ring buffer',
        accentColor: theme.specularColor,
        onTap: onCardTap,
      ),
      _MetricCard(
        eyebrow: 'IMPELLER BLUR',
        headline: enableBlurBatching ? 'BackdropGroup' : 'Naive Stacked',
        subtitle: enableBlurBatching
            ? 'Shared single-pass blur (σ=${theme.blurSigma.toStringAsFixed(1)})'
            : 'Per-card backdrop blur passes',
        accentColor: theme.specularColor,
        onTap: onCardTap,
      ),
      _MetricCard(
        eyebrow: 'SURFACE GEOMETRY',
        headline: '${theme.edgeFlexDistance.toStringAsFixed(1)} px Flex',
        subtitle: 'Corners $radiusLabel • ±7° 3D tilt cap',
        accentColor: theme.specularColor,
        onTap: onCardTap,
      ),
    ];

    if (wide) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: cards[0]),
              const SizedBox(width: 16.0),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: <Widget>[
              Expanded(child: cards[2]),
              const SizedBox(width: 16.0),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        for (var i = 0; i < cards.length; i++) ...<Widget>[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 14.0),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final String eyebrow;
  final String headline;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AetherGlassCard(
      padding: const EdgeInsetsDirectional.all(22.0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.0,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
