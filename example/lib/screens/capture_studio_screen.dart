import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';

import 'showcase_dashboard_screen.dart';

/// Deterministic physics inspection scenarios for visual QA and README capture.
enum CaptureScenario {
  /// Magnetic Bezier edge pull toward a pinned near-edge pointer coordinate.
  edgeFlex,

  /// Expanding wavefront tilting a 2x2 grid of sibling cards in 3D.
  waveTilt,

  /// Tapered 14-point wake ribbon deflecting ambient light motes.
  wakeRibbon,

  /// Calm reduced-motion glass rendering with zero dynamic tilt or flex.
  reducedMotion,
}

/// Deterministic physics-state studio allowing engineers to step exact frame
/// timestamps and inspect edge flex, wave tilt, wake ribbons, and reduced
/// motion states reproducibly.
class CaptureStudioScreen extends StatefulWidget {
  const CaptureStudioScreen({
    super.key,
    required this.controller,
    required this.theme,
    required this.onReducedMotionChanged,
  });

  final AetherFieldController controller;
  final AetherThemeData theme;
  final ValueChanged<bool> onReducedMotionChanged;

  @override
  State<CaptureStudioScreen> createState() => _CaptureStudioScreenState();
}

class _CaptureStudioScreenState extends State<CaptureStudioScreen> {
  CaptureScenario _scenario = CaptureScenario.edgeFlex;

  void _applyScenario(CaptureScenario scenario) {
    setState(() {
      _scenario = scenario;
    });

    final c = widget.controller;
    final size = c.viewportSize;
    final reduced = scenario == CaptureScenario.reducedMotion;
    widget.onReducedMotionChanged(reduced);
    c.reducedMotion = reduced;
    c.showTouchIndicator = !reduced;

    switch (scenario) {
      case CaptureScenario.edgeFlex:
        final target = Offset(size.width * 0.56, size.height * 0.48);
        c.pinnedTouchIndicator = target;
        c.handlePointerDown(target);
        for (var i = 0; i < 20; i++) {
          c.stepSimulation(1.0 / 60.0);
        }
      case CaptureScenario.waveTilt:
        final origin = Offset(size.width * 0.50, size.height * 0.52);
        c.pinnedTouchIndicator = origin;
        c.emitRipple(
          origin: origin,
          maxRadius: 480.0,
          intensity: 1.0,
          strokeWidth: 3.6,
          kind: AetherRippleKind.pulse,
        );
        for (var i = 0; i < 18; i++) {
          c.stepSimulation(1.0 / 60.0);
        }
      case CaptureScenario.wakeRibbon:
        final start = Offset(size.width * 0.24, size.height * 0.60);
        c.handlePointerDown(start);
        Offset prev = start;
        for (var i = 1; i <= 14; i++) {
          final t = i / 14.0;
          final next = Offset(
            size.width * (0.24 + 0.52 * t),
            size.height * (0.60 - 0.22 * t + (i.isEven ? 0.03 : -0.03)),
          );
          c.handlePointerMove(next, next - prev);
          c.stepSimulation(1.0 / 60.0);
          prev = next;
        }
        c.pinnedTouchIndicator = prev;
      case CaptureScenario.reducedMotion:
        c.pinnedTouchIndicator = null;
        c.handlePointerCancel();
        for (var i = 0; i < 25; i++) {
          c.stepSimulation(1.0 / 60.0);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

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
                semanticLabel: 'Capture Studio Controls',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'DETERMINISTIC CAPTURE STUDIO',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: theme.specularColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Step exact physics states via stepSimulation(1/60s) for visual QA and documentation captures.',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: <Widget>[
                        GlassSegmentButton(
                          label: 'Edge Flex',
                          selected: _scenario == CaptureScenario.edgeFlex,
                          accentColor: theme.ripplePrimaryColor,
                          onTap: () => _applyScenario(CaptureScenario.edgeFlex),
                        ),
                        GlassSegmentButton(
                          label: 'Wave Tilt',
                          selected: _scenario == CaptureScenario.waveTilt,
                          accentColor: theme.ripplePrimaryColor,
                          onTap: () => _applyScenario(CaptureScenario.waveTilt),
                        ),
                        GlassSegmentButton(
                          label: 'Wake Ribbon',
                          selected: _scenario == CaptureScenario.wakeRibbon,
                          accentColor: theme.ripplePrimaryColor,
                          onTap: () =>
                              _applyScenario(CaptureScenario.wakeRibbon),
                        ),
                        GlassSegmentButton(
                          label: 'Reduced Motion',
                          selected: _scenario == CaptureScenario.reducedMotion,
                          accentColor: theme.ripplePrimaryColor,
                          onTap: () =>
                              _applyScenario(CaptureScenario.reducedMotion),
                        ),
                        AetherMagneticButton(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          semanticLabel: 'Step Simulation 16ms',
                          onPressed: () {
                            widget.controller.stepSimulation(1.0 / 60.0);
                          },
                          child: const Text(
                            'Step +16ms',
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: AetherGlassCard(
                      padding: const EdgeInsetsDirectional.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'SURFACE A',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: theme.specularColor,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Magnetic Bezier Target',
                            style: TextStyle(
                              fontSize: 19.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          const Text(
                            'Inspects surface-tension deflection and live specular angle.',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: AetherGlassCard(
                      padding: const EdgeInsetsDirectional.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'SURFACE B',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: theme.specularColor,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Wavefront Tilt Target',
                            style: TextStyle(
                              fontSize: 19.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          const Text(
                            'Tilts smoothly up to ±7° as expanding shockwaves cross.',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
