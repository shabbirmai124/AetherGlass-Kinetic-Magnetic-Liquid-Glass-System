import 'dart:async';
import 'dart:math' as math;

import 'package:aether_glass/aether_glass.dart';
import 'package:flutter/widgets.dart';

import 'screens/benchmark_comparison_screen.dart';
import 'screens/capture_studio_screen.dart';
import 'screens/showcase_dashboard_screen.dart';

void main() {
  runApp(const AetherExampleApp());
}

enum _ExampleScreen { dashboard, blurBench, captureStudio }

/// Pure-Flutter 3-screen showcase application demonstrating the AetherGlass
/// kinetic liquid-glass rendering and spatial physics engine.
class AetherExampleApp extends StatefulWidget {
  const AetherExampleApp({super.key});

  @override
  State<AetherExampleApp> createState() => _AetherExampleAppState();
}

class _AetherExampleAppState extends State<AetherExampleApp> {
  late final AetherFieldController _controller;
  final math.Random _random = math.Random(42);

  AetherThemeData _theme = AetherPresets.bioluminescent;
  _ExampleScreen _screen = _ExampleScreen.dashboard;
  bool _enableBlurBatching = true;
  bool _reducedMotion = false;
  bool _showPerformanceHud = true;
  bool _rhythmicPulse = false;
  bool _stressWaves = false;
  int _benchPanelCount = 12;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AetherFieldController(
      theme: _theme,
      animateParticlesWhenIdle: false,
    );
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncPulseTimer() {
    _pulseTimer?.cancel();
    final active =
        _rhythmicPulse || (_screen == _ExampleScreen.blurBench && _stressWaves);
    if (!active) {
      return;
    }
    final period = (_screen == _ExampleScreen.blurBench && _stressWaves)
        ? const Duration(milliseconds: 550)
        : const Duration(milliseconds: 1400);
    _pulseTimer = Timer.periodic(period, (_) => _emitRandomWave());
  }

  void _emitCenterWave() {
    final size = _controller.viewportSize;
    _controller.emitRipple(
      origin: Offset(size.width * 0.5, size.height * 0.42),
      maxRadius: math.max(size.longestSide * 0.65, 420.0),
      intensity: 0.98,
      strokeWidth: 3.4,
      kind: AetherRippleKind.pulse,
    );
  }

  void _emitRandomWave() {
    final size = _controller.viewportSize;
    _controller.emitRipple(
      origin: Offset(
        size.width * (0.18 + _random.nextDouble() * 0.64),
        size.height * (0.20 + _random.nextDouble() * 0.60),
      ),
      maxRadius: math.max(size.longestSide * 0.62, 380.0),
      intensity: 0.90,
      strokeWidth: 3.2,
      kind: AetherRippleKind.pulse,
    );
  }

  void _selectPreset(AetherPreset preset) {
    final next = AetherPresets.fromPreset(preset);
    setState(() {
      _theme = next;
    });
    _controller.theme = next;
    _emitCenterWave();
  }

  void _selectScreen(_ExampleScreen screen) {
    setState(() {
      _screen = screen;
    });
    _syncPulseTimer();
    if (screen != _ExampleScreen.captureStudio) {
      _controller.pinnedTouchIndicator = null;
      _emitCenterWave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'AetherGlass Showcase',
      color: _theme.backgroundColors.first,
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? _) {
        return DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14.0,
            color: Color(0xFFF8FAFC),
            decoration: TextDecoration.none,
          ),
          child: AetherStage(
            controller: _controller,
            theme: _theme,
            enableBlurBatching: _enableBlurBatching,
            reducedMotion: _reducedMotion,
            showPerformanceHud: _showPerformanceHud,
            hudAlignment: AlignmentDirectional.bottomEnd,
            hudPadding: const EdgeInsetsDirectional.all(16.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20.0,
                      16.0,
                      20.0,
                      8.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 10.0,
                                    height: 10.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _theme.ripplePrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  const Text(
                                    'AetherGlass',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: <Widget>[
                                GlassSegmentButton(
                                  label: 'Dashboard',
                                  selected: _screen == _ExampleScreen.dashboard,
                                  accentColor: _theme.ripplePrimaryColor,
                                  onTap: () =>
                                      _selectScreen(_ExampleScreen.dashboard),
                                ),
                                GlassSegmentButton(
                                  label: 'Blur Bench',
                                  selected: _screen == _ExampleScreen.blurBench,
                                  accentColor: _theme.ripplePrimaryColor,
                                  onTap: () =>
                                      _selectScreen(_ExampleScreen.blurBench),
                                ),
                                GlassSegmentButton(
                                  label: 'Capture Studio',
                                  selected:
                                      _screen == _ExampleScreen.captureStudio,
                                  accentColor: _theme.ripplePrimaryColor,
                                  onTap: () => _selectScreen(
                                    _ExampleScreen.captureStudio,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: switch (_screen) {
                      _ExampleScreen.dashboard => ShowcaseDashboardScreen(
                        controller: _controller,
                        theme: _theme,
                        enableBlurBatching: _enableBlurBatching,
                        reducedMotion: _reducedMotion,
                        showPerformanceHud: _showPerformanceHud,
                        rhythmicPulse: _rhythmicPulse,
                        showTouchMarker: _controller.showTouchIndicator,
                        onSelectPreset: _selectPreset,
                        onUpdateTheme: (AetherThemeData next) {
                          setState(() {
                            _theme = next;
                          });
                          _controller.theme = next;
                        },
                        onToggleBlurBatching: () {
                          setState(() {
                            _enableBlurBatching = !_enableBlurBatching;
                          });
                        },
                        onToggleReducedMotion: () {
                          setState(() {
                            _reducedMotion = !_reducedMotion;
                          });
                        },
                        onTogglePerformanceHud: () {
                          setState(() {
                            _showPerformanceHud = !_showPerformanceHud;
                          });
                        },
                        onToggleRhythmicPulse: () {
                          setState(() {
                            _rhythmicPulse = !_rhythmicPulse;
                          });
                          _syncPulseTimer();
                        },
                        onToggleTouchMarker: () {
                          setState(() {
                            _controller.showTouchIndicator =
                                !_controller.showTouchIndicator;
                          });
                        },
                        onLaunchWave: _emitCenterWave,
                      ),
                      _ExampleScreen.blurBench => BenchmarkComparisonScreen(
                        theme: _theme,
                        enableBlurBatching: _enableBlurBatching,
                        panelCount: _benchPanelCount,
                        stressWaves: _stressWaves,
                        onToggleBlurBatching: () {
                          setState(() {
                            _enableBlurBatching = !_enableBlurBatching;
                          });
                        },
                        onSelectPanelCount: (int count) {
                          setState(() {
                            _benchPanelCount = count;
                          });
                        },
                        onToggleStressWaves: () {
                          setState(() {
                            _stressWaves = !_stressWaves;
                          });
                          _syncPulseTimer();
                        },
                        onEmitBurst: _emitRandomWave,
                      ),
                      _ExampleScreen.captureStudio => CaptureStudioScreen(
                        controller: _controller,
                        theme: _theme,
                        onReducedMotionChanged: (bool value) {
                          setState(() {
                            _reducedMotion = value;
                          });
                        },
                      ),
                    },
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
