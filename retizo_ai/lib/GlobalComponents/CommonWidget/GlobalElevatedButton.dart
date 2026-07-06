// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class GlobalElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final OutlinedBorder? shape;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const GlobalElevatedButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.width,
    this.padding,
    this.shape,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimensions.buttonHeightMedium,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.black,
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.md,
              ),
          shape:
              shape ??
              RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
        ),
        onPressed: onPressed,
        child: Text(
          buttonText,
          style:
              textStyle ??
              CommonWidget.CommonTitleTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
