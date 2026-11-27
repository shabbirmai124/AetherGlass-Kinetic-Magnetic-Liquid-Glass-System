import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../physics/aether_field_controller.dart';

/// Passive raw pointer observer feeding touch coordinates and tracked velocity
/// into [AetherFieldController] without participating in Flutter's gesture arena.
///
/// Child buttons, sliders, and scrollable lists keep receiving gestures
/// normally with zero interference.
class AetherSurfaceListener extends StatefulWidget {
  /// Creates a passive [AetherSurfaceListener] forwarding events to [controller].
  const AetherSurfaceListener({
    super.key,
    required this.controller,
    required this.child,
  });

  /// Spatial physics engine receiving passive pointer coordinates and velocity.
  final AetherFieldController controller;

  /// Subtree whose native taps and scrolling continue uninterrupted.
  final Widget child;

  @override
  State<AetherSurfaceListener> createState() => _AetherSurfaceListenerState();
}

class _AetherSurfaceListenerState extends State<AetherSurfaceListener> {
  final Map<int, VelocityTracker> _trackers = <int, VelocityTracker>{};

  Offset _toStageLocal(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  VelocityTracker _trackerFor(PointerEvent event) {
    return _trackers.putIfAbsent(
      event.pointer,
      () => VelocityTracker.withKind(event.kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        final local = _toStageLocal(event.position);
        _trackerFor(event).addPosition(event.timeStamp, local);
        widget.controller.handlePointerDown(local);
      },
      onPointerMove: (PointerMoveEvent event) {
        final local = _toStageLocal(event.position);
        final tracker = _trackerFor(event);
        tracker.addPosition(event.timeStamp, local);
        final velocity = tracker.getVelocity().pixelsPerSecond;
        widget.controller.handlePointerMove(
          local,
          event.delta,
          trackedVelocity: velocity,
        );
      },
      onPointerHover: (PointerHoverEvent event) {
        widget.controller.handlePointerHover(_toStageLocal(event.position));
      },
      onPointerUp: (PointerUpEvent event) {
        final local = _toStageLocal(event.position);
        final tracker = _trackers.remove(event.pointer);
        final velocity = tracker?.getVelocity().pixelsPerSecond;
        widget.controller.handlePointerUp(local, releaseVelocity: velocity);
      },
      onPointerCancel: (PointerCancelEvent event) {
        _trackers.remove(event.pointer);
        widget.controller.handlePointerCancel();
      },
      child: widget.child,
    );
  }
}
