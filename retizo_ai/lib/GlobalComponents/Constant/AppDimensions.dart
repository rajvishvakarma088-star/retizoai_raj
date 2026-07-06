// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
/// Provides consistent spacing and dimensions throughout the app.
/// Uses 8pt grid system for visual harmony and professional appearance.
/// All values are responsive and adapt to different screen sizes.
//-✅---------------------------------------------------------------------✅-//
class AppDimensions {
  //-✅-- Spacing Scale (8pt Grid System) -------------------------------✅-//

  /// Extra small spacing (4dp) - Used for very tight padding within small elements
  static double xs = 4.0;

  /// Small spacing (8dp) - Used for padding within components
  static double sm = 8.0;

  /// Medium spacing (12dp) - Used between related UI elements
  static double md = 12.0;

  /// Large spacing (16dp) - Used between sections and major UI groups
  static double lg = 16.0;

  /// Extra large spacing (20dp) - Used for screen-level padding
  static double xl = 20.0;

  /// Extra extra large spacing (24dp) - Used for major section separation
  static double xxl = 24.0;

  /// Extra extra extra large spacing (32dp) - Used for screen top/bottom spacing
  static double xxxl = 32.0;

  //-✅-- Screen Query Helpers ------------------------------------------✅-//

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area top padding (for notch/status bar)
  static double safeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get safe area bottom padding (for gesture bars)
  static double safeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  //-✅-- Device Type Helpers -------------------------------------------✅-//

  /// Check if device is a small phone (width < 360dp)
  static bool isSmallPhone(BuildContext context) {
    return screenWidth(context) < 360;
  }

  /// Check if device is a standard mobile (width < 600dp)
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// Check if device is a tablet (width >= 600dp)
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  //-✅-- Responsive Value Helper ---------------------------------------✅-//

  /// Get responsive value based on device type
  ///
  /// Example:
  /// ```dart
  /// double padding = AppDimensions.responsive(
  ///   context: context,
  ///   mobile: 12.0,
  ///   tablet: 16.0,
  /// );
  /// ```
  static double responsive({
    required BuildContext context,
    required double mobile,
    double? tablet,
  }) {
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  //-✅-- Component Dimensions ------------------------------------------✅-//

  /// Button heights (maintains 44dp minimum for accessibility)
  static double buttonHeightSmall = 40.0;
  static double buttonHeightMedium = 48.0;
  static double buttonHeightLarge = 56.0;

  /// Input field standard height (accessible)
  static double inputHeight = 48.0;
  static double inputHeightCompact = 40.0;

  /// Icon sizes
  static double iconSmall = 16.0;
  static double iconMedium = 24.0;
  static double iconLarge = 32.0;

  /// Card/Container padding
  static double cardPadding = 16.0;
  static double cardPaddingCompact = 12.0;

  /// App bar height (excluding safe area)
  static double appBarHeight = kToolbarHeight;

  //-✅-- Screen Padding Helpers ----------------------------------------✅-//

  /// Get standard screen horizontal padding (responsive)
  static double screenPaddingHorizontal(BuildContext context) {
    return responsive(context: context, mobile: lg, tablet: xl);
  }

  /// Get standard screen vertical padding
  static double screenPaddingVertical(BuildContext context) {
    return responsive(context: context, mobile: lg, tablet: xl);
  }

  /// Get EdgeInsets for standard screen padding
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: screenPaddingHorizontal(context),
      vertical: screenPaddingVertical(context),
    );
  }

  /// Get EdgeInsets for card padding
  static EdgeInsets cardPaddingInsets = EdgeInsets.all(cardPadding);

  /// Get EdgeInsets for compact card padding
  static EdgeInsets cardPaddingInsetsCompact = EdgeInsets.all(
    cardPaddingCompact,
  );
}

//-✅---------------------------------------------------------------------✅-//
