import 'package:flutter/material.dart';

/// One accent per app; everything else is shared calm neutrals (same values as the
/// React Native `@basalt/core` palette so all Basalt apps look like one family).
@immutable
class BasaltAccent {
  const BasaltAccent({required this.dark, required this.light, this.onAccentDark = const Color(0xFF0C0D10)});

  /// Accent on dark surfaces.
  final Color dark;

  /// Accent on light surfaces (usually a deeper shade for contrast).
  final Color light;

  /// Text/icon colour placed on the accent in dark mode. Light mode always uses white.
  final Color onAccentDark;

  static const teal = BasaltAccent(dark: Color(0xFF2DD4BF), light: Color(0xFF0F766E));
  static const indigo = BasaltAccent(dark: Color(0xFF818CF8), light: Color(0xFF4F46E5));
  static const amber = BasaltAccent(dark: Color(0xFFFBBF24), light: Color(0xFFB45309));
  static const rose = BasaltAccent(dark: Color(0xFFFB7185), light: Color(0xFFE11D48));
  static const sky = BasaltAccent(dark: Color(0xFF38BDF8), light: Color(0xFF0369A1));
  static const lime = BasaltAccent(dark: Color(0xFFA3E635), light: Color(0xFF4D7C0F));
  static const violet = BasaltAccent(dark: Color(0xFFC084FC), light: Color(0xFF7E22CE));
  static const orange = BasaltAccent(dark: Color(0xFFFB923C), light: Color(0xFFC2410C));
}

/// Resolved colours for one brightness. Read it with `context.basalt`.
@immutable
class BasaltPalette extends ThemeExtension<BasaltPalette> {
  const BasaltPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.fill,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dangerSoft,
    required this.overlay,
  });

  factory BasaltPalette.build(Brightness brightness, BasaltAccent accent) {
    if (brightness == Brightness.dark) {
      return BasaltPalette(
        brightness: brightness,
        bg: const Color(0xFF0C0D10),
        surface: const Color(0xFF15171B),
        surfaceRaised: const Color(0xFF1B1E23),
        fill: const Color(0xFF1F2228),
        border: const Color(0xFF262A31),
        text: const Color(0xFFECEDEF),
        textMuted: const Color(0xFF9EA4AE),
        textFaint: const Color(0xFF6A707B),
        accent: accent.dark,
        accentSoft: accent.dark.withValues(alpha: 0.13),
        onAccent: accent.onAccentDark,
        success: const Color(0xFF4ADE80),
        warning: const Color(0xFFFBBF24),
        danger: const Color(0xFFF87171),
        dangerSoft: const Color(0xFFF87171).withValues(alpha: 0.13),
        overlay: Colors.black.withValues(alpha: 0.6),
      );
    }
    return BasaltPalette(
      brightness: brightness,
      bg: const Color(0xFFF6F7F9),
      surface: const Color(0xFFFFFFFF),
      surfaceRaised: const Color(0xFFFFFFFF),
      fill: const Color(0xFFF0F1F4),
      border: const Color(0xFFE3E5E9),
      text: const Color(0xFF111318),
      textMuted: const Color(0xFF5A606C),
      textFaint: const Color(0xFF8B919C),
      accent: accent.light,
      accentSoft: accent.light.withValues(alpha: 0.09),
      onAccent: Colors.white,
      success: const Color(0xFF15803D),
      warning: const Color(0xFFB45309),
      danger: const Color(0xFFDC2626),
      dangerSoft: const Color(0xFFDC2626).withValues(alpha: 0.08),
      overlay: const Color(0xFF111318).withValues(alpha: 0.45),
    );
  }

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceRaised;

  /// Subtle fill for inputs, icon tiles and pressed states.
  final Color fill;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dangerSoft;
  final Color overlay;

  bool get isDark => brightness == Brightness.dark;

  /// A soft tint of any colour, for icon tiles and badges.
  Color soft(Color c) => c.withValues(alpha: isDark ? 0.14 : 0.10);

  @override
  BasaltPalette copyWith({Color? accent, Color? accentSoft, Color? onAccent}) => BasaltPalette(
        brightness: brightness,
        bg: bg,
        surface: surface,
        surfaceRaised: surfaceRaised,
        fill: fill,
        border: border,
        text: text,
        textMuted: textMuted,
        textFaint: textFaint,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        onAccent: onAccent ?? this.onAccent,
        success: success,
        warning: warning,
        danger: danger,
        dangerSoft: dangerSoft,
        overlay: overlay,
      );

  @override
  BasaltPalette lerp(ThemeExtension<BasaltPalette>? other, double t) {
    if (other is! BasaltPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BasaltPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      fill: l(fill, other.fill),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      overlay: l(overlay, other.overlay),
    );
  }
}

/// Spacing scale shared with the React Native apps.
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double pill = 999;
}

/// Type scale (Inter, bundled in this package so nothing is fetched at runtime).
abstract final class BasaltType {
  static const String family = 'Inter';
  static const String package = 'basalt';

  static const hero = TextStyle(fontSize: 30, height: 36 / 30, letterSpacing: -0.6, fontWeight: FontWeight.w700);
  static const display = TextStyle(fontSize: 26, height: 32 / 26, letterSpacing: -0.5, fontWeight: FontWeight.w700);
  static const title = TextStyle(fontSize: 20, height: 26 / 20, letterSpacing: -0.3, fontWeight: FontWeight.w600);
  static const heading = TextStyle(fontSize: 16, height: 22 / 16, letterSpacing: -0.1, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400);
  static const bodyStrong = TextStyle(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w500);
  static const label = TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500);
  static const caption = TextStyle(fontSize: 12.5, height: 17 / 12.5, fontWeight: FontWeight.w400);
  static const overline = TextStyle(fontSize: 11, height: 14 / 11, letterSpacing: 0.8, fontWeight: FontWeight.w600);
}

extension BasaltContext on BuildContext {
  /// The Basalt palette for the current theme.
  BasaltPalette get basalt => Theme.of(this).extension<BasaltPalette>()!;
}
