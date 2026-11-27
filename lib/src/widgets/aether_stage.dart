import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../input/aether_surface_listener.dart';
import '../physics/aether_field_controller.dart';
import '../renderer/aether_field_painter.dart';
import '../renderer/liquid_edge_clipper.dart';
import '../telemetry/aether_telemetry_hud.dart';
import '../theme/aether_presets.dart';
import '../theme/aether_theme_data.dart';
import 'capture_touch_indicator.dart';

/// Inherited notifier scope connecting descendant [AetherGlassCard] and
/// [AetherMagneticButton] widgets to the root [AetherStage].
class AetherStageScope extends InheritedNotifier<AetherFieldController> {
  /// Creates an [AetherStageScope] wrapping [child].
  const AetherStageScope({
    super.key,
    required AetherFieldController controller,
    required this.stageKey,
    required this.enableBlurBatching,
    required this.reducedMotion,
    required this.filterResolver,
    required super.child,
  }) : super(notifier: controller);

  /// Stage key used to convert card bounds into stage-local coordinates.
  final GlobalKey stageKey;

  /// Whether sibling glass panels share a single [BackdropGroup] blur pass.
  final bool enableBlurBatching;

  /// Whether reduced-motion accessibility dampening is active.
  final bool reducedMotion;

  /// Hoisted immutable [ui.ImageFilter] cache resolver keyed by blur sigma.
  final ui.ImageFilter Function(double sigma) filterResolver;

  /// Physics controller exposed by this stage.
  AetherFieldController get controller => notifier!;

  /// Looks up the nearest [AetherStageScope].
  ///
  /// Pass `listen: false` inside stateful glass cards so the card uses its
  /// isolated [ListenableBuilder] rather than rebuilding the enclosing tree.
  static AetherStageScope? maybeOf(
    BuildContext context, {
    bool listen = false,
  }) {
    return listen
        ? context.dependOnInheritedWidgetOfExactType<AetherStageScope>()
        : context.getInheritedWidgetOfExactType<AetherStageScope>();
  }

  @override
  bool updateShouldNotify(covariant AetherStageScope oldWidget) {
    return super.updateShouldNotify(oldWidget) ||
        oldWidget.stageKey != stageKey ||
        oldWidget.enableBlurBatching != enableBlurBatching ||
        oldWidget.reducedMotion != reducedMotion;
  }
}

/// Root container assembling all four pure-Flutter layers of AetherGlass:
/// passive pointer observation, single-Ticker physics, single-pass canvas
/// field rendering, and Impeller [BackdropGroup] blur batching.
class AetherStage extends StatefulWidget {
  /// Creates an [AetherStage] wrapping [child].
  const AetherStage({
    super.key,
    required this.child,
    this.controller,
    this.theme,
    this.enableBlurBatching = true,
    this.paintBackground = true,
    this.autoSleep = true,
    this.animateParticlesWhenIdle = false,
    this.reducedMotion,
    this.showPerformanceHud = false,
    this.hudAlignment = AlignmentDirectional.topEnd,
    this.hudPadding = const EdgeInsetsDirectional.all(12.0),
  });

  /// Interactive foreground UI tree containing cards, buttons, and lists.
  final Widget child;

  /// Optional external [AetherFieldController]. When omitted, one is created
  /// and disposed automatically by this stage.
  final AetherFieldController? controller;

  /// Optional theme override; defaults to [AetherPresets.bioluminescent].
  final AetherThemeData? theme;

  /// Wraps descendant panels in [BackdropGroup] so sibling
  /// [BackdropFilter.grouped] cards share a single Impeller blur pass.
  final bool enableBlurBatching;

  /// Whether [AetherFieldPainter] paints the preset atmospheric gradient.
  final bool paintBackground;

  /// Automatically pauses the central Ticker once physics settle at rest.
  final bool autoSleep;

  /// Keeps ambient motes drifting continuously even without user touch input.
  final bool animateParticlesWhenIdle;

  /// Explicit reduced-motion override. Defaults to OS `disableAnimations` check.
  final bool? reducedMotion;

  /// Displays the live [AetherTelemetryHud] performance overlay.
  final bool showPerformanceHud;

  /// Corner alignment for [AetherTelemetryHud] when visible.
  final AlignmentGeometry hudAlignment;

  /// Outer padding around [AetherTelemetryHud].
  final EdgeInsetsGeometry hudPadding;

  @override
  State<AetherStage> createState() => _AetherStageState();
}

class _AetherStageState extends State<AetherStage>
    with SingleTickerProviderStateMixin {
  static final Map<int, ui.ImageFilter> _hoistedFilterCache =
      <int, ui.ImageFilter>{};

  final GlobalKey _stageKey = GlobalKey(debugLabel: 'AetherStageRoot');
  final BackdropKey _backdropKey = BackdropKey();

  late AetherFieldController _controller;
  late bool _ownsController;
  late Ticker _ticker;
  late AetherFieldPainter _fieldPainter;

  @override
  void initState() {
    super.initState();
    _initController();
    _ticker = createTicker(_onTick);
    if (!_controller.isSleeping) {
      _ticker.start();
    }
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      if (widget.theme != null) {
        _controller.theme = widget.theme!;
      }
    } else {
      _controller = AetherFieldController(
        theme: widget.theme ?? AetherPresets.bioluminescent,
        autoSleep: widget.autoSleep,
        animateParticlesWhenIdle: widget.animateParticlesWhenIdle,
      );
      _ownsController = true;
    }

    _controller.onWakeRequested = _handleWake;
    _controller.onSleepRequested = _handleSleep;
    _fieldPainter = AetherFieldPainter(
      controller: _controller,
      paintBackground: widget.paintBackground,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final osReduced = AetherAdaptiveGeometry.isReducedMotion(context);
    _controller.reducedMotion = widget.reducedMotion ?? osReduced;
  }

  @override
  void didUpdateWidget(covariant AetherStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.onWakeRequested = null;
      _controller.onSleepRequested = null;
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    } else {
      if (widget.theme != null && widget.theme != oldWidget.theme) {
        _controller.theme = widget.theme!;
      }
      if (widget.paintBackground != oldWidget.paintBackground) {
        _fieldPainter = AetherFieldPainter(
          controller: _controller,
          paintBackground: widget.paintBackground,
        );
      }
    }

    final osReduced = AetherAdaptiveGeometry.isReducedMotion(context);
    _controller.reducedMotion = widget.reducedMotion ?? osReduced;
  }

  void _handleWake() {
    if (mounted && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _handleSleep() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    _controller.step(elapsed);
  }

  static ui.ImageFilter _resolveHoistedBlur(double sigma) {
    final safeSigma = sigma.clamp(0.0, 40.0);
    final key = (safeSigma * 10.0).round();
    return _hoistedFilterCache.putIfAbsent(
      key,
      () => ui.ImageFilter.blur(sigmaX: key / 10.0, sigmaY: key / 10.0),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (_controller.onWakeRequested == _handleWake) {
      _controller.onWakeRequested = null;
    }
    if (_controller.onSleepRequested == _handleSleep) {
      _controller.onSleepRequested = null;
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        widget.reducedMotion ?? AetherAdaptiveGeometry.isReducedMotion(context);

    Widget content = widget.child;
    if (widget.enableBlurBatching) {
      content = BackdropGroup(backdropKey: _backdropKey, child: content);
    }

    return AetherStageScope(
      controller: _controller,
      stageKey: _stageKey,
      enableBlurBatching: widget.enableBlurBatching,
      reducedMotion: reducedMotion,
      filterResolver: _resolveHoistedBlur,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
            _controller.setViewportSize(constraints.biggest);
          }

          return AetherSurfaceListener(
            controller: _controller,
            child: Stack(
              key: _stageKey,
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _fieldPainter,
                      isComplex: true,
                      willChange: true,
                    ),
                  ),
                ),
                content,
                Positioned.fill(
                  child: CaptureTouchIndicator(controller: _controller),
                ),
                if (widget.showPerformanceHud)
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: widget.hudPadding,
                        child: Align(
                          alignment: widget.hudAlignment,
                          child: AetherTelemetryHud(
                            controller: _controller,
                            blurBatched: widget.enableBlurBatching,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
