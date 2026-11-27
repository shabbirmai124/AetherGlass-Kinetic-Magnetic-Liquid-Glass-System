import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../physics/ripple_wave_pool.dart';
import 'aether_glass_card.dart';
import 'aether_stage.dart';

/// Elastic liquid-glass action button that meets the `>= 48x48` logical pixel
/// accessibility touch target, supports keyboard focus/activation, stretches
/// up to [maxMagneticPull] logical pixels (10.0 px default) toward an
/// off-center drag, triggers a cooldown-guarded haptic click on snap
/// threshold, and launches a release ripple.
class AetherMagneticButton extends StatefulWidget {
  /// Creates an [AetherMagneticButton].
  const AetherMagneticButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: 24.0,
      vertical: 14.0,
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(28.0)),
    this.maxMagneticPull = 10.0,
    this.tintColor,
    this.blurSigma,
    this.semanticLabel,
    this.enableBlur = true,
    this.focusNode,
  });

  /// Label or icon content inside the magnetic glass button.
  final Widget child;

  /// Callback invoked when the button is tapped or activated; `null` disables it.
  final VoidCallback? onPressed;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  /// Rounded pill/button border radius.
  final BorderRadius borderRadius;

  /// Maximum magnetic translation offset toward the pointer (default 10.0 px).
  final double maxMagneticPull;

  /// Optional frosted tint override.
  final Color? tintColor;

  /// Optional blur sigma override.
  final double? blurSigma;

  /// Accessibility label announced for screen readers.
  final String? semanticLabel;

  /// Enables frosted backdrop blur inside the magnetic button.
  final bool enableBlur;

  /// Optional [FocusNode] for keyboard navigation and focus control.
  final FocusNode? focusNode;

  @override
  State<AetherMagneticButton> createState() => _AetherMagneticButtonState();
}

class _AetherMagneticButtonState extends State<AetherMagneticButton> {
  static const Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      };

  bool _isFocused = false;

  void _handleReleaseTap() {
    final onPressed = widget.onPressed;
    if (onPressed == null) {
      return;
    }

    final scope = AetherStageScope.maybeOf(context, listen: false);
    final renderBox = context.findRenderObject();
    if (scope != null && renderBox is RenderBox && renderBox.hasSize) {
      final stageRender = scope.stageKey.currentContext?.findRenderObject();
      final globalCenter = renderBox.localToGlobal(
        renderBox.size.center(Offset.zero),
      );
      final stageCenter = (stageRender is RenderBox && stageRender.hasSize)
          ? stageRender.globalToLocal(globalCenter)
          : globalCenter;

      scope.controller.emitRipple(
        origin: stageCenter,
        maxRadius: 340.0,
        speed: scope.controller.theme.waveSpeed * 1.12,
        intensity: 0.95,
        strokeWidth: 3.4,
        kind: AetherRippleKind.release,
      );
      scope.controller.hapticGuard.triggerImpact(
        enabled: scope.controller.theme.enableHaptics && !scope.reducedMotion,
      );
    }

    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scope = AetherStageScope.maybeOf(context, listen: false);
    final rimStroke = scope?.controller.theme.specularRimStroke ?? 1.2;
    final focusColor =
        scope?.controller.theme.specularColor ?? const Color(0xD95EEAD4);

    return FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      shortcuts: _shortcuts,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            _handleReleaseTap();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (ButtonActivateIntent _) {
            _handleReleaseTap();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (bool focused) {
        if (_isFocused != focused) {
          setState(() {
            _isFocused = focused;
          });
        }
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        focused: _isFocused,
        label: widget.semanticLabel,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: _isFocused
                  ? Border.all(color: focusColor, width: 2.0)
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 48.0,
                minHeight: 48.0,
              ),
              child: AetherGlassCard(
                padding: widget.padding,
                borderRadius: widget.borderRadius,
                adaptToDisplayCorners: false,
                tintColor: widget.tintColor,
                blurSigma: widget.blurSigma,
                enableBlur: widget.enableBlur,
                maxMagneticOffset: enabled ? widget.maxMagneticPull : 0.0,
                tiltStrength: enabled ? 1.1 : 0.0,
                flexStrength: enabled ? 1.15 : 0.0,
                rimStrokeWidth: rimStroke + (_isFocused ? 0.65 : 0.25),
                onTap: enabled ? _handleReleaseTap : null,
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
