import 'package:flutter/material.dart';

/// Aura Design System — Color Tokens
///
/// Every color in the app flows through [AuraColors].
/// Screens access tokens via `context.aura.<token>`.
///
/// Themes: dark (default), light, midnight, solana.
class AuraColors extends ThemeExtension<AuraColors> {
  final Brightness brightness;

  // ── Surfaces ──
  final Color background;
  final Color surface;
  final Color surfaceElevated;

  // ── Panel (light zone inside dark screens) ──
  final Color panelBackground;
  final Color panelText;
  final Color panelTextSecondary;
  final Color panelBorder;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  // ── Brand ──
  final Color accent;
  final Color accentMuted; // accent at ~10% for chip backgrounds etc.

  // ── Semantic ──
  final Color profit;
  final Color loss;
  final Color warning;
  final Color info;

  // ── Structure ──
  final Color border;
  final Color borderSubtle;
  final Color inputFill;
  final Color overlay;

  // ── Button ──
  final Color buttonPrimary;
  final Color buttonPrimaryText;
  final Color buttonDisabled;

  // ── Mode selector ──
  final Color modeActive;
  final Color modeInactive;

  // ── Onboarding (special) ──
  final Color onboardingNavy;
  final Color onboardingAccent;

  const AuraColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.panelBackground,
    required this.panelText,
    required this.panelTextSecondary,
    required this.panelBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.accentMuted,
    required this.profit,
    required this.loss,
    required this.warning,
    required this.info,
    required this.border,
    required this.borderSubtle,
    required this.inputFill,
    required this.overlay,
    required this.buttonPrimary,
    required this.buttonPrimaryText,
    required this.buttonDisabled,
    required this.modeActive,
    required this.modeInactive,
    required this.onboardingNavy,
    required this.onboardingAccent,
  });

  // ─────────────────────────────────────────────────────
  // DARK — primary experience
  // ─────────────────────────────────────────────────────
  static const dark = AuraColors(
    brightness: Brightness.dark,
    background: Color(0xFF050506),
    surface: Color(0xFF141416),
    surfaceElevated: Color(0xFF1C1C1E),
    panelBackground: Color(0xFFF8F8FA),
    panelText: Color(0xFF1A1A1C),
    panelTextSecondary: Color(0xFF6B6B70),
    panelBorder: Color(0xFFE8E8EC),
    textPrimary: Color(0xFFEFEFF1),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF48484A),
    textInverse: Color(0xFF1A1A1C),
    accent: Color(0xFF5B8DEF),
    accentMuted: Color(0x145B8DEF),
    profit: Color(0xFF34C759),
    loss: Color(0xFFFF3B30),
    warning: Color(0xFFFF9F0A),
    info: Color(0xFF5B8DEF),
    border: Color(0xFF2C2C2E),
    borderSubtle: Color(0xFF1C1C1E),
    inputFill: Color(0xFF1C1C1E),
    overlay: Color(0x66000000),
    buttonPrimary: Color(0xFF3366FF),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonDisabled: Color(0xFF48484A),
    modeActive: Color(0xFFEFEFF1),
    modeInactive: Color(0xFF48484A),
    onboardingNavy: Color(0xFF0A0A2E),
    onboardingAccent: Color(0xFF3366FF),
  );

  // ─────────────────────────────────────────────────────
  // LIGHT
  // ─────────────────────────────────────────────────────
  static const light = AuraColors(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F7),
    surfaceElevated: Color(0xFFFFFFFF),
    panelBackground: Color(0xFFF2F2F7),
    panelText: Color(0xFF1A1A1C),
    panelTextSecondary: Color(0xFF6B6B70),
    panelBorder: Color(0xFFE5E5EA),
    textPrimary: Color(0xFF1A1A1C),
    textSecondary: Color(0xFF6B6B70),
    textTertiary: Color(0xFFAEAEB2),
    textInverse: Color(0xFFEFEFF1),
    accent: Color(0xFF3D6FCC),
    accentMuted: Color(0x143D6FCC),
    profit: Color(0xFF28A745),
    loss: Color(0xFFDC3545),
    warning: Color(0xFFE67E22),
    info: Color(0xFF3D6FCC),
    border: Color(0xFFE5E5EA),
    borderSubtle: Color(0xFFF2F2F7),
    inputFill: Color(0xFFF2F2F7),
    overlay: Color(0x0A000000),
    buttonPrimary: Color(0xFF3366FF),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonDisabled: Color(0xFFD1D1D6),
    modeActive: Color(0xFF1A1A1C),
    modeInactive: Color(0xFFAEAEB2),
    onboardingNavy: Color(0xFF0A0A2E),
    onboardingAccent: Color(0xFF3366FF),
  );

  // ─────────────────────────────────────────────────────
  // MIDNIGHT — pure OLED black, cooler accents
  // ─────────────────────────────────────────────────────
  static const midnight = AuraColors(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF0C0C0E),
    surfaceElevated: Color(0xFF161618),
    panelBackground: Color(0xFF0C0C0E),
    panelText: Color(0xFFE0E0E4),
    panelTextSecondary: Color(0xFF6B6B70),
    panelBorder: Color(0xFF222224),
    textPrimary: Color(0xFFE8E8EC),
    textSecondary: Color(0xFF7C7C82),
    textTertiary: Color(0xFF3A3A3C),
    textInverse: Color(0xFF1A1A1C),
    accent: Color(0xFF6C9FFF),
    accentMuted: Color(0x146C9FFF),
    profit: Color(0xFF32D583),
    loss: Color(0xFFFF4D4F),
    warning: Color(0xFFFFB020),
    info: Color(0xFF6C9FFF),
    border: Color(0xFF222224),
    borderSubtle: Color(0xFF161618),
    inputFill: Color(0xFF161618),
    overlay: Color(0x80000000),
    buttonPrimary: Color(0xFF4D7FFF),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonDisabled: Color(0xFF3A3A3C),
    modeActive: Color(0xFFE8E8EC),
    modeInactive: Color(0xFF3A3A3C),
    onboardingNavy: Color(0xFF060620),
    onboardingAccent: Color(0xFF4D7FFF),
  );

  // ─────────────────────────────────────────────────────
  // SOLANA — Solana-branded accents (green/purple)
  // ─────────────────────────────────────────────────────
  static const solana = AuraColors(
    brightness: Brightness.dark,
    background: Color(0xFF0E0E12),
    surface: Color(0xFF18181E),
    surfaceElevated: Color(0xFF222228),
    panelBackground: Color(0xFF18181E),
    panelText: Color(0xFFE0E0E4),
    panelTextSecondary: Color(0xFF6B6B70),
    panelBorder: Color(0xFF2C2C32),
    textPrimary: Color(0xFFEFEFF1),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF48484A),
    textInverse: Color(0xFF1A1A1C),
    accent: Color(0xFF14F195), // Solana green
    accentMuted: Color(0x1414F195),
    profit: Color(0xFF14F195),
    loss: Color(0xFFFF4D4F),
    warning: Color(0xFFFFB020),
    info: Color(0xFF9945FF), // Solana purple
    border: Color(0xFF2C2C32),
    borderSubtle: Color(0xFF1E1E24),
    inputFill: Color(0xFF1E1E24),
    overlay: Color(0x66000000),
    buttonPrimary: Color(0xFF9945FF), // Solana purple CTA
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonDisabled: Color(0xFF48484A),
    modeActive: Color(0xFF14F195),
    modeInactive: Color(0xFF48484A),
    onboardingNavy: Color(0xFF0A0A20),
    onboardingAccent: Color(0xFF9945FF),
  );

  /// All available themes, keyed by name.
  static const Map<String, AuraColors> themes = {
    'dark': dark,
    'light': light,
    'midnight': midnight,
    'solana': solana,
  };

  @override
  AuraColors copyWith() => this;

  @override
  AuraColors lerp(AuraColors? other, double t) {
    if (other == null) return this;
    return AuraColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      panelText: Color.lerp(panelText, other.panelText, t)!,
      panelTextSecondary: Color.lerp(
        panelTextSecondary,
        other.panelTextSecondary,
        t,
      )!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonPrimaryText: Color.lerp(
        buttonPrimaryText,
        other.buttonPrimaryText,
        t,
      )!,
      buttonDisabled: Color.lerp(buttonDisabled, other.buttonDisabled, t)!,
      modeActive: Color.lerp(modeActive, other.modeActive, t)!,
      modeInactive: Color.lerp(modeInactive, other.modeInactive, t)!,
      onboardingNavy: Color.lerp(onboardingNavy, other.onboardingNavy, t)!,
      onboardingAccent: Color.lerp(
        onboardingAccent,
        other.onboardingAccent,
        t,
      )!,
    );
  }
}

/// Quick access: `context.aura.accent`, `context.aura.background`, etc.
extension AuraColorsX on BuildContext {
  AuraColors get aura => Theme.of(this).extension<AuraColors>()!;
}
