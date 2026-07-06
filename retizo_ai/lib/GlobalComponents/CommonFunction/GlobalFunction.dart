// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, curly_braces_in_flow_control_structures
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrintingDeviceProvider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/single_child_widget.dart';

//-✅--CommonProviders----------------------------------------------------✅-//
List<SingleChildWidget> CommonProviders(BuildContext context) => [
  //----✅--HttpServiceProvider
  ChangeNotifierProvider(create: (context) => HttpServiceProvider()),
  //----✅--LanguageProvider
  ChangeNotifierProvider(create: (context) => LanguageProvider()),
  //----✅--ThemeProvider
  ChangeNotifierProvider(create: (context) => ThemeProvider()),
  //----✅--CheckInternetProvider
  ChangeNotifierProvider(create: (context) => CheckInternetProvider()),
  //----✅--SplashProvider
  ChangeNotifierProvider(create: (context) => SplashProvider()),
  //----✅--LoginProvider
  ChangeNotifierProvider(create: (context) => LoginProvider()),
  //----✅--UserInfoProvider
  ChangeNotifierProvider(create: (context) => UserInfoProvider()),
  //----✅--BackGroundApiProvider
  ChangeNotifierProvider(create: (context) => BackGroundApiProvider()),
  //----✅--HomeProvider
  ChangeNotifierProvider(create: (context) => HomeProvider()),
  //----✅--AddOrderProvider
  ChangeNotifierProvider(create: (context) => AddOrderProvider()),
  //----✅--NumberInputDiscountProvider
  ChangeNotifierProvider(create: (context) => NumberInputDiscountProvider()),
  //----✅--NumberInputPAXProvider
  ChangeNotifierProvider(create: (context) => NumberInputPAXProvider()),
  //----✅--CashAmountProvider
  ChangeNotifierProvider(create: (context) => CashAmountProvider()),
  //----✅--CardAmountProvider
  ChangeNotifierProvider(create: (context) => CardAmountProvider()),
  ChangeNotifierProvider(create: (context) => PayBillCashAmountProvider()),
  ChangeNotifierProvider(create: (context) => PayBillCardAmountProvider()),
  //----✅--MultiPaymentProvider
  ChangeNotifierProvider(create: (context) => MultiPaymentProvider()),
  //----✅--SessionProvider
  ChangeNotifierProvider(create: (context) => SessionProvider()),
  //----✅--KdsProvider
  ChangeNotifierProvider(create: (context) => KdsProvider()),
  //----✅--BottomNavProvider
  ChangeNotifierProvider(create: (context) => BottomNavProvider()),
  //----✅--CashDrawerProvider
  ChangeNotifierProvider(create: (context) => CashDrawerProvider()),
  //----✅--PrinterIntegrationProvider (Epson Printer Support)
  ChangeNotifierProvider(create: (context) => PrinterIntegrationProvider()),
  //----✅--PrintingDeviceProvider (Backend-driven printer device list + KDS auto-print)
  ChangeNotifierProvider(create: (context) => PrintingDeviceProvider()),
];

class GlobalFunction {
  /// Guard flag to prevent multiple concurrent logout calls.
  static bool _isLoggingOut = false;

  String formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return "";

    try {
      DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat("hh:mm a").format(dateTime);
    } catch (e) {
      return "";
    }
  }

  //--🔹--setPortrait----------------------------------------------------🔹--//
  Future<void> setPortrait() async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  //-----------------EmailInputFormatters
  static List<TextInputFormatter> get EmailInputFormatters {
    return [FilteringTextInputFormatter.deny(RegExp(r'\s'))];
  }

  //--🔹--AppPermission--------------------------------------------------🔹--//
  /*  Future<void> AppPermission() async {
    await Permission.camera.request();
    await Permission.mediaLibrary.request();
  }*/

  //--🔹--debugFunction--------------------------------------------------🔹--//
  void debugFunction(String Value) {
    debugPrint("✅============$Value");
  }

  //--🔹--hideKeyboard---------------------------------------------------🔹--//
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    FocusScope.of(context).unfocus();
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  //--🔹--checkInternetConnection----------------------------------------🔹--//
  Future<bool> checkInternetConnection(BuildContext context) async {
    hideKeyboard(context);
    FocusScope.of(context).requestFocus(FocusNode());
    FocusScope.of(context).unfocus();
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      PopupAlertHelper.showPopupFailedAlert(
        context,
        "InternetNotConnected",
        "",
        GlobalFlag.InternetNotConnected,
      );
      return false;
    }
    return true;
  }

  //--🔹--LogOutApplication----------------------------------------------🔹--//
  static Future<void> LogOutApplication({required BuildContext context}) async {
    bool isConnected = await GlobalFunction().checkInternetConnection(
      navigatorKey.currentContext!,
    );
    if (isConnected) {
      // Show bottom sheet
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: navigatorKey.currentContext!,
        builder: (_) => ShowBottomSheet(
          msgTitle: GlobalFlag.LogOutApp,
          button1Text: GlobalFlag.Close,
          button2Text: GlobalFlag.LogOut,
          BtnCondition: "LogOutApplication",
          icon: Icons.logout_sharp,
          iconColor: GlobalAppColor.WhiteColorCode,
          iconSize: 22,
        ),
      );
    }
  }

  //--🔹--ExitApplication------------------------------------------------🔹--//
  static Future<bool> ExitApplication({required BuildContext context}) async {
    final result = await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => ShowBottomSheet(
        msgTitle: GlobalFlag.exitanApp,
        button1Text: GlobalFlag.Close,
        button2Text: GlobalFlag.Exit,
        BtnCondition: "ExitApplication",
        icon: Icons.logout_sharp,
        iconColor: GlobalAppColor.WhiteColorCode,
        iconSize: 20,
      ),
    );
    return result ?? false;
  }

  //--🔹--DeleteOrder---------------------------------------------------🔹--//
  static Future<bool> DeleteOrder({
    required BuildContext context,
    required String Msg,
    required String OrderID,
  }) async {
    final result = await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => ShowBottomSheet(
        msgTitle: Msg,
        button1Text: GlobalFlag.Close,
        button2Text: "Delete",
        BtnCondition: "DeleteOrder",
        icon: Symbols.delete,
        iconColor: GlobalAppColor.WhiteColorCode,
        iconSize: 20,
        OrderID: OrderID,
      ),
    );
    return result ?? false;
  }

  //--🔹--CancelOrder---------------------------------------------------🔹--//
  static Future<bool> CancelOrder({
    required BuildContext context,
    required String Msg,
    required String OrderID,
  }) async {
    final result = await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => ShowBottomSheet(
        msgTitle: Msg,
        button1Text: GlobalFlag.Close,
        button2Text: "Cancel",
        BtnCondition: "CancelOrder",
        icon: Symbols.block,
        iconColor: GlobalAppColor.WhiteColorCode,
        iconSize: 20,
        OrderID: OrderID,
      ),
    );
    return result ?? false;
  }

  //-✅------isValidEmail-------------------------------------------------✅-//
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  //-🔹showError----------------------------------------------------------🔹-//
  void showError(BuildContext context, Object e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", "$e");
    });
  }

  //--🔹--capitalizeEachPart**-------------------------------------------🔹--//
  String capitalizeEachPart(String text) {
    return text
        .split('-')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join('-');
  }

  //--🔹--formatOrderDate**----------------------------------------------🔹--//
  String formatOrderDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal(); // convert UTC → local
      final dayFormat = DateFormat(
        'EEE, MMM d, y',
      ); // Sun, Oct 19, 2025
      final timeFormat = DateFormat('h:mm a'); // 11:21 AM
      return '${dayFormat.format(date)} | ${timeFormat.format(date)}';
    } catch (e) {
      return dateString; // fallback if parsing fails
    }
  }

  //-✅------LogoutClearData----------------------------------------------✅-//
  Future<void> LogoutClearData(BuildContext context) async {
    // Guard: ignore duplicate logout calls triggered by concurrent 401 responses.
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      // 1. Close HTTP client
      final httpCtrl = Provider.of<HttpServiceProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      httpCtrl.closeHttpClient();

      // 2. Clear locally stored secure data
      await SecureStorageService.ClearAll();
      SecureStorageService.resetLogger();

      // 🔐 2.1 Mark session inactive
      final sessionProvider = Provider.of<SessionProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      sessionProvider.expireSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("detailTimers");
      await prefs.remove("autoExtended");
      await prefs.remove("detailEndTimes");
      await prefs.remove("activeOrderId");
      // 3. Clear UserInfoProvider data
      final userInfoProvider = Provider.of<UserInfoProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await userInfoProvider.Logout();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // release the guard before navigating — pushAndRemoveUntil never
        // completes when the destination route is never popped, so any code
        // placed after the await would never run.
        _isLoggingOut = false;
        await Navigator.pushAndRemoveUntil(
          navigatorKey.currentContext!,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );

        GlobalFunction().debugFunction(
          "✅============🔒 User logged out and all data cleared successfully.",
        );
      });
    } catch (e) {
      _isLoggingOut = false;
      GlobalFunction().debugFunction(
        "❌ Error during logout & clearing data: $e",
      );
    }
  }

  //--🔹--capitalizeFirst------------------------------------------------🔹--//
  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

//-✅---------------------------------------------------------------------✅-//
// ** MyHttpOverrides Class: Handles HTTP Security Overrides **
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              true; // Ignore SSL certificate validation
  }
}

//-✅---------------------------------------------------------------------✅-//
// ** MyCustomScrollBehavior: Custom Scroll Behavior for App **
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Disable global scrollbar
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

//-✅---------------------------------------------------------------------✅-//