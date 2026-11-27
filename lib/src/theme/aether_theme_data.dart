import 'package:flutter/widgets.dart';

/// Built-in visual and physics personality identifiers for AetherGlass.
enum AetherPreset {
  /// Abyss navy backdrop, cyan-teal glass glow, emerald ripples, silky float.
  bioluminescent,

  /// Matte charcoal backdrop, smoked glass cards, crisp silver rims, snappy.
  obsidianFrost,

  /// Deep dark bronze backdrop, golden specular sheen, ember motes, elastic.
  solarAmber,
}

/// Immutable configuration defining spring constants, wave optics, and
/// color palette for an [AetherStage].
@immutable
class AetherThemeData {
  /// Creates an [AetherThemeData] instance with enterprise defaults aligned to
  /// 120Hz Impeller budgets.
  const AetherThemeData({
    required this.preset,
    required this.name,
    this.stiffness = 260.0,
    this.damping = 18.0,
    this.pointerStiffness = 280.0,
    this.pointerDamping = 24.0,
    this.blurSigma = 12.0,
    this.maxTiltRadians = 0.12217,
    this.edgeFlexDistance = 8.0,
    this.activationRadius = 140.0,
    this.waveSpeed = 520.0,
    this.wavefrontBand = 40.0,
    this.specularRimStroke = 1.2,
    this.specularIntensity = 0.85,
    this.enableHaptics = true,
    this.hapticCooldown = const Duration(milliseconds: 60),
    required this.backgroundColors,
    required this.glassTintColor,
    required this.glassBorderColor,
    required this.specularColor,
    required this.ripplePrimaryColor,
    required this.rippleSecondaryColor,
    required this.particlePrimaryColor,
    required this.particleSecondaryColor,
    required this.ribbonStartColor,
    required this.ribbonEndColor,
  });

  /// Preset personality identifier.
  final AetherPreset preset;

  /// Human-readable preset display name.
  final String name;

  /// Spring stiffness coefficient for card tilt, depression, and Bezier edge flex.
  final double stiffness;

  /// Spring damping coefficient controlling overshoot decay.
  final double damping;

  /// Spring stiffness for the trailing pointer magnet.
  final double pointerStiffness;

  /// Spring damping for the trailing pointer magnet.
  final double pointerDamping;

  /// Hoisted Gaussian backdrop blur sigma applied uniformly across grouped cards.
  final double blurSigma;

  /// Maximum 3D rotation angle in radians along X/Y axes (7.0 deg = 0.12217 rad).
  final double maxTiltRadians;

  /// Maximum Bezier midpoint flex distance in logical pixels (default 8.0 px).
  final double edgeFlexDistance;

  /// Magnetic edge activation radius around each card in logical pixels (140 px).
  final double activationRadius;

  /// Kinetic ripple wave propagation speed in logical pixels per second (520 px/s).
  final double waveSpeed;

  /// Active wavefront band width in logical pixels (40 px).
  final double wavefrontBand;

  /// Specular glass rim stroke width in logical pixels (1.2 px).
  final double specularRimStroke;

  /// Specular rim and inner refraction sheen brightness multiplier `[0.0, 1.0]`.
  final double specularIntensity;

  /// Whether micro-haptics trigger when magnetic stretch hits threshold.
  final bool enableHaptics;

  /// Cooldown enforced between consecutive haptic pulses (default 60 ms).
  final Duration hapticCooldown;

  /// Atmospheric multi-stop background gradient colors.
  final List<Color> backgroundColors;

  /// Frosted glass core tint (`10%–14%` opacity).
  final Color glassTintColor;

  /// Subtle resting glass edge stroke color.
  final Color glassBorderColor;

  /// Highlight color for the pointer-tracking glossy rim and surface sheen.
  final Color specularColor;

  /// Primary expanding kinetic ripple stroke color.
  final Color ripplePrimaryColor;

  /// Secondary outer halo color for expanding energy waves.
  final Color rippleSecondaryColor;

  /// Primary ambient mote color.
  final Color particlePrimaryColor;

  /// Secondary ambient mote color.
  final Color particleSecondaryColor;

  /// Leading head color of the 14-point wake ribbon.
  final Color ribbonStartColor;

  /// Trailing tail color of the wake ribbon.
  final Color ribbonEndColor;

  /// Returns a copy with selective parameter overrides.
  AetherThemeData copyWith({
    AetherPreset? preset,
    String? name,
    double? stiffness,
    double? damping,
    double? pointerStiffness,
    double? pointerDamping,
    double? blurSigma,
    double? maxTiltRadians,
    double? edgeFlexDistance,
    double? activationRadius,
    double? waveSpeed,
    double? wavefrontBand,
    double? specularRimStroke,
    double? specularIntensity,
    bool? enableHaptics,
    Duration? hapticCooldown,
    List<Color>? backgroundColors,
    Color? glassTintColor,
    Color? glassBorderColor,
    Color? specularColor,
    Color? ripplePrimaryColor,
    Color? rippleSecondaryColor,
    Color? particlePrimaryColor,
    Color? particleSecondaryColor,
    Color? ribbonStartColor,
    Color? ribbonEndColor,
  }) {
    return AetherThemeData(
      preset: preset ?? this.preset,
      name: name ?? this.name,
      stiffness: stiffness ?? this.stiffness,
      damping: damping ?? this.damping,
      pointerStiffness: pointerStiffness ?? this.pointerStiffness,
      pointerDamping: pointerDamping ?? this.pointerDamping,
      blurSigma: blurSigma ?? this.blurSigma,
      maxTiltRadians: maxTiltRadians ?? this.maxTiltRadians,
      edgeFlexDistance: edgeFlexDistance ?? this.edgeFlexDistance,
      activationRadius: activationRadius ?? this.activationRadius,
      waveSpeed: waveSpeed ?? this.waveSpeed,
      wavefrontBand: wavefrontBand ?? this.wavefrontBand,
      specularRimStroke: specularRimStroke ?? this.specularRimStroke,
      specularIntensity: specularIntensity ?? this.specularIntensity,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      hapticCooldown: hapticCooldown ?? this.hapticCooldown,
      backgroundColors: backgroundColors ?? this.backgroundColors,
      glassTintColor: glassTintColor ?? this.glassTintColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
      specularColor: specularColor ?? this.specularColor,
      ripplePrimaryColor: ripplePrimaryColor ?? this.ripplePrimaryColor,
      rippleSecondaryColor: rippleSecondaryColor ?? this.rippleSecondaryColor,
      particlePrimaryColor: particlePrimaryColor ?? this.particlePrimaryColor,
      particleSecondaryColor:
          particleSecondaryColor ?? this.particleSecondaryColor,
      ribbonStartColor: ribbonStartColor ?? this.ribbonStartColor,
      ribbonEndColor: ribbonEndColor ?? this.ribbonEndColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AetherThemeData &&
        other.preset == preset &&
        other.name == name &&
        other.stiffness == stiffness &&
        other.damping == damping &&
        other.pointerStiffness == pointerStiffness &&
        other.pointerDamping == pointerDamping &&
        other.blurSigma == blurSigma &&
        other.maxTiltRadians == maxTiltRadians &&
        other.edgeFlexDistance == edgeFlexDistance &&
        other.activationRadius == activationRadius &&
        other.waveSpeed == waveSpeed &&
        other.wavefrontBand == wavefrontBand &&
        other.specularRimStroke == specularRimStroke &&
        other.specularIntensity == specularIntensity &&
        other.enableHaptics == enableHaptics &&
        other.hapticCooldown == hapticCooldown &&
        other.glassTintColor == glassTintColor &&
        other.glassBorderColor == glassBorderColor &&
        other.specularColor == specularColor &&
        other.ripplePrimaryColor == ripplePrimaryColor &&
        other.rippleSecondaryColor == rippleSecondaryColor &&
        other.particlePrimaryColor == particlePrimaryColor &&
        other.particleSecondaryColor == particleSecondaryColor &&
        other.ribbonStartColor == ribbonStartColor &&
        other.ribbonEndColor == ribbonEndColor &&
        _listsEqual(other.backgroundColors, backgroundColors);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        preset,
        name,
        stiffness,
        damping,
        pointerStiffness,
        pointerDamping,
        blurSigma,
        maxTiltRadians,
        edgeFlexDistance,
        activationRadius,
        waveSpeed,
        wavefrontBand,
        specularRimStroke,
        specularIntensity,
        enableHaptics,
        hapticCooldown,
        Object.hashAll(backgroundColors),
        glassTintColor,
        glassBorderColor,
        specularColor,
        ripplePrimaryColor,
        rippleSecondaryColor,
        particlePrimaryColor,
        particleSecondaryColor,
        ribbonStartColor,
        ribbonEndColor,
      ]);

  static bool _listsEqual(List<Color> a, List<Color> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
