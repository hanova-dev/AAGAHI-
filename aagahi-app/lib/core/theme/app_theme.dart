import 'package:flutter/material.dart';

import '../../features/risk/domain/entities/risk_assessment.dart';

/// Design tokens for AAGAHI.
///
/// The palette is dark by default rather than light-with-a-dark-option. The
/// product is used outdoors in strong sun, where a dark surface with high
/// contrast text is more legible than a bright one, and it halves battery
/// draw on the OLED devices common in the target market.
abstract final class AppColors {
  // Ground
  static const soil = Color(0xFF0A130E);
  static const soil2 = Color(0xFF0F1C15);
  static const canopy = Color(0xFF16281E);
  static const canopy2 = Color(0xFF1D3527);
  static const bark = Color(0xFF2A3B31);

  // Glass
  static const glass = Color(0x12FFFFFF);
  static const glassStrong = Color(0x1CFFFFFF);
  static const edge = Color(0x29DCF0E2);
  static const edgeBright = Color(0x4DDCF0E2);

  // Text. Contrast measured against `soil`:
  //   ink   #EDF5EF -> 15.8:1  (AA and AAA for body)
  //   ink2  #B6CCBE ->  8.6:1  (AA for body)
  //   ink3  #87A091 ->  4.9:1  (AA for body, minimum acceptable)
  // Nothing lighter than ink3 is permitted for text of any size.
  static const ink = Color(0xFFEDF5EF);
  static const ink2 = Color(0xFFB6CCBE);
  static const ink3 = Color(0xFF87A091);

  // Risk ladder
  static const low = Color(0xFF63C08A);
  static const watch = Color(0xFFE7CB7E);
  static const warning = Color(0xFFE2934A);
  static const severe = Color(0xFFCB4830);

  // Action
  static const seed = Color(0xFF9BDCAE);
  static const seedDeep = Color(0xFF3E7A56);
  static const onSeed = Color(0xFF07150D);

  static Color forBand(RiskBand band) => switch (band) {
        RiskBand.low => low,
        RiskBand.watch => watch,
        RiskBand.warning => warning,
        RiskBand.severe => severe,
      };
}

/// Glyph shapes paired with each band, so risk is never carried by colour
/// alone (UI-EXT-07, NFR-USE-007). Circle, square, triangle, pentagon are
/// distinguishable in greyscale, at small size, and to a colour-blind user.
enum BandGlyph { circle, square, triangle, pentagon }

extension RiskBandPresentation on RiskBand {
  BandGlyph get glyph => switch (this) {
        RiskBand.low => BandGlyph.circle,
        RiskBand.watch => BandGlyph.square,
        RiskBand.warning => BandGlyph.triangle,
        RiskBand.severe => BandGlyph.pentagon,
      };

  /// Localisation key for the band name. Resolved to Urdu, Roman Urdu, or
  /// English at render time - never hardcoded English in the UI.
  String get labelKey => 'risk.band.$name';
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  /// Minimum interactive target (UI-EXT-05). Larger than Material's 48 dp
  /// default guidance is not needed, but smaller is never acceptable: the
  /// user may be wearing work gloves.
  static const double minTouchTarget = 48;
}

abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
}

abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.seed,
      onPrimary: AppColors.onSeed,
      secondary: AppColors.seedDeep,
      onSecondary: AppColors.ink,
      surface: AppColors.canopy,
      onSurface: AppColors.ink,
      error: AppColors.severe,
      onError: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.soil,
      fontFamily: 'Inter',
      textTheme: _textTheme,
      splashFactory: InkSparkle.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.seed,
          foregroundColor: AppColors.onSeed,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.edgeBright),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
    );
  }

  static const _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: AppColors.ink,
      height: 1.08,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: AppColors.ink,
      height: 1.18,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      color: AppColors.ink2,
      height: 1.55,
    ),
    bodySmall: TextStyle(
      fontSize: 11.5,
      color: AppColors.ink3,
      height: 1.5,
    ),
  );

  /// Urdu text style. Nastaliq needs far more line height than Latin script;
  /// at Material's default the descenders of one line collide with the
  /// ascenders of the next and the text becomes unreadable (CON-05).
  static const urdu = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    height: 2.05,
    color: AppColors.ink2,
  );
}
