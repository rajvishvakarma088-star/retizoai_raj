// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';

//-✅---------------------------------------------------------------------✅-//
class ShowBottomSheet extends StatelessWidget {
  final String msgTitle, button1Text, button2Text, BtnCondition;
  final IconData? icon;
  final Color iconColor;
  final double iconSize;
  final String? OrderID;

  const ShowBottomSheet({
    super.key,
    required this.msgTitle,
    required this.button1Text,
    required this.button2Text,
    required this.BtnCondition,
    this.icon,
    this.iconColor = const Color(0xFF141414),
    this.iconSize = 65.0,
    this.OrderID,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bool isPortrait = orientation == Orientation.portrait;
    final double screenWidth = MediaQuery.of(context).size.width;

    // ✅ Web + Tablet width limit
    final double sheetWidth = screenWidth > 600 ? 450 : screenWidth;

    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: sheetWidth, // ✅ Set max width for Web/Tablet properly
          ),
          child: Container(
            padding: EdgeInsets.only(
              bottom: isPortrait ? 20 : 18,
              top: isPortrait ? 18 : 10,
            ),
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
                    color: GlobalAppColor.ButtonColor.withOpacity(.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                SizedBox(height: isPortrait ? 20 : 15),

                if (icon != null) _buildIcon(isPortrait),
                SizedBox(height: isPortrait ? 20 : 15),

                Animate(
                  effects: [
                    FadeEffect(delay: 600.ms),
                    const SlideEffect(begin: Offset(0, 0.3), end: Offset(0, 0)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      msgTitle,
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: isPortrait ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: isPortrait ? 20 : 15),

                CommonWidget.buildButtons(
                  context: context,
                  button1Text: button2Text,
                  onButton1Pressed: () {
                    _executeButtonCondition(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //✅ Icon widget responsive
  Widget _buildIcon(bool isPortrait) {
    final double size = isPortrait ? iconSize : iconSize * 0.75;

    return Animate(
      effects: [
        FadeEffect(delay: 500.ms),
        const SlideEffect(begin: Offset(0, 0.3), end: Offset(0, 0)),
      ],
      child: Container(
        padding: EdgeInsets.all(isPortrait ? 15 : 10),
        decoration: BoxDecoration(
          color: GlobalAppColor.ButtonColor,
          shape: BoxShape.circle,
          border: Border.all(color: iconColor, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: size),
      ),
    );
  }

  //✅ आपका Logic unchanged
  void _executeButtonCondition(BuildContext context) async {
    final HomeCtrl = Provider.of<HomeProvider>(context, listen: false);
    GlobalFunction.hideKeyboard(context);
    switch (BtnCondition) {
      case "ExitApplication":
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else if (Platform.isIOS) {
          try {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          } catch (_) {}
        } else {
          exit(0);
        }
        break;

      case "LogOutApplication":
        await GlobalFunction().LogoutClearData(context);
        break;

      case "DeleteOrder":
        await HomeCtrl.DeleteOrderService(context, OrderID.toString());
      case "CancelOrder":
        await HomeCtrl.CancelOrderItemService(context, OrderID.toString());
        break;
    }
  }
}

//-✅---------------------------------------------------------------------✅-//
