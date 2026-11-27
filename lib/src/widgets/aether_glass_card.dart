import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';
import '../renderer/liquid_edge_clipper.dart';
import '../renderer/specular_rim_painter.dart';
import '../theme/aether_presets.dart';
import '../theme/aether_theme_data.dart';
import 'aether_stage.dart';

/// A frosted liquid-glass surface that flexes its Bezier borders magnetically
/// toward touches, tilts in 3D when kinetic ripples pass beneath it, and
/// batches Gaussian backdrop blurs via Impeller's [BackdropGroup].
class AetherGlassCard extends StatefulWidget {
  /// Creates an [AetherGlassCard] wrapping [child].
  const AetherGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.borderRadius,
    this.adaptToDisplayCorners = true,
    this.blurSigma,
    this.tintColor,
    this.onTap,
    this.tiltStrength = 1.0,
    this.flexStrength = 1.0,
    this.enableBlur = true,
    this.maxMagneticOffset = 0.0,
    this.rimStrokeWidth,
    this.semanticLabel,
  });

  /// Static inner widget tree isolated inside a [RepaintBoundary] so frame
  /// animations never rebuild or repaint text and icons.
  final Widget child;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  /// Custom corner radii. When `null` and [adaptToDisplayCorners] is `true`,
  /// radii adapt automatically to the device's physical `displayCornerRadii`.
  final BorderRadius? borderRadius;

  /// Whether to harmonize corner curvature with hardware `displayCornerRadii`.
  final bool adaptToDisplayCorners;

  /// Optional blur sigma override; defaults to [AetherThemeData.blurSigma].
  final double? blurSigma;

  /// Optional frosted tint override; defaults to [AetherThemeData.glassTintColor].
  final Color? tintColor;

  /// Optional tap handler compatible with passive stage pointer observation.
  final VoidCallback? onTap;

  /// Multiplier applied to 3D perspective tilting (`0.0` disables tilt).
  final double tiltStrength;

  /// Multiplier applied to magnetic Bezier edge flexing (`0.0` keeps flat sides).
  final double flexStrength;

  /// Enables frosted backdrop blur inside the deformed liquid-glass silhouette.
  final bool enableBlur;

  /// Maximum magnetic translation offset in logical pixels (`0.0` for cards).
  final double maxMagneticOffset;

  /// Optional stroke width override for the specular rim (`1.2` px default).
  final double? rimStrokeWidth;

  /// Optional semantic description for screen readers.
  final String? semanticLabel;

  @override
  State<AetherGlassCard> createState() => _AetherGlassCardState();
}

class _AetherGlassCardState extends State<AetherGlassCard> {
  final Object _cardToken = Object();

  AetherStageScope? _scope;
  AetherFieldController? _controller;
  AetherCardForceState? _forceState;
  ScrollPosition? _scrollPosition;
  bool _boundsScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = AetherStageScope.maybeOf(context, listen: false);
    final nextController = nextScope?.controller;
    if (!identical(_controller, nextController)) {
      _controller?.unregisterCard(_cardToken);
      _controller = nextController;
      _forceState = null;
    }
    _scope = nextScope;

    final nextScroll = Scrollable.maybeOf(context)?.position;
    if (!identical(_scrollPosition, nextScroll)) {
      _scrollPosition?.removeListener(_scheduleBoundsSync);
      _scrollPosition = nextScroll;
      _scrollPosition?.addListener(_scheduleBoundsSync);
    }

    _scheduleBoundsSync();
  }

  @override
  void didUpdateWidget(covariant AetherGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maxMagneticOffset != oldWidget.maxMagneticOffset &&
        _forceState != null) {
      _forceState!.maxMagneticOffset = widget.maxMagneticOffset;
    }
    _scheduleBoundsSync();
  }

  void _scheduleBoundsSync() {
    if (_boundsScheduled || _controller == null) {
      return;
    }
    _boundsScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _boundsScheduled = false;
      if (mounted) {
        _syncBounds();
      }
    });
  }

  void _syncBounds() {
    final controller = _controller;
    final scope = _scope;
    if (controller == null || scope == null) {
      return;
    }
    final cardRender = context.findRenderObject();
    final stageRender = scope.stageKey.currentContext?.findRenderObject();
    if (cardRender is! RenderBox || !cardRender.hasSize) {
      return;
    }
    final Offset topLeft;
    if (stageRender is RenderBox && stageRender.hasSize) {
      final globalTopLeft = cardRender.localToGlobal(Offset.zero);
      topLeft = stageRender.globalToLocal(globalTopLeft);
    } else {
      topLeft = cardRender.localToGlobal(Offset.zero);
    }
    final bounds = topLeft & cardRender.size;
    _forceState = controller.registerCard(
      _cardToken,
      bounds,
      maxMagneticOffset: widget.maxMagneticOffset,
    );
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleBoundsSync);
    _controller?.unregisterCard(_cardToken);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AetherStageScope.maybeOf(context, listen: true);
    final controller = _controller ?? scope?.controller;
    final resolvedRadius = widget.borderRadius ??
        (widget.adaptToDisplayCorners
            ? AetherAdaptiveGeometry.resolveCardRadius(context)
            : const BorderRadius.all(Radius.circular(24.0)));

    final isolatedContent = RepaintBoundary(
      child: Padding(
        padding: widget.padding,
        child: widget.child,
      ),
    );

    if (scope == null || controller == null) {
      return _buildStaticFallback(context, resolvedRadius, isolatedContent);
    }

    Widget result = RepaintBoundary(
      child: ListenableBuilder(
        listenable: controller,
        child: isolatedContent,
        builder: (BuildContext context, Widget? cachedChild) {
          final theme = controller.theme;
          final state = _forceState ?? controller.cardStateFor(_cardToken);
          final reduced = scope.reducedMotion;

          final tiltX = (state?.tiltX.value ?? 0.0) * widget.tiltStrength;
          final tiltY = (state?.tiltY.value ?? 0.0) * widget.tiltStrength;
          final depression = state?.depression.value ?? 0.0;
          final edgePull = state == null
              ? Offset.zero
              : Offset(state.edgePullX.value, state.edgePullY.value);
          final hoverGlow = state?.hoverGlow.value ?? 0.0;
          final specularAlign = state == null
              ? const Offset(-0.55, -0.55)
              : Offset(state.specularAlignX, state.specularAlignY);
          final tx = state?.offsetX.value ?? 0.0;
          final ty = state?.offsetY.value ?? 0.0;

          final scale = (1.0 - depression * (reduced ? 0.01 : 0.032))
              .clamp(0.92, 1.03);
          final flexAmount =
              (reduced ? 0.0 : theme.edgeFlexDistance) * widget.flexStrength;

          final matrix = Matrix4.translationValues(tx, ty, 0.0)
            ..setEntry(3, 2, 0.0012)
            ..rotateX(tiltX)
            ..rotateY(tiltY)
            ..scaleByDouble(scale, scale, 1.0, 1.0);

          final baseTint = widget.tintColor ?? theme.glassTintColor;
          final dynamicAlpha =
              (baseTint.a + hoverGlow * 0.06).clamp(0.0, 0.65);
          final effectiveTint = baseTint.withValues(alpha: dynamicAlpha);

          final sigma = widget.blurSigma ?? theme.blurSigma;
          final shouldBlur = widget.enableBlur && sigma > 0.05;
          final filter =
              shouldBlur ? scope.filterResolver(sigma) : null;
          final rimStroke = widget.rimStrokeWidth ?? theme.specularRimStroke;

          Widget glassCore = CustomPaint(
            foregroundPainter: SpecularRimPainter(
              borderRadius: resolvedRadius,
              edgePull: edgePull,
              flexAmount: flexAmount,
              specularAlign: specularAlign,
              hoverGlow: hoverGlow,
              baseBorderColor: theme.glassBorderColor,
              specularColor: theme.specularColor,
              specularIntensity: theme.specularIntensity,
              strokeWidth: rimStroke,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: effectiveTint),
              child: cachedChild,
            ),
          );

          if (filter != null) {
            glassCore = scope.enableBlurBatching
                ? BackdropFilter.grouped(
                    filter: filter,
                    child: glassCore,
                  )
                : BackdropFilter(
                    filter: filter,
                    child: glassCore,
                  );
          }

          Widget cardBody = Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: ClipPath(
              clipper: LiquidEdgeClipper(
                borderRadius: resolvedRadius,
                edgePull: edgePull,
                flexAmount: flexAmount,
              ),
              child: glassCore,
            ),
          );

          if (widget.onTap != null) {
            cardBody = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: cardBody,
            );
          }

          return cardBody;
        },
      ),
    );

    if (widget.semanticLabel != null) {
      result = Semantics(
        container: true,
        label: widget.semanticLabel,
        child: result,
      );
    }

    return result;
  }

  Widget _buildStaticFallback(
    BuildContext context,
    BorderRadius resolvedRadius,
    Widget isolatedContent,
  ) {
    const fallbackTheme = AetherPresets.bioluminescent;
    final sigma = widget.blurSigma ?? fallbackTheme.blurSigma;
    final tint = widget.tintColor ?? fallbackTheme.glassTintColor;
    final stroke = widget.rimStrokeWidth ?? fallbackTheme.specularRimStroke;

    Widget core = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: fallbackTheme.glassBorderColor,
          width: math.max(stroke, 1.0),
        ),
      ),
      child: isolatedContent,
    );

    if (widget.enableBlur && sigma > 0.05) {
      core = ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: _fallbackFilter(sigma),
          child: core,
        ),
      );
    }

    if (widget.onTap != null) {
      core = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: core,
      );
    }
    return RepaintBoundary(child: core);
  }

  static final Map<int, ui.ImageFilter> _fallbackFilterCache =
      <int, ui.ImageFilter>{};

  static ui.ImageFilter _fallbackFilter(double sigma) {
    final key = (sigma.clamp(0.0, 40.0) * 10.0).round();
    return _fallbackFilterCache.putIfAbsent(
      key,
      () => ui.ImageFilter.blur(
        sigmaX: key / 10.0,
        sigmaY: key / 10.0,
      ),
    );
  }
}
