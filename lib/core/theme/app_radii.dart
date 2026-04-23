import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Aura Design System — Radius Tokens
///
/// Semantic corner radii. Picked to give an iOS-style "squircle" feel
/// when paired with [squircleShape] / [squircleBorder]. Migrate any
/// `BorderRadius.circular(N.r)` call sites to one of these tiers so the
/// curve language stays consistent across screens.
///
/// Tier guide (from `AURA_MOBILE_DESIGN_SKILL.md` §1.3):
///   pill  — full-pill capsule: action buttons, status badges, small tags
///   xl    — hero cards, top of bottom sheets, agent containers
///   lg    — primary cards, modal buttons, profile/strategy cards
///   md    — list item rows, input fields, OTP boxes, fleet/strategy chips
///   sm    — inline badges, tooltip pills, segmented control items
///   xs    — tight inner elements, mini progress bars
///
/// Access via `context.auraRadii.lg` (returns a [double] in `.r` units).
/// For an iOS-style squircle [ShapeBorder], call
/// `context.auraRadii.squircleShape(context.auraRadii.lg)`.
class AuraRadii extends ThemeExtension<AuraRadii> {
  final double pill;
  final double xl;
  final double lg;
  final double md;
  final double sm;
  final double xs;

  const AuraRadii({
    required this.pill,
    required this.xl,
    required this.lg,
    required this.md,
    required this.sm,
    required this.xs,
  });

  /// Default tokens. Values are pre-`.r`-scaled by reading them through
  /// `ScreenUtil` at build time via the [AuraRadii.responsive] factory.
  /// Use [AuraRadii.responsive] inside the theme builder so values track
  /// device width.
  factory AuraRadii.responsive() =>
      AuraRadii(pill: 999.0, xl: 28.r, lg: 22.r, md: 16.r, sm: 10.r, xs: 6.r);

  /// Plain `BorderRadius` of the given tier — drop-in for existing
  /// `BoxDecoration(borderRadius: ...)` sites.
  BorderRadius border(double r) => BorderRadius.circular(r);

  /// iOS-style continuous-curve squircle for the given tier. Use with
  /// `ShapeDecoration(shape: …)`, `Material(shape: …)`, or
  /// `ClipPath(clipper: ShapeBorderClipper(shape: …))`.
  ///
  /// Flutter's [ContinuousRectangleBorder] is the closest built-in
  /// approximation of the iOS superellipse. Pass the same numeric tier
  /// you would use for `BorderRadius.circular`.
  ShapeBorder squircleShape(double r) =>
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(r));

  /// Convenience: [squircleShape] + a stroke side, for cards that need
  /// both the squircle silhouette and a hairline border.
  ShapeBorder squircleBorder(double r, {required BorderSide side}) =>
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(r),
        side: side,
      );

  @override
  AuraRadii copyWith({
    double? pill,
    double? xl,
    double? lg,
    double? md,
    double? sm,
    double? xs,
  }) => AuraRadii(
    pill: pill ?? this.pill,
    xl: xl ?? this.xl,
    lg: lg ?? this.lg,
    md: md ?? this.md,
    sm: sm ?? this.sm,
    xs: xs ?? this.xs,
  );

  @override
  AuraRadii lerp(ThemeExtension<AuraRadii>? other, double t) {
    if (other is! AuraRadii) return this;
    return AuraRadii(
      pill: _l(pill, other.pill, t),
      xl: _l(xl, other.xl, t),
      lg: _l(lg, other.lg, t),
      md: _l(md, other.md, t),
      sm: _l(sm, other.sm, t),
      xs: _l(xs, other.xs, t),
    );
  }

  static double _l(double a, double b, double t) => a + (b - a) * t;
}

/// Quick accessor — `context.auraRadii.lg`.
extension AuraRadiiX on BuildContext {
  AuraRadii get auraRadii =>
      Theme.of(this).extension<AuraRadii>() ?? AuraRadii.responsive();
}
