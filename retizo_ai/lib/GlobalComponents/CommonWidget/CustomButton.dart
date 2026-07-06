// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';

//-✅---------------------------------------------------------------------✅-//
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? borderRadius;
  final Color? customColor;
  final double? fontSize;
  final FontWeight? fontWeight; // Optional FontWeight

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.borderRadius,
    this.customColor,
    this.fontSize,
    this.fontWeight, // Default null, so it can be overridden
  });

  //--🔹-----------------------------------------------------------------🔹--//
  @override
  Widget build(BuildContext context) {
    final buttonColor =
        customColor ??
        (isEnabled
            ? GlobalAppColor.DarkTextColorCode
            : GlobalAppColor.DarkTextColorCode.withOpacity(0.7));

    return SizedBox(
      width: double.infinity, // Full width button
      height: AppDimensions.buttonHeightMedium,
      child:
          CupertinoButton(
            pressedOpacity: 1.0,
            color: buttonColor,
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppBorderRadius.md,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm,
            ),
            onPressed: isEnabled ? onPressed : null,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CommonWidget.CommonTitleTextStyle(
                color: GlobalAppColor.WhiteColorCode,
                fontWeight: fontWeight ?? FontWeight.w500,
                fontSize: fontSize ?? 16,
              ),
            ),
          ).animate().scale(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
