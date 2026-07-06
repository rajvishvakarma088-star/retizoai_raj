// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';

//-✅---------------------------------------------------------------------✅-//
class LoginProvider with ChangeNotifier {
  bool isLoginLoading = false;

  bool get isLoginLoader => isLoginLoading;

  void setLoginLoading(bool value) {
    isLoginLoading = value;
    notifyListeners();
  }

  TextEditingController EmailController = TextEditingController();
  final FocusNode myFocusNodeEmail = FocusNode();

  TextEditingController PasswordController = TextEditingController();
  final FocusNode myFocusNodePassword = FocusNode();

  ValueNotifier<bool> toggleCredential = ValueNotifier<bool>(false);

  //--🔹--SubmitValidation----------------------------------------------🔹--//

  Future<void> SubmitValidation(BuildContext context) async {
    GlobalFunction.hideKeyboard(context);

    final email = EmailController.text.trim();
    final password = PasswordController.text;

    String? msgError;
    final langCtrl = Provider.of<LanguageProvider>(context, listen: false);

    if (email.isEmpty) {
      msgError = langCtrl.translate('validation.pleaseEnterEmail');
    } else if (!GlobalFunction().isValidEmail(email)) {
      msgError = langCtrl.translate('validation.pleaseEnterValidEmail');
    } else if (password.isEmpty) {
      msgError = langCtrl.translate('validation.pleaseEnterPassword');
    }

    if (msgError != null) {
      PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", msgError);
      return;
    }

    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (!isConnected) return;

    await LoginService(context);
  }

  //--🔹--LoginService---------------------------------------------------🔹--//
  Future<void> LoginService(BuildContext context) async {
    if (!context.mounted) return;

    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (!isConnected) return;

    GlobalFunction.hideKeyboard(context);
    setLoginLoading(true);

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final userInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final result = await httpCtrl.request(
        method: 'POST',
        url: PreLoginService,
        context: context,
        body: {
          "email": EmailController.text.trim(),
          "password": PasswordController.text.trim(),
        },
        requireLogin: true,
      );

      final success = result['success'] as bool? ?? false;
      final message = result['message']?.toString() ?? 'Unexpected response';

      if (!success) {
        PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", message);
        return;
      }
      // ✅ Success: Clear storage first, then save user info
      await SecureStorageService.ClearAll();

      // ✅ Success: parse and save user info
      final loginResponse = LoginResponseModel.fromJson(result);
      await userInfoCtrl.SaveUserInfo(context, loginResponse);

      // Fetch enriched profile (vat_no etc.) from /auth/me
      await userInfoCtrl.refreshUserProfile(context, httpCtrl);

      if (!context.mounted) return;

      await CallFunction(context, loginResponse);

      showCustomToast(
        context: context,
        message: message,
        backgroundColor: GlobalAppColor.ButtonColor,
      );
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error while login: $e");
      debugPrintStack(stackTrace: stack);
      final langCtrl = Provider.of<LanguageProvider>(context, listen: false);
      GlobalFunction().showError(context, langCtrl.translate('validation.somethingWrong'));
    } finally {
      setLoginLoading(false);
    }

    notifyListeners();
  }

  //--🔹--CallFunction----------------------------------------------------🔹--//
  Future<void> CallFunction(
    BuildContext context,
    LoginResponseModel loginResponse,
  ) async {
    final userInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);
    await userInfoCtrl.Login(context);

    // restore session so BasicAPI gate passes after logout+relogin
    Provider.of<SessionProvider>(context, listen: false).restoreSession();

    // Clear temporary data after login
    await ClearData(context);

    notifyListeners();
  }

  //--🔹--ClearData------------------------------------------------------🔹--//
  Future<void> ClearData(BuildContext context) async {
    isLoginLoading = false;
    EmailController.clear();
    myFocusNodeEmail.unfocus();
    PasswordController.clear();
    myFocusNodePassword.unfocus();
    // ✅ Only reset value, do NOT replace or dispose
    toggleCredential.value = false;
    notifyListeners();
  }
}

//-✅---------------------------------------------------------------------✅-//
