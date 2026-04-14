import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/theme/app_colors.dart';

/// Aura Design System — Theme Builder
///
/// Font: Manrope (geometric, fintech-grade).
/// Scale: display → label, each with explicit semantic purpose.
/// Access via Material `Theme.of(context).textTheme` or `context.sageText`.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────
  // Typography scale
  // ─────────────────────────────────────────────────────

  static TextTheme _textTheme(SageColors c) {
    return TextTheme(
      // Hero metric — portfolio total
      displayLarge: GoogleFonts.manrope(
        fontSize: 44.sp,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.5,
        color: c.textPrimary,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
      // Sub-metric — card values
      displayMedium: GoogleFonts.manrope(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
        color: c.textPrimary,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
      // Stat value inside cards
      displaySmall: GoogleFonts.manrope(
        fontSize: 22.sp,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
        color: c.textPrimary,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
      // Page headline (onboarding, connect wallet)
      headlineLarge: GoogleFonts.manrope(
        fontSize: 36.sp,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: c.textPrimary,
      ),
      // Section title
      headlineMedium: GoogleFonts.manrope(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: c.textPrimary,
      ),
      // Card title
      headlineSmall: GoogleFonts.manrope(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: c.textPrimary,
      ),
      // Nav/header title
      titleLarge: GoogleFonts.manrope(
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
      ),
      // Row title
      titleMedium: GoogleFonts.manrope(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      // Uppercase tracked label — institutional signature
      titleSmall: GoogleFonts.manrope(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: c.textSecondary,
      ),
      // Paragraph / AI text
      bodyLarge: GoogleFonts.manrope(
        fontSize: 17.sp,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: c.textPrimary,
      ),
      // Default body
      bodyMedium: GoogleFonts.manrope(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: c.textSecondary,
      ),
      // Caption / detail
      bodySmall: GoogleFonts.manrope(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: c.textTertiary,
      ),
      // Button text
      labelLarge: GoogleFonts.manrope(
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
        color: c.buttonPrimaryText,
      ),
      // Chip / tag
      labelMedium: GoogleFonts.manrope(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: c.textSecondary,
      ),
      // Tiny label
      labelSmall: GoogleFonts.manrope(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: c.textTertiary,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // ThemeData builder
  // ─────────────────────────────────────────────────────

  static ThemeData _build(SageColors c) {
    final textTheme = _textTheme(c);
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.background,
      fontFamily: GoogleFonts.manrope().fontFamily,
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.accent,
        onPrimary: c.buttonPrimaryText,
        secondary: c.accent,
        onSecondary: c.buttonPrimaryText,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.loss,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: c.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 0.5, space: 0),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      extensions: [c],
    );
  }

  static ThemeData get darkTheme => _build(SageColors.dark);
  static ThemeData get lightTheme => _build(SageColors.light);
  static ThemeData get midnightTheme => _build(SageColors.midnight);
  static ThemeData get solanaTheme => _build(SageColors.solana);

  /// Build theme from any [SageColors] instance.
  static ThemeData fromColors(SageColors c) => _build(c);
}

/// Quick text-theme access: `context.sageText.headlineLarge`
extension SageTextX on BuildContext {
  TextTheme get sageText => Theme.of(this).textTheme;
}
