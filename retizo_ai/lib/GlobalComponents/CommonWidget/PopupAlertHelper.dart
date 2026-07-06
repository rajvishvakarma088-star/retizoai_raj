// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class PopupAlertHelper {
  static Future<void> showPopupFailedAlert(
    BuildContext context,
    String msgType,
    String btnValue,
    String msgTitle, [
    dynamic extraData,
  ]) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // ✅ Pass extraData here
          child: _buildPopupContent(
            context,
            msgType,
            msgTitle,
            btnValue,
            extraData,
          ),
        ),
      ),
    );
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static Widget _buildPopupContent(
    BuildContext context,
    String msgType,
    String msgTitle,
    String btnValue, [
    dynamic extraData,
  ]) {
    double screenWidth = MediaQuery.of(context).size.width;

    double dialogWidth = screenWidth * 0.1;
    if (screenWidth > 1200) {
      dialogWidth = 400;
    } else if (screenWidth > 900) {
      dialogWidth = 400;
    } else if (screenWidth > 600) {
      dialogWidth = 400;
    }

    return Container(
      width: dialogWidth,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 24 : 16,
        vertical: screenWidth > 600 ? 20 : 15,
      ),
      decoration: BoxDecoration(
        color: GlobalAppColor.WhiteColorCode,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 2),
            CommonWidget().FadeInUpWidget(
              duration: Duration(milliseconds: 600),
              child: _buildIcon(context, msgType),
            ),
            SizedBox(height: 25),
            CommonWidget().FadeInUpWidget(
              duration: Duration(milliseconds: 800),
              child: _buildMessage(msgTitle),
            ),
            SizedBox(height: 25),
            _buildCloseButton(context, btnValue, extraData),
            SizedBox(height: 2.0),
          ],
        ),
      ),
    );
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static Widget _buildIcon(BuildContext context, String msgType) {
    return Icon(
      _getIconForMessageType(msgType),
      size: 50,
      color: _getIconColor(msgType),
    );
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static Widget _buildMessage(String msgTitle) {
    return Text(
      msgTitle,
      textAlign: TextAlign.center,
      style: CommonWidget.CommonTitleTextStyle(
        fontSize: 15,
        letterSpacing: 0.5,
      ),
    );
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static Widget _buildCloseButton(
    BuildContext context,
    String btnValue,
    extraData,
  ) {
    return SizedBox(
      width: double.infinity,
      child: CommonWidget().CustomElevatedButton(
        title: GlobalFlag.Close,
        backgroundColor: GlobalAppColor.ButtonColor.withOpacity(.8),
        width: double.infinity,
        onPressed: () {
          GlobalFunction.hideKeyboard(context);
          _handleButtonPress(context, btnValue, extraData);
        },
      ),
    );
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static Color _getIconColor(String msgType) {
    switch (msgType) {
      case "Done":
        return GlobalAppColor.AvailableCode;
      case "Success":
        return GlobalAppColor.AvailableCode;
      case "WorkInProgress":
        return GlobalAppColor.RedCode;
      case "Failed":
      case "InternetNotConnected":
      case "Location":
        return GlobalAppColor.RedCode;
      default:
        return GlobalAppColor.RedCode;
    }
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static IconData? _getIconForMessageType(String msgType) {
    switch (msgType) {
      case "Done":
        return CupertinoIcons.check_mark_circled;
      case "Success":
        return CupertinoIcons.checkmark_alt_circle_fill;
      case "Failed":
        return CupertinoIcons.exclamationmark_shield_fill;
      case "WorkInProgress":
        return CupertinoIcons.exclamationmark_triangle_fill;
      case "InternetNotConnected":
        return FontAwesomeIcons.wifi;
      case "Location":
        return CupertinoIcons.location_solid;
      default:
        return CupertinoIcons.info_circle_fill;
    }
  }

  //--🔹-----------------------------------------------------------------🔹--//
  static void _handleButtonPress(
    BuildContext context,
    String btnValue,
    extraData,
  ) async {
    if (!context.mounted) return;
    GlobalFunction.hideKeyboard(context);
    // Default behavior: Close the dialog
    Navigator.pop(context);
    // Additional navigation based on the button value
    switch (btnValue) {
      /* // ✅ rescheduled appointment has been confirmed
      case "rescheduled appointment has been confirmed":
        CommonWidget().navigateToScreen(context, HomeScreen());
        break;*/
      case '':
        // No additional action — dialog already closed above
        break;
      default:
        GlobalFunction().debugFunction("⚠️ Unknown button value: $btnValue");
        break;
    }
  }
}

//-✅---------------------------------------------------------------------✅-//
