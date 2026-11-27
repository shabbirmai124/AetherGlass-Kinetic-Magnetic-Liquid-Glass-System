import 'dart:ui';

import 'aether_theme_data.dart';

/// Pre-configured physics and optical theme personalities for AetherGlass.
abstract final class AetherPresets {
  /// **Bioluminescent:** Deep abyss navy backdrop (`#040B16` to `#081C2E`),
  /// cyan-teal glass glow (12% tint), emerald kinetic ripples, stiffness `180`,
  /// damping `14` (silky aquatic float).
  static const AetherThemeData bioluminescent = AetherThemeData(
    preset: AetherPreset.bioluminescent,
    name: 'Bioluminescent',
    stiffness: 180.0,
    damping: 14.0,
    pointerStiffness: 200.0,
    pointerDamping: 21.0,
    blurSigma: 12.0,
    maxTiltRadians: 0.12217,
    edgeFlexDistance: 8.0,
    activationRadius: 140.0,
    waveSpeed: 520.0,
    wavefrontBand: 40.0,
    specularRimStroke: 1.2,
    specularIntensity: 0.88,
    backgroundColors: <Color>[
      Color(0xFF040B16),
      Color(0xFF081C2E),
      Color(0xFF040E1C),
    ],
    glassTintColor: Color(0x1F0EA5E9),
    glassBorderColor: Color(0x4767E8F9),
    specularColor: Color(0xD95EEAD4),
    ripplePrimaryColor: Color(0xFF00F5D4),
    rippleSecondaryColor: Color(0xFF00BBF9),
    particlePrimaryColor: Color(0xFF38BDF8),
    particleSecondaryColor: Color(0xFF2DD4BF),
    ribbonStartColor: Color(0xFF5EEAD4),
    ribbonEndColor: Color(0xFF0284C7),
  );

  /// **Obsidian Frost:** Matte charcoal backdrop (`#0A0B0E` to `#14171D`),
  /// smoked slate glass cards (11% tint), crisp silver hairline sheen,
  /// stiffness `340`, damping `24` (tight snappy).
  static const AetherThemeData obsidianFrost = AetherThemeData(
    preset: AetherPreset.obsidianFrost,
    name: 'Obsidian Frost',
    stiffness: 340.0,
    damping: 24.0,
    pointerStiffness: 360.0,
    pointerDamping: 28.0,
    blurSigma: 12.0,
    maxTiltRadians: 0.095,
    edgeFlexDistance: 8.0,
    activationRadius: 140.0,
    waveSpeed: 520.0,
    wavefrontBand: 40.0,
    specularRimStroke: 1.2,
    specularIntensity: 0.78,
    backgroundColors: <Color>[
      Color(0xFF0A0B0E),
      Color(0xFF14171D),
      Color(0xFF090A0D),
    ],
    glassTintColor: Color(0x1C1F2937),
    glassBorderColor: Color(0x4AE2E8F0),
    specularColor: Color(0xE0F8FAFC),
    ripplePrimaryColor: Color(0xFFCBD5E1),
    rippleSecondaryColor: Color(0xFF64748B),
    particlePrimaryColor: Color(0xFF94A3B8),
    particleSecondaryColor: Color(0xFFE2E8F0),
    ribbonStartColor: Color(0xFFE2E8F0),
    ribbonEndColor: Color(0xFF475569),
  );

  /// **Solar Amber:** Deep warm bronze backdrop (`#140A05` to `#241309`),
  /// warm amber glass (13% tint), liquid gold sheen, ember motes,
  /// stiffness `250`, damping `18` (elastic bounce).
  static const AetherThemeData solarAmber = AetherThemeData(
    preset: AetherPreset.solarAmber,
    name: 'Solar Amber',
    stiffness: 250.0,
    damping: 18.0,
    pointerStiffness: 260.0,
    pointerDamping: 22.0,
    blurSigma: 12.0,
    maxTiltRadians: 0.12217,
    edgeFlexDistance: 8.0,
    activationRadius: 140.0,
    waveSpeed: 520.0,
    wavefrontBand: 40.0,
    specularRimStroke: 1.2,
    specularIntensity: 0.90,
    backgroundColors: <Color>[
      Color(0xFF140A05),
      Color(0xFF241309),
      Color(0xFF110804),
    ],
    glassTintColor: Color(0x21D97706),
    glassBorderColor: Color(0x4DFBBF24),
    specularColor: Color(0xD9FDE68A),
    ripplePrimaryColor: Color(0xFFF59E0B),
    rippleSecondaryColor: Color(0xFFFB7185),
    particlePrimaryColor: Color(0xFFFBBF24),
    particleSecondaryColor: Color(0xFFF97316),
    ribbonStartColor: Color(0xFFFDE68A),
    ribbonEndColor: Color(0xFFEA580C),
  );

  /// All built-in presets ordered for showcase selectors.
  static const List<AetherThemeData> all = <AetherThemeData>[
    bioluminescent,
    obsidianFrost,
    solarAmber,
  ];

  /// Resolves an [AetherPreset] enum value to its [AetherThemeData].
  static AetherThemeData fromPreset(AetherPreset preset) {
    switch (preset) {
      case AetherPreset.bioluminescent:
        return bioluminescent;
      case AetherPreset.obsidianFrost:
        return obsidianFrost;
      case AetherPreset.solarAmber:
        return solarAmber;
    }
  }
}
