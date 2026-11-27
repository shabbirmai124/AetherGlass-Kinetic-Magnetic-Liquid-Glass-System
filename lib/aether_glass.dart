/// Zero-dependency pure-Flutter kinetic liquid-glass UI and spatial physics
/// rendering engine.
///
/// Exported layers:
/// - **Physics:** [SpringSolver], [AetherSpringState], [RippleWavePool],
///   [AetherRipple], [AetherRippleKind], [AmbientMotePool], [AetherMote],
///   [WakeTrailBuffer], [AetherTrailPoint], [AetherCardForceState],
///   [AetherFieldController].
/// - **Theme:** [AetherThemeData], [AetherPresets], [AetherPreset].
/// - **Input:** [AetherSurfaceListener], [HapticPulseGuard].
/// - **Renderer:** [AetherFieldPainter], [LiquidEdgeClipper],
///   [SpecularRimPainter], [AetherAdaptiveGeometry].
/// - **Telemetry:** [FrameMetricsTracker], [AetherTelemetrySnapshot],
///   [AetherTelemetryHud].
/// - **Widgets:** [AetherStage], [AetherStageScope], [AetherGlassCard],
///   [AetherMagneticButton], [CaptureTouchIndicator].
library;

export 'src/input/aether_surface_listener.dart';
export 'src/input/haptic_pulse_guard.dart';
export 'src/physics/aether_field_controller.dart';
export 'src/physics/ambient_mote_pool.dart';
export 'src/physics/ripple_wave_pool.dart';
export 'src/physics/spring_solver.dart';
export 'src/physics/wake_trail_buffer.dart';
export 'src/renderer/aether_field_painter.dart';
export 'src/renderer/liquid_edge_clipper.dart';
export 'src/renderer/specular_rim_painter.dart';
export 'src/telemetry/aether_telemetry_hud.dart';
export 'src/telemetry/frame_metrics_tracker.dart';
export 'src/theme/aether_presets.dart';
export 'src/theme/aether_theme_data.dart';
export 'src/widgets/aether_glass_card.dart';
export 'src/widgets/aether_magnetic_button.dart';
export 'src/widgets/aether_stage.dart';
export 'src/widgets/capture_touch_indicator.dart';
