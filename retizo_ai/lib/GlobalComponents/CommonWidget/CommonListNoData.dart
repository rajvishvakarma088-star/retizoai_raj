// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

/// CommonListNoData
/// Globally reusable widget to show an image + content centered
/// Supports custom image and flexible child widgets
//-✅--------------------------------------------------------------------✅-//
class CommonListNoData extends StatelessWidget {
  /// Image asset path
  final String? imagePath;

  /// Optional image height
  final double? imageHeight;

  /// Children widgets below image (Text, Column, Buttons etc.)
  final List<Widget> children;

  /// Optional vertical padding around content
  final double verticalPadding;

  const CommonListNoData({
    super.key,
    this.imagePath,
    this.imageHeight,
    this.verticalPadding = 20,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.7, // default height 60% of screen
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display image if provided
            if (imagePath != null)
              Image.asset(
                imagePath!,
                height: imageHeight ?? 120, // default image height
                fit: BoxFit.contain,
              ),

            // Space between image and children

            // Render passed children widgets
            ...children,
          ],
        ),
      ),
    );
  }
}

//-✅--------------------------------------------------------------------✅-//
