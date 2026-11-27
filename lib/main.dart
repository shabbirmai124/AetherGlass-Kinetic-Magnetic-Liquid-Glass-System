import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'aether_glass.dart';

/// Launches the interactive AetherGlass showcase application.
void main() {
  runApp(const AetherShowcaseApp());
}

enum _ShowcaseView { dashboard, blurBench }

/// Pure-Flutter showcase application demonstrating the AetherGlass kinetic
/// liquid-glass rendering and spatial physics engine.
class AetherShowcaseApp extends StatefulWidget {
  /// Creates an [AetherShowcaseApp].
  const AetherShowcaseApp({super.key});

  @override
  State<AetherShowcaseApp> createState() => _AetherShowcaseAppState();
}

class _AetherShowcaseAppState extends State<AetherShowcaseApp> {
  late final AetherFieldController _controller;
  final math.Random _random = math.Random(42);

  AetherThemeData _theme = AetherPresets.bioluminescent;
  _ShowcaseView _view = _ShowcaseView.dashboard;
  bool _enableBlurBatching = true;
  bool _reducedMotion = false;
  bool _showPerformanceHud = true;
  bool _stressWaves = false;
  int _panelCount = 12;
  Timer? _waveTimer;

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
    _waveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncWaveTimer() {
    _waveTimer?.cancel();
    if (!_stressWaves) {
      return;
    }
    _waveTimer = Timer.periodic(
      const Duration(milliseconds: 650),
      (_) => _emitWave(randomOrigin: true),
    );
  }

  void _emitWave({bool randomOrigin = false}) {
    final size = _controller.viewportSize;
    final origin = randomOrigin
        ? Offset(
            size.width * (0.18 + _random.nextDouble() * 0.64),
            size.height * (0.20 + _random.nextDouble() * 0.60),
          )
        : Offset(size.width * 0.5, size.height * 0.42);
    _controller.emitRipple(
      origin: origin,
      maxRadius: math.max(size.longestSide * 0.65, 420.0),
      intensity: 0.96,
      strokeWidth: 3.4,
      kind: AetherRippleKind.pulse,
    );
  }

  void _selectPreset(AetherPreset preset) {
    final next = AetherPresets.fromPreset(preset);
    setState(() {
      _theme = next;
    });
    _controller.theme = next;
    _emitWave();
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? swatch,
  }) {
    final accent = _theme.ripplePrimaryColor;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 13.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.20)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(13.0),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.88)
                  : const Color(0x2EFFFFFF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (swatch != null) ...<Widget>[
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatch,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
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

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'AetherGlass',
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
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8.0,
                              children: <Widget>[
                                _chip(
                                  label: 'Dashboard',
                                  active: _view == _ShowcaseView.dashboard,
                                  onTap: () {
                                    setState(() {
                                      _view = _ShowcaseView.dashboard;
                                    });
                                    _emitWave();
                                  },
                                ),
                                _chip(
                                  label: 'Blur Bench',
                                  active: _view == _ShowcaseView.blurBench,
                                  onTap: () {
                                    setState(() {
                                      _view = _ShowcaseView.blurBench;
                                    });
                                    _emitWave();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final wide = constraints.maxWidth >= 820.0;
                            return SingleChildScrollView(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                20.0,
                                12.0,
                                20.0,
                                32.0,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1120.0,
                                  ),
                                  child: _view == _ShowcaseView.dashboard
                                      ? _buildDashboard(wide)
                                      : _buildBlurBench(constraints.maxWidth),
                                ),
                              ),
                            );
                          },
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

  Widget _buildDashboard(bool wide) {
    final metrics = <(String, String, String)>[
      (
        'SPRING SOLVER',
        '${_theme.stiffness.toStringAsFixed(0)} N/m',
        'Symplectic 240Hz substep • c=${_theme.damping.toStringAsFixed(1)}',
      ),
      (
        'ZERO-ALLOC POOLS',
        '${_controller.maxRipples} Waves • ${_controller.particleCount} Motes',
        '${_controller.maxTrailPoints}-pt wake ribbon ring buffer',
      ),
      (
        'IMPELLER BLUR',
        _enableBlurBatching ? 'BackdropGroup' : 'Naive Stacked',
        _enableBlurBatching
            ? 'Shared single-pass blur (σ=${_theme.blurSigma.toStringAsFixed(1)})'
            : 'Per-card backdrop blur passes',
      ),
      (
        'SURFACE GEOMETRY',
        '${_theme.edgeFlexDistance.toStringAsFixed(1)} px Flex',
        'Hardware corner adaptation • ±7° 3D tilt cap',
      ),
    ];

    Widget buildCard((String, String, String) m) {
      return AetherGlassCard(
        padding: const EdgeInsetsDirectional.all(22.0),
        onTap: _emitWave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              m.$1,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _theme.specularColor,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              m.$2,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              m.$3,
              style: TextStyle(
                fontSize: 13.0,
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.74),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
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
                      'AETHERGLASS • 100% PURE-DART KINETIC ENGINE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _theme.specularColor,
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
                      'Single-Ticker spatial physics, zero-allocation object pools, Bezier surface tension, and Impeller BackdropGroup batching — authored by Md Shabbir Mia.',
                      style: TextStyle(
                        fontSize: 14.0,
                        height: 1.45,
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: <Widget>[
                        for (final preset in AetherPresets.all)
                          _chip(
                            label: preset.name,
                            active: _theme.preset == preset.preset,
                            swatch: preset.ripplePrimaryColor,
                            onTap: () => _selectPreset(preset.preset),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: wide ? 24.0 : 0.0, height: wide ? 0.0 : 18.0),
              AetherMagneticButton(
                semanticLabel: 'Launch Kinetic Wave',
                onPressed: _emitWave,
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
        if (wide) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(child: buildCard(metrics[0])),
              const SizedBox(width: 16.0),
              Expanded(child: buildCard(metrics[1])),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: <Widget>[
              Expanded(child: buildCard(metrics[2])),
              const SizedBox(width: 16.0),
              Expanded(child: buildCard(metrics[3])),
            ],
          ),
        ] else
          for (var i = 0; i < metrics.length; i++) ...<Widget>[
            buildCard(metrics[i]),
            if (i < metrics.length - 1) const SizedBox(height: 14.0),
          ],
        const SizedBox(height: 18.0),
        AetherGlassCard(
          padding: const EdgeInsetsDirectional.all(20.0),
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: <Widget>[
              _chip(
                label: 'BackdropGroup',
                active: _enableBlurBatching,
                onTap: () {
                  setState(() {
                    _enableBlurBatching = !_enableBlurBatching;
                  });
                },
              ),
              _chip(
                label: 'Reduced Motion',
                active: _reducedMotion,
                onTap: () {
                  setState(() {
                    _reducedMotion = !_reducedMotion;
                  });
                },
              ),
              _chip(
                label: 'Telemetry HUD',
                active: _showPerformanceHud,
                onTap: () {
                  setState(() {
                    _showPerformanceHud = !_showPerformanceHud;
                  });
                },
              ),
              _chip(
                label: 'Touch Marker',
                active: _controller.showTouchIndicator,
                onTap: () {
                  setState(() {
                    _controller.showTouchIndicator =
                        !_controller.showTouchIndicator;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlurBench(double width) {
    final columns = width >= 900.0 ? 4 : (width >= 600.0 ? 3 : 2);
    final rows = (_panelCount / columns).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AetherGlassCard(
          padding: const EdgeInsetsDirectional.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'IMPELLER BLUR BATCHING BENCHMARK',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _theme.specularColor,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _enableBlurBatching
                    ? 'Mode: BackdropGroup (1 Shared Pass)'
                    : 'Mode: Naive Stacked ($_panelCount Individual Passes)',
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
                children: <Widget>[
                  _chip(
                    label: _enableBlurBatching
                        ? 'BackdropGroup ON'
                        : 'Naive Stacked',
                    active: _enableBlurBatching,
                    onTap: () {
                      setState(() {
                        _enableBlurBatching = !_enableBlurBatching;
                      });
                    },
                  ),
                  _chip(
                    label: 'Run Stress Waves',
                    active: _stressWaves,
                    onTap: () {
                      setState(() {
                        _stressWaves = !_stressWaves;
                      });
                      _syncWaveTimer();
                    },
                  ),
                  for (final count in const <int>[6, 12, 24])
                    _chip(
                      label: '$count Panels',
                      active: _panelCount == count,
                      onTap: () {
                        setState(() {
                          _panelCount = count;
                        });
                      },
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
                  child: (r * columns + c) < _panelCount
                      ? AetherGlassCard(
                          padding: const EdgeInsetsDirectional.all(16.0),
                          onTap: () => _emitWave(randomOrigin: true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'PANEL ${(r * columns + c + 1).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: _theme.specularColor,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                _enableBlurBatching
                                    ? 'Grouped Blur'
                                    : 'Isolated Blur',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (c < columns - 1) const SizedBox(width: 12.0),
              ],
            ],
          ),
          if (r < rows - 1) const SizedBox(height: 12.0),
        ],
      ],
    );
  }
}
