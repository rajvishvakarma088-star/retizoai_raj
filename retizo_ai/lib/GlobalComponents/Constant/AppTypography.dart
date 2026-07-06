// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
/// Provides consistent typography styles throughout the app.
/// Ensures professional text hierarchy and readability.
/// All styles are responsive and adapt to screen sizes.
//-✅---------------------------------------------------------------------✅-//
class AppTypography {
  //-✅-- Font Families -------------------------------------------------✅-//

  static const String primaryFont = 'RoobertPRO';
  static const String secondaryFont = 'openSans';

  //-✅-- Display Text Styles (Large Headlines) ------------------------✅-//

  /// Display Large: 32sp, Bold - Used for major headlines
  static TextStyle displayLarge({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 32,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      letterSpacing: -0.5,
    );
  }

  /// Display Medium: 28sp, Bold - Used for prominent subheadings
  static TextStyle displayMedium({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 28,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      letterSpacing: -0.3,
    );
  }

  /// Display Small: 24sp, SemiBold - Used for section titles
  static TextStyle displaySmall({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: -0.2,
    );
  }

  //-✅-- Heading Styles ------------------------------------------------✅-//

  /// H1: 24sp, SemiBold - Section titles
  static TextStyle h1({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: -0.2,
    );
  }

  /// H2: 20sp, SemiBold - Subsection titles
  static TextStyle h2({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 20,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: -0.1,
    );
  }

  /// H3: 18sp, Medium - Card titles, important labels
  static TextStyle h3({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 18,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
    );
  }

  /// H4: 16sp, Medium - Smaller headings
  static TextStyle h4({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
    );
  }

  //-✅-- Body Text Styles ----------------------------------------------✅-//

  /// Body Large: 16sp, Regular - Main content text
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  /// Body Medium: 14sp, Regular - Secondary content
  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  /// Body Small: 12sp, Regular - Captions, helper text
  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      height: 1.4,
    );
  }

  //-✅-- Label Styles --------------------------------------------------✅-//

  /// Label Large: 14sp, Medium - Buttons, prominent labels
  static TextStyle labelLarge({
    Color? color,
    FontWeight? fontWeight,
    bool uppercase = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: uppercase ? 0.5 : 0,
    );
  }

  /// Label Medium: 12sp, Medium - Standard labels
  static TextStyle labelMedium({
    Color? color,
    FontWeight? fontWeight,
    bool uppercase = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: uppercase ? 0.5 : 0,
    );
  }

  /// Label Small: 11sp, Medium - Tiny labels, badges
  static TextStyle labelSmall({
    Color? color,
    FontWeight? fontWeight,
    bool uppercase = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 11,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: uppercase ? 0.5 : 0,
    );
  }

  //-✅-- Specialized Styles --------------------------------------------✅-//

  /// Button text style - optimized for buttons
  static TextStyle button({Color? color, double? fontSize}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.3,
    );
  }

  /// Price/Number text style - tabular numbers for alignment
  static TextStyle price({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Caption text style - for very small supporting text
  static TextStyle caption({Color? color, FontStyle? fontStyle}) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color,
      fontStyle: fontStyle,
      height: 1.3,
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
