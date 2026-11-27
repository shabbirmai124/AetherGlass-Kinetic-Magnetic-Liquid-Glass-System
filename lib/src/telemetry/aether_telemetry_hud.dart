import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';
import 'frame_metrics_tracker.dart';

/// Toggleable live performance HUD overlay displaying rolling FPS, UI/GPU
/// frame times, p50/p90 budgets, object pool usage, and Ticker sleep status.
class AetherTelemetryHud extends StatefulWidget {
  /// Creates an [AetherTelemetryHud] observing [controller].
  const AetherTelemetryHud({
    super.key,
    required this.controller,
    this.blurBatched = true,
    this.compact = false,
  });

  /// Centralized physics engine observed by this HUD.
  final AetherFieldController controller;

  /// Indicates whether Impeller [BackdropGroup] batching is active.
  final bool blurBatched;

  /// Renders a slightly narrower footprint for mobile/compact views.
  final bool compact;

  @override
  State<AetherTelemetryHud> createState() => _AetherTelemetryHudState();
}

class _AetherTelemetryHudState extends State<AetherTelemetryHud> {
  late FrameMetricsTracker _tracker;

  @override
  void initState() {
    super.initState();
    _tracker = FrameMetricsTracker(
      controller: widget.controller,
      blurBatched: widget.blurBatched,
    )..start();
  }

  @override
  void didUpdateWidget(covariant AetherTelemetryHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _tracker.dispose();
      _tracker = FrameMetricsTracker(
        controller: widget.controller,
        blurBatched: widget.blurBatched,
      )..start();
    } else {
      _tracker.blurBatched = widget.blurBatched;
    }
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: _tracker,
        builder: (BuildContext context, Widget? _) {
          final snap = _tracker.snapshot;
          final theme = widget.controller.theme;
          final statusColor = snap.isSleeping
              ? const Color(0xFF34D399)
              : theme.ripplePrimaryColor;
          final budgetHealthy = snap.p90Millis <= 8.33 || snap.sampleCount == 0;
          final fpsColor = budgetHealthy
              ? const Color(0xFF34D399)
              : (snap.p90Millis <= 16.67
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFF87171));

          return Container(
            constraints: BoxConstraints(
              maxWidth: widget.compact ? 256.0 : 320.0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xCC060A12),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: theme.glassBorderColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.0,
                height: 1.35,
                color: Color(0xFFE2E8F0),
                decoration: TextDecoration.none,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        'AETHER HUD',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: theme.specularColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          snap.isSleeping ? 'SLEEPING' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 2.0,
                    children: <Widget>[
                      Text(
                        'FPS ${snap.fps.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: fpsColor,
                        ),
                      ),
                      Text(
                        'UI ${snap.uiMillis.toStringAsFixed(1)}ms • GPU ${snap.rasterMillis.toStringAsFixed(1)}ms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'p50 ${snap.p50Millis.toStringAsFixed(1)}ms  •  p90 ${snap.p90Millis.toStringAsFixed(1)}ms',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Waves ${snap.activeRipples}/${snap.maxRipples}  •  Motes ${snap.moteCount}  •  Cards ${snap.registeredCards}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Blur: ${snap.blurBatched ? "BackdropGroup (Batched)" : "Ungrouped (Stacked)"}',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: snap.blurBatched
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
