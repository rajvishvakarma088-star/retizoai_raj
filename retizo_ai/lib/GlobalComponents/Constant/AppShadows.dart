// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
/// Provides consistent elevation and shadow styles throughout the app.
/// Creates depth hierarchy and professional visual layering.
//-✅---------------------------------------------------------------------✅-//
class AppShadows {
  //-✅-- Shadow Levels (Elevation System) ------------------------------✅-//

  /// Level 0: No shadow - Flat surfaces, inline elements
  static List<BoxShadow> none = [];

  /// Level 1: Subtle shadow - Resting cards, minimal elevation
  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Level 2: Medium shadow - Raised cards, buttons, dropdowns
  static List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Level 3: Strong shadow - Dialogs, floating elements
  static List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Level 4: Very strong shadow - Modals, prominent overlays
  static List<BoxShadow> xl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      offset: const Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// Level 5: Dramatic shadow - Bottom sheets, heavy modals
  static List<BoxShadow> xxl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      offset: const Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  //-✅-- Specialized Shadows -------------------------------------------✅-//

  /// Card shadow - Default for most cards
  static List<BoxShadow> card = md;

  /// Button shadow - Subtle elevation for buttons
  static List<BoxShadow> button = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Dialog shadow - For alert dialogs and modals
  static List<BoxShadow> dialog = lg;

  /// Bottom sheet shadow - For sheet overlays
  static List<BoxShadow> bottomSheet = xl;

  /// Floating action button shadow
  static List<BoxShadow> fab = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  //-✅-- Colored Shadows (for visual emphasis) -------------------------✅-//

  /// Colored shadow helper - useful for accent shadows
  static List<BoxShadow> colored({
    required Color color,
    double opacity = 0.3,
    double blur = 8,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        offset: offset,
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  //-✅-- Inner Shadows (for pressed states) ----------------------------✅-//

  /// Inner shadow effect - for pressed/inset appearance
  /// Note: Requires custom paint or using Stack with clipped containers
  static List<BoxShadow> inner = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
}

//-✅---------------------------------------------------------------------✅-//
