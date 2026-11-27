import 'package:flutter/services.dart';

/// Cooldown-guarded micro-haptic pulse dispatcher preventing rapid vibration
/// spam during continuous drags while synchronizing peak magnetic feedback.
final class HapticPulseGuard {
  /// Creates a [HapticPulseGuard] enforcing [cooldown] between triggers.
  HapticPulseGuard({
    this.cooldown = const Duration(milliseconds: 60),
    void Function()? onSelectionClick,
    void Function()? onLightImpact,
    DateTime Function()? clock,
  })  : _onSelectionClick = onSelectionClick ?? HapticFeedback.selectionClick,
        _onLightImpact = onLightImpact ?? HapticFeedback.lightImpact,
        _clock = clock ?? DateTime.now;

  /// Minimum interval required between consecutive tactile triggers.
  Duration cooldown;

  final void Function() _onSelectionClick;
  final void Function() _onLightImpact;
  final DateTime Function() _clock;

  DateTime _lastTriggeredAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _triggerCount = 0;

  /// Total tactile pulses successfully emitted after passing cooldown checks.
  int get triggerCount => _triggerCount;

  /// Triggers a subtle selection click when magnetic stretch hits threshold.
  ///
  /// Returns `true` if the pulse fired or `false` if suppressed by [cooldown]
  /// or [enabled] being false.
  bool triggerSelection({required bool enabled}) {
    return _dispatch(enabled: enabled, callback: _onSelectionClick);
  }

  /// Triggers a soft impact pulse when releasing an energetic swipe or button.
  bool triggerImpact({required bool enabled}) {
    return _dispatch(enabled: enabled, callback: _onLightImpact);
  }

  bool _dispatch({
    required bool enabled,
    required void Function() callback,
  }) {
    if (!enabled) {
      return false;
    }
    final now = _clock();
    if (now.difference(_lastTriggeredAt) < cooldown) {
      return false;
    }
    _lastTriggeredAt = now;
    _triggerCount++;
    callback();
    return true;
  }
}
