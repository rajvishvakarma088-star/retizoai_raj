// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures, constant_identifier_names
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrintingDeviceProvider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:culai/ScreenSection/PostLogin/HomeScreen/Model/MultiPaymentEntry.dart';

//-✅-CheckInternetProvider-----------------------------------------------✅-//
class CheckInternetProvider with ChangeNotifier {
  bool? _isConnected;
  late StreamSubscription<ConnectivityResult> _subscription;

  CheckInternetProvider() {
    _initConnectivity();
  }

  bool get isConnected => _isConnected ?? true;

  bool? get initialStatus => _isConnected;

  void _initConnectivity() async {
    try {
      final initialResult = await Connectivity().checkConnectivity();
      _updateStatus(initialResult, notify: true); // notify immediately

      _subscription = Connectivity().onConnectivityChanged.listen(
        (result) => _updateStatus(result, notify: true),
      );
    } catch (e) {
      GlobalFunction().debugFunction("❌ Connectivity init error: $e");
    }
  }

  void _updateStatus(ConnectivityResult result, {bool notify = true}) {
    final newStatus = result != ConnectivityResult.none;
    if (_isConnected != newStatus) {
      _isConnected = newStatus;
      if (notify) notifyListeners();
      GlobalFunction().debugFunction(
        _isConnected == true
            ? "🌐 Internet Connected"
            : "🚫 Internet Disconnected",
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> openDeviceInternetSettings() async {
    try {
      if (kIsWeb) {
        GlobalFunction().debugFunction(
          "⚠️ Web platform — Cannot open settings.",
        );
        return;
      }
      if (Platform.isAndroid || Platform.isIOS) {
        await AppSettings.openAppSettings(type: AppSettingsType.wifi);
      } else {
        GlobalFunction().debugFunction("⚠️ Desktop not supported.");
      }
    } catch (e) {
      GlobalFunction().debugFunction("❌ Failed to open settings: $e");
    }
  }
}

//-✅-UserInfoProvider----------------------------------------------------✅-//
class UserInfoProvider with ChangeNotifier {
  UserModel? UserData;
  String? AccessToken;

  bool _hasPrintedUserInfo = false;

  //================== Getters ==================//
  UserModel? get getUserData => UserData;

  String? get getAccessToken => AccessToken;

  bool get isLoggedIn => AccessToken != null && UserData != null;

  //-- Strongly typed getters -------------------//
  String? get orgUserId => UserData?.orgUserId;

  String? get name => UserData?.name;

  String? get email => UserData?.email;

  String? get type => UserData?.type;

  String? get designation => UserData?.designation; // ⭐ Added now
  String? get orgId => UserData?.orgId;

  int? get branchId => UserData?.branchId;

  String? get orgName => UserData?.orgName;

  String? get branchName => UserData?.branchName;

  String? get appAccess => UserData?.appAccess;

  String? get status => UserData?.status;

  String? get picture => UserData?.picture; // ⭐ Already added

  //-- Permission Getter (Easy Access)
  Map<String, PermissionModel>? get permissions => UserData?.permissions;

  bool hasPermission(String module, String right) {
    final perm = permissions?[module];
    if (perm == null) return false;
    return perm.rights.contains(right);
  }

  //================== Save User Info ==================//
  Future<void> SaveUserInfo(
    BuildContext context,
    LoginResponseModel loginResponse,
  ) async {
    try {
      await SecureStorageService.ClearAll();

      UserData = loginResponse.user;
      AccessToken = loginResponse.token;

      await Future.wait([
        SecureStorageService.Write('UserData', UserData!.toJson()),
        SecureStorageService.Write('AccessToken', AccessToken ?? ''),
      ]);
      // ⭐ Complete JSON Print
      final userJson = jsonEncode(UserData!.toJson());
      final token = AccessToken ?? "No Token";

      GlobalFunction().debugFunction("🔑 Access Token: $token");
      GlobalFunction().debugFunction("👤 Full User JSON:\n$userJson");
      if (!_hasPrintedUserInfo) {
        GlobalFunction().debugFunction("📌 User Saved: ${UserData?.name}");
        _hasPrintedUserInfo = true;
      }

      notifyListeners();
    } catch (e) {
      GlobalFunction().debugFunction("❌ Error Saving User Info: $e");
    }
  }

  //================== Load User Info ==================//
  Future<void> LoadUserInfo() async {
    try {
      final result = await Future.wait([
        SecureStorageService.Read('UserData'),
        SecureStorageService.Read('AccessToken'),
      ]);

      if (result[0] != null && result[1] != null) {
        UserData = UserModel.fromJson(Map<String, dynamic>.from(result[0]));
        AccessToken = result[1].toString();
      }

      notifyListeners();
    } catch (e) {
      GlobalFunction().debugFunction("❌ Error Loading User Info: $e");
    }
  }

  //================== Refresh User Profile from /auth/me ==================//
  Future<void> refreshUserProfile(
    BuildContext context,
    HttpServiceProvider httpCtrl,
  ) async {
    try {
      final token = AccessToken ?? "";
      if (token.isEmpty) return;
      final authHeaders = APIHelper.buildAuthHeaders(token);
      final result = await httpCtrl.request(
        method: 'GET',
        url: GlobalServiceURL.AuthMeUrl,
        context: context,
        headers: authHeaders,
      );
      if (result is Map<String, dynamic> && result['success'] == true) {
        final userJson = result['user'] as Map<String, dynamic>?;
        if (userJson == null || UserData == null) return;
        UserData = UserModel.fromJson({...UserData!.toJson(), ...userJson});
        await SecureStorageService.Write('UserData', UserData!.toJson());
        GlobalFunction().debugFunction(
          "✅ /auth/me profile refreshed. VAT: ${UserData?.vatNo}",
        );
        notifyListeners();
      }
    } catch (e) {
      GlobalFunction().debugFunction(
        "⚠️ /auth/me refresh failed (non-fatal): $e",
      );
    }
  }

  //================== Logout ==================//
  Future<void> Logout() async {
    try {
      await SecureStorageService.ClearAll();
      UserData = null;
      AccessToken = null;
      _hasPrintedUserInfo = false;
      notifyListeners();
      GlobalFunction().debugFunction("🚪 Logged Out");
    } catch (e) {
      GlobalFunction().debugFunction("❌ Logout Error: $e");
    }
  }

  //================== Logout ==================//
  Future<void> Login(BuildContext context) async {
    GlobalFunction().debugFunction(appAccess.toString());
    if (appAccess == "both") {
      await CommonWidget().navigateToScreen(context, const DashBoard());
    } else if (appAccess == "order") {
      await CommonWidget().navigateToScreen(context, const HomeScreen());
    } else if (appAccess == "kds") {
      await CommonWidget().navigateToScreen(context, const Kds());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: navigatorKey.currentContext!,
          builder: (_) => ShowBottomSheet(
            msgTitle: "App is not for user type",
            button1Text: GlobalFlag.Close,
            button2Text: GlobalFlag.LogOut,
            BtnCondition: "LogOutApplication",
            icon: Icons.logout_sharp,
            iconColor: GlobalAppColor.WhiteColorCode,
            iconSize: 22,
          ),
        );
      });
    }
    notifyListeners();
  }
}

//-✅-BackGroundApiProvider-----------------------------------------------✅-//
class BackGroundApiProvider with ChangeNotifier {
  Future<void> BackGroundApiService(BuildContext context) async {
    final UserInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);
    // Load user info securely
    await UserInfoCtrl.LoadUserInfo();

    // Fetch user data
    final userData = UserInfoCtrl.UserData;
    final String orgUserId = userData?.orgUserId ?? "";
    final int branchId = userData?.branchId ?? 0;

    if (orgUserId.isNotEmpty || branchId != 0) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      if (!session.isSessionActive) {
        debugPrint("⚠️ Session inactive — skipping background API calls.");
        return;
      }

      final HomeCtrl = Provider.of<HomeProvider>(context, listen: false);
      final AddOrderCtrl = Provider.of<AddOrderProvider>(
        context,
        listen: false,
      );

      debugPrint("✅ Background API called after reconnect");
      await HomeCtrl.getOrderListService(
        context,
        HomeCtrl.selectedFilter,
        HomeCtrl.selectedDate.toString(),
      );
      await AddOrderCtrl.BasicAPI(context);

      // 🖨️ Refresh backend printing devices and auto-connect KDS printer
      // (fire-and-forget — any failure is non-fatal and logged internally)
      if (UserInfoCtrl.AccessToken != null) {
        final printingDeviceProvider = Provider.of<PrintingDeviceProvider>(
          context,
          listen: false,
        );
        printingDeviceProvider
            .fetchAndConnect(UserInfoCtrl.AccessToken!)
            .ignore();
      }
    }
    notifyListeners();
  }
}

//-✅-NumberInputProvider-------------------------------------------------✅-//
class NumberInputDiscountProvider extends ChangeNotifier {
  int _value = 0; // default 0
  int get value => _value;

  String get formattedValue => _value == 0 ? '' : _value.toString();

  // 🔹 Manual input
  void manualInput(BuildContext context, String input) {
    int newValue = int.tryParse(input) ?? 0;

    // Clamp value between 0–100
    newValue = newValue.clamp(0, 100);
    _value = newValue;

    GlobalFunction().debugFunction("💰 Discount Value (manual): $_value");
    notifyListeners();

    // Recalculate discount in AddOrderCtrl
    _calculateDiscount(context);
  }

  // 🔹 Increment value
  void increment(BuildContext context) {
    if (_value < 100) {
      _value++;
      GlobalFunction().debugFunction("💰 Discount Incremented: $_value");
      notifyListeners();

      _calculateDiscount(context);
    }
  }

  // 🔹 Decrement value
  void decrement(BuildContext context) {
    if (_value > 0) {
      _value--;
      GlobalFunction().debugFunction("💰 Discount Decremented: $_value");
      notifyListeners();

      _calculateDiscount(context);
    }
  }

  // 🔹 Reset discount
  void reset(BuildContext context) {
    _value = 0;
    GlobalFunction().debugFunction("💰 Discount Reset: $_value");
    notifyListeners();

    _calculateDiscount(context);
  }

  // 🔹 Private helper to calculate discount via AddOrderCtrl
  void _calculateDiscount(BuildContext context) {
    try {
      // Make sure your AddOrderProvider class name is correct here
      context.read<AddOrderProvider>().calculateDiscountAmount(context);
    } catch (e) {
      GlobalFunction().debugFunction("⚠️ Discount calc failed: $e");
    }
  }
}

//-✅-NumberInputPAXProvider----------------------------------------------✅-//
class NumberInputPAXProvider extends ChangeNotifier {
  int _value = 0; // default value
  int get value => _value;

  String get formattedValue => _value == 0 ? '' : _value.toString();

  void manualInput(String input) {
    // Remove non-digit characters
    String sanitized = input.replaceAll(RegExp(r'[^0-9]'), '');
    int newValue = int.tryParse(sanitized) ?? 0;
    if (newValue < 0) newValue = 0;
    if (newValue > 100) newValue = 100;
    _value = newValue;

    // 🔹 Print debug
    GlobalFunction().debugFunction(
      "📝 Manual InputPAX: $input -> Sanitized: $sanitized -> Value: $_value",
    );

    notifyListeners();
  }

  void increment() {
    if (_value < 100) {
      _value++;

      // 🔹 Print debug
      GlobalFunction().debugFunction("🔼 Incremented InputPAX: $_value");

      notifyListeners();
    }
  }

  void decrement() {
    if (_value > 0) {
      _value--;

      // 🔹 Print debug
      GlobalFunction().debugFunction("🔽 Decremented InputPAX: $_value");

      notifyListeners();
    }
  }

  void reset() {
    _value = 0;

    // 🔹 Print debug
    GlobalFunction().debugFunction("♻️ Reset InputPAX value: $_value");

    notifyListeners();
  }
}

//-✅-SessionProvider-----------------------------------------------------✅-//
class SessionProvider with ChangeNotifier {
  bool _isSessionActive = true;

  bool get isSessionActive => _isSessionActive;

  void setSessionActive(bool value) {
    if (_isSessionActive != value) {
      _isSessionActive = value;
      notifyListeners();
    }
  }

  void expireSession() {
    _isSessionActive = false;
    notifyListeners();
  }

  void restoreSession() {
    _isSessionActive = true;
    notifyListeners();
  }
}

//-✅-BottomNavProvider---------------------------------------------------✅-//
class BottomNavProvider with ChangeNotifier {
  static const int TabOrder = 0;
  static const int TabKds = 1;

  int SELECTED_INDEX = TabOrder;

  void changeTab(int newIndex) {
    if (SELECTED_INDEX == newIndex)
      return; // Jis tab me ho, dobara click par kuch nai karega
    SELECTED_INDEX = newIndex;
    notifyListeners();
  }
}

//-✅-CashAmountProvider---------------------------------------------------✅-//
class CashAmountProvider extends ChangeNotifier {
  double _value = 0.0;
  double _lastTotal = -1;

  final TextEditingController controller = TextEditingController();

  double get value => _value;
  String get formattedValue => _value.toStringAsFixed(2);

  void setFromTotal(double total) {
    if (_lastTotal != total) {
      _lastTotal = total;
      _value = total / 2;
      controller.text = formattedValue;
      notifyListeners();
    }
  }

  void manualInput(String v) {
    _value = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void increment() {
    _value++;
    controller.text = formattedValue;
    notifyListeners();
  }

  void decrement() {
    if (_value > 0) _value--;
    controller.text = formattedValue;
    notifyListeners();
  }
}

//-✅-CardAmountProvider---------------------------------------------------✅-//
class CardAmountProvider extends ChangeNotifier {
  double _value = 0.0;
  double _lastTotal = -1;

  final TextEditingController controller = TextEditingController();

  double get value => _value;
  String get formattedValue => _value.toStringAsFixed(2);

  void setFromTotal(double total) {
    if (_lastTotal != total) {
      _lastTotal = total;
      _value = total / 2;
      controller.text = formattedValue;
      notifyListeners();
    }
  }

  void manualInput(String v) {
    _value = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void increment() {
    _value++;
    controller.text = formattedValue;
    notifyListeners();
  }

  void decrement() {
    if (_value > 0) _value--;
    controller.text = formattedValue;
    notifyListeners();
  }
}

//-✅-CashAmountProvider---------------------------------------------------✅-//
class PayBillCashAmountProvider extends ChangeNotifier {
  double _value = 0.0;
  double _lastNetAmt = -1;

  final TextEditingController controller = TextEditingController();

  double get value => _value;
  String get formattedValue => _value.toStringAsFixed(2);

  void setFromNetAmt(double netAmt) {
    if (_lastNetAmt != netAmt) {
      _lastNetAmt = netAmt;

      _value = netAmt / 2;
      controller.text = formattedValue;
      notifyListeners();
    }
  }

  void manualInput(String v) {
    _value = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void increment() {
    _value++;
    controller.text = formattedValue;
    notifyListeners();
  }

  void decrement() {
    if (_value > 0) _value--;
    controller.text = formattedValue;
    notifyListeners();
  }
}

//-✅-CardAmountProvider---------------------------------------------------✅-//
class PayBillCardAmountProvider extends ChangeNotifier {
  double _value = 0.0;
  double _lastNetAmt = -1;

  final TextEditingController controller = TextEditingController();

  double get value => _value;
  String get formattedValue => _value.toStringAsFixed(2);

  void setFromNetAmt(double netAmt) {
    if (_lastNetAmt != netAmt) {
      _lastNetAmt = netAmt;

      _value = netAmt / 2;
      controller.text = formattedValue;
      notifyListeners();
    }
  }

  void manualInput(String v) {
    _value = double.tryParse(v) ?? 0.0;
    notifyListeners();
  }

  void increment() {
    _value++;
    controller.text = formattedValue;
    notifyListeners();
  }

  void decrement() {
    if (_value > 0) _value--;
    controller.text = formattedValue;
    notifyListeners();
  }
}

//-✅-MultiPaymentProvider------------------------------------------------✅-//
/// Manages multiple payment entries for multi-payment mode
class MultiPaymentProvider extends ChangeNotifier {
  List<MultiPaymentEntry> _entries = [];
  int _entryCounter = 0;

  List<MultiPaymentEntry> get entries => _entries;
  double get totalAmount => _entries.fold(0.0, (sum, e) => sum + e.amount);

  /// Check if all entries are complete and valid
  bool get allEntriesValid =>
      _entries.isNotEmpty && _entries.every((e) => e.isComplete);

  /// Initialize with one empty entry
  void initialize() {
    _entries = [_createNewEntry()];
    _entryCounter = 1;
    notifyListeners();
  }

  /// Add a new empty payment entry
  void addEntry() {
    _entries.add(_createNewEntry());
    notifyListeners();
  }

  /// Remove an entry by ID
  void removeEntry(String entryId) {
    if (_entries.length > 1) {
      _entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
    }
  }

  /// Update an entry's amount
  void updateAmount(String entryId, double amount) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(amount: amount);
      notifyListeners();
    }
  }

  /// Update an entry's payment method
  void updatePaymentMethod(
    String entryId,
    int methodId,
    String methodName,
    String methodType,
  ) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        paymentMethodId: methodId,
        paymentMethodName: methodName,
        paymentMethodType: methodType,
      );
      notifyListeners();
    }
  }

  /// Update an entry's remark
  void updateRemark(String entryId, String remark) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(remark: remark);
      notifyListeners();
    }
  }

  /// Clear all entries
  void clear() {
    _entries.clear();
    _entryCounter = 0;
    notifyListeners();
  }

  /// Create a new empty entry with unique ID
  MultiPaymentEntry _createNewEntry() {
    _entryCounter++;
    return MultiPaymentEntry(id: 'entry_$_entryCounter', amount: 0.0);
  }

  /// Validate total against payable amount
  bool validateTotal(double payableAmount) {
    return (totalAmount - payableAmount).abs() < 0.01; // Allow 1 cent tolerance
  }

  /// Get validation message
  String getValidationMessage(double payableAmount) {
    if (_entries.isEmpty) {
      return "Add at least one payment entry";
    }

    if (!allEntriesValid) {
      return "Complete all payment entries";
    }

    final diff = totalAmount - payableAmount;
    if (diff.abs() < 0.01) {
      return "✓ Ready to complete";
    } else if (diff > 0) {
      return "Total exceeds payable by ${diff.toStringAsFixed(2)} SAR";
    } else {
      return "Remaining: ${(-diff).toStringAsFixed(2)} SAR";
    }
  }
}

//-✅---------------------------------------------------------------------✅-//
