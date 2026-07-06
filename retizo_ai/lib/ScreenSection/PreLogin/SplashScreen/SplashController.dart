// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrintingDeviceProvider.dart';

//-✅---------------------------------------------------------------------✅-//
class SplashProvider with ChangeNotifier {
  //--🔹--StartTimeout--------------------------------------------------🔹--//
  void StartTimeout(BuildContext context) {
    Future.delayed(Duration(seconds: 7), () => HandleTimeout(context));
    notifyListeners();
  }

  //--🔹--HandleTimeout--------------------------------------------------🔹--//
  Future<void> HandleTimeout(BuildContext context) async {
    try {
      // Initialize providers
      final userInfoProvider = context.read<UserInfoProvider>();
      context.read<CheckInternetProvider>();
      // Load user info securely
      await userInfoProvider.LoadUserInfo();

      // Fetch user data
      final userData = userInfoProvider.UserData;
      final String orgUserId = userData?.orgUserId ?? "";
      final int branchId = userData?.branchId ?? 0;

      // Print user data status in debug
      GlobalFunction().debugFunction(
        "🌟 [SplashProvider] User Data Loaded -> orgUserId: $orgUserId, branchId: $branchId, IsLoggedIn: ${userInfoProvider.isLoggedIn}",
      );
      if (orgUserId.isEmpty || branchId == 0) {
        await NavigateTo(context, const LoginScreen());
      } else {
        final userInfoCtrl = Provider.of<UserInfoProvider>(
          context,
          listen: false,
        );

        // Connect printer before navigating to home.
        // We capture the provider and token here so they can be safely used
        // in a delayed callback AFTER Login() pushes to the home screen —
        // no BuildContext is needed after navigation.
        final printingDeviceProvider = Provider.of<PrintingDeviceProvider>(
          context,
          listen: false,
        );
        final accessToken = userInfoCtrl.AccessToken;

        if (accessToken != null) {
          try {
            await printingDeviceProvider
                .fetchAndConnect(accessToken)
                .timeout(const Duration(seconds: 10), onTimeout: () {});
          } catch (_) {}
        }

        await userInfoCtrl.Login(context);

        // Delayed retry after home navigation completes.
        // Root cause: the 10-second splash wrapper unblocks Login() before
        // fetchAndConnect() finishes (HTTP + TCP connect can take >10s on
        // first install), leaving lastRegularTarget null in the native layer.
        // This retry fires 8 seconds after reaching the home screen —
        // by then the network and printer are ready — and mirrors exactly
        // what Printer Settings does in initState() via addPostFrameCallback.
        if (accessToken != null) {
          Future.delayed(const Duration(seconds: 8), () {
            printingDeviceProvider.fetchAndConnect(accessToken).ignore();
          });
        }
      }
    } catch (error, stack) {
      debugPrintStack(stackTrace: stack);
      GlobalFunction().debugFunction('❌ Error in splash timeout: $error');
    }
  }

  //--🔹--NavigateTo-----------------------------------------------------🔹--//
  Future<void> NavigateTo(BuildContext context, Widget destination) async {
    await GlobalFunction().setPortrait();
    CommonWidget().navigateToScreen(context, destination);
  }
}

//-✅---------------------------------------------------------------------✅-//
