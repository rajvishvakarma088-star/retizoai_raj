// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
/// Provides consistent border radius values throughout the app.
/// Ensures professional, cohesive visual design.
//-✅---------------------------------------------------------------------✅-//
class AppBorderRadius {
  //-✅-- Border Radius Scale -------------------------------------------✅-//

  /// No radius - Sharp corners (0dp)
  static double none = 0;

  /// Extra small radius (4dp) - Subtle rounding
  static double xs = 4;

  /// Small radius (8dp) - Input fields, chips
  static double sm = 8;

  /// Medium radius (12dp) - Buttons, cards (most common)
  static double md = 12;

  /// Large radius (16dp) - Dialogs, prominent cards
  static double lg = 16;

  /// Extra large radius (20dp) - Pills, badges
  static double xl = 20;

  /// Extra extra large radius (24dp) - Large rounded elements
  static double xxl = 24;

  /// Full radius (999dp) - Circular elements
  static double full = 999;

  //-✅-- BorderRadius Helpers ------------------------------------------✅-//

  /// Get BorderRadius.circular for xs
  static BorderRadius circularXS = BorderRadius.circular(xs);

  /// Get BorderRadius.circular for sm
  static BorderRadius circularSM = BorderRadius.circular(sm);

  /// Get BorderRadius.circular for md (most common)
  static BorderRadius circularMD = BorderRadius.circular(md);

  /// Get BorderRadius.circular for lg
  static BorderRadius circularLG = BorderRadius.circular(lg);

  /// Get BorderRadius.circular for xl
  static BorderRadius circularXL = BorderRadius.circular(xl);

  /// Get BorderRadius.circular for xxl
  static BorderRadius circularXXL = BorderRadius.circular(xxl);

  /// Get BorderRadius.circular for full circle
  static BorderRadius circularFull = BorderRadius.circular(full);

  //-✅-- Component-Specific BorderRadius -------------------------------✅-//

  /// Button border radius (12dp) - Professional rounded
  static BorderRadius button = BorderRadius.circular(md);

  /// Card border radius (12dp) - Consistent with buttons
  static BorderRadius card = BorderRadius.circular(md);

  /// Input field border radius (8dp) - Subtle, form-like
  static BorderRadius input = BorderRadius.circular(sm);

  /// Dialog border radius (16dp) - Prominent, modal
  static BorderRadius dialog = BorderRadius.circular(lg);

  /// Bottom sheet border radius (16dp, top corners only)
  static BorderRadius bottomSheet = const BorderRadius.vertical(
    top: Radius.circular(16),
  );

  /// Chip/Badge border radius (20dp) - Pill-shaped
  static BorderRadius chip = BorderRadius.circular(xl);

  /// Avatar border radius (full circle)
  static BorderRadius avatar = BorderRadius.circular(full);

  //-✅-- Directional BorderRadius --------------------------------------✅-//

  /// Top left and top right corners only
  static BorderRadius topOnly({double radius = 12}) {
    return BorderRadius.vertical(top: Radius.circular(radius));
  }

  /// Bottom left and bottom right corners only
  static BorderRadius bottomOnly({double radius = 12}) {
    return BorderRadius.vertical(bottom: Radius.circular(radius));
  }

  /// Left side corners only
  static BorderRadius leftOnly({double radius = 12}) {
    return BorderRadius.horizontal(left: Radius.circular(radius));
  }

  /// Right side corners only
  static BorderRadius rightOnly({double radius = 12}) {
    return BorderRadius.horizontal(right: Radius.circular(radius));
  }

  /// Custom corner radius (specify each corner individually)
  static BorderRadius custom({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
