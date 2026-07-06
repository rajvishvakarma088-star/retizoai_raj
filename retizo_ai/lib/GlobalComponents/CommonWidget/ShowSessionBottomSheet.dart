// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class ShowSessionBottomSheet extends StatelessWidget {
  final String msgTitle, button1Text, button2Text, BtnCondition;
  final IconData? icon; // Optional icon
  final Color iconColor;
  final double iconSize;

  const ShowSessionBottomSheet({
    super.key,
    required this.msgTitle,
    required this.button1Text,
    required this.button2Text,
    required this.BtnCondition,
    this.icon,
    this.iconColor = const Color(0xFF4ECB71), // Default icon color
    this.iconSize = 60.0, // Default icon size
  });

  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.only(bottom: 30, top: 15),
          decoration: BoxDecoration(
            color: GlobalAppColor.WhiteColorCode,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GlobalAppColor.ButtonColor.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 30),
              if (icon != null) _buildIcon(), // Display icon if available
              Animate(
                effects: [
                  FadeEffect(delay: 600.ms),
                  const SlideEffect(begin: Offset(0, 0.3), end: Offset(0, 0)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: Text(
                    msgTitle,
                    style: CommonWidget.CommonTitleTextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: CommonWidget().CustomElevatedButton(
                  width: double.infinity,
                  backgroundColor: GlobalAppColor.ButtonColor,
                  height: 45,
                  title: GlobalFlag.Close,
                  onPressed: () {
                    _executeButtonCondition(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  //-✅-------------------------------------------------------------------✅-//
  /// Creates a circular bordered icon
  Widget _buildIcon() {
    return Animate(
      effects: [
        FadeEffect(delay: 500.ms),
        const SlideEffect(begin: Offset(0, 0.3), end: Offset(0, 0)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Container(
          padding: const EdgeInsets.all(15), // Inner spacing for the icon
          decoration: BoxDecoration(
            color: GlobalAppColor.ButtonColor,
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1), // Circular border
          ),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }

  //-✅-------------------------------------------------------------------✅-//
  /// Executes button condition logic
  void _executeButtonCondition(BuildContext context) async {
    GlobalFunction.hideKeyboard(context);
    switch (BtnCondition) {
      //-✅------LogOutApplication----------------------------------------✅-//
      case "SessionExpired":
        await GlobalFunction().LogoutClearData(context);
        // Do NOT call Navigator.pop here — LogoutClearData already uses
        // pushAndRemoveUntil which clears the entire stack and pushes
        // SplashScreen. Calling pop afterwards on an empty history causes
        // the '_history.isNotEmpty' assertion crash.
        break;
      default:
        debugPrint("No matching condition");
        break;
    }
  }
}

//-✅--------------------------------------------------------------------✅-//
