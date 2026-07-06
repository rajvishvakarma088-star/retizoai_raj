// ignore_for_file: file_names, use_build_context_synchronously, avoid_print, unnecessary_import
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class CashDrawerProvider extends ChangeNotifier {
  // 🔹 Drawer State
  CashDrawerData? _currentDrawer;
  bool _isDrawerLoading = false;
  String? _lastDrawerAction;
  List<Map<String, dynamic>> _methodSummary = [];

  // 🔹 Getters
  CashDrawerData? get currentDrawer => _currentDrawer;
  bool get isDrawerLoading => _isDrawerLoading;
  String? get lastDrawerAction => _lastDrawerAction;
  bool get isDrawerOpen => _currentDrawer?.isOpen ?? false;
  bool get isDrawerClosed => !isDrawerOpen;
  List<Map<String, dynamic>> get methodSummary => _methodSummary;

  // 🔹 Setters
  void _setDrawerLoading(bool value) {
    _isDrawerLoading = value;
    notifyListeners();
  }

  void _setDrawer(CashDrawerData? drawer) {
    _currentDrawer = drawer;
    notifyListeners();
  }

  void _setLastAction(String? action) {
    _lastDrawerAction = action;
    notifyListeners();
  }

  //-✅--Check Drawer Status-----------------------------------------------✅-//
  Future<void> checkDrawerStatus(
    BuildContext context, {
    bool silent = false,
  }) async {
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!silent) _setDrawerLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 API Request - GET /cash-drawer/ (check status)
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: GlobalServiceURL.CashDrawerUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (responseRaw is List) {
        // some backends return a top-level array
        if (responseRaw.isNotEmpty &&
            responseRaw.first is Map<String, dynamic>) {
          final drawerJson = responseRaw.first as Map<String, dynamic>;
          _setLastAction(null);
          _setDrawer(CashDrawerData.fromJson(drawerJson));
        }
        return;
      }

      if (responseRaw is List) {
        // some backends return a top-level array
        if (responseRaw.isNotEmpty &&
            responseRaw.first is Map<String, dynamic>) {
          _setLastAction(null);
          _setDrawer(
            CashDrawerData.fromJson(responseRaw.first as Map<String, dynamic>),
          );
        }
        return;
      }

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().debugFunction("❌ Invalid drawer status response");
        return;
      }

      final response = CashDrawerResponse.fromJson(responseRaw);
      _setLastAction(response.action);
      _setDrawer(response.drawer);
      _methodSummary = response.methodSummary;

      GlobalFunction().debugFunction(
        "✅ Drawer Status: ${response.drawer?.status ?? 'CLOSED'} | Action: ${response.action}",
      );
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error checking drawer status: $e");
      debugPrintStack(stackTrace: stack);
      _setDrawer(null);
      _setLastAction(null);
    } finally {
      if (!silent) _setDrawerLoading(false);
    }
  }

  //-✅--Open Drawer-------------------------------------------------------✅-//
  Future<bool> openDrawer(BuildContext context, String openingAmount) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      _setDrawerLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 API Request - POST /cash-drawer/ (open drawer)
      final dynamic responseRaw = await httpCtrl.request(
        method: 'POST',
        url: GlobalServiceURL.CashDrawerUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
        body: {"opening_amt": openingAmount},
      );

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().showError(context, "Invalid response from server");
        return false;
      }

      final response = CashDrawerResponse.fromJson(responseRaw);

      if (response.success) {
        _setDrawer(response.drawer);
        _setLastAction(response.action);
        GlobalFunction().debugFunction(
          "✅ Drawer Opened Successfully: Opening Amount = $openingAmount",
        );
        return true;
      } else {
        // if backend says already opened, drawer is currently open — sync state
        final msg = response.message?.toLowerCase() ?? '';
        final isAlreadyOpen =
            response.action == "ALREADY_OPEN" ||
            msg.contains('already') && msg.contains('open');
        if (isAlreadyOpen) {
          await checkDrawerStatus(context);
          if (!isDrawerOpen) {
            _currentDrawer = CashDrawerData(status: "OPEN");
            notifyListeners();
          }
          return true;
        }
        GlobalFunction().showError(
          context,
          response.message ?? "Failed to open drawer",
        );
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error opening drawer: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Error opening drawer: $e");
      return false;
    } finally {
      _setDrawerLoading(false);
    }
  }

  //-✅--Close Drawer------------------------------------------------------✅-//
  Future<bool> closeDrawer(
    BuildContext context, {
    required String cashIn,
    required String cashOut,
    required String countedClosingCash,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      _setDrawerLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 API Request — PATCH /cash-drawer/ (close drawer)
      final dynamic responseRaw = await httpCtrl.request(
        method: 'PATCH',
        url: GlobalServiceURL.CashDrawerUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
        body: {
          "cash_in": cashIn,
          "cash_out": cashOut,
          "counted_closing_cash": countedClosingCash,
        },
      );

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().showError(context, "Invalid response from server");
        return false;
      }

      final response = CashDrawerResponse.fromJson(responseRaw);

      if (response.success) {
        _setDrawer(response.drawer);
        _setLastAction(response.action);
        _methodSummary = response.methodSummary;
        GlobalFunction().debugFunction(
          "✅ Drawer Closed Successfully: Cash In = $cashIn, Cash Out = $cashOut, Counted = $countedClosingCash",
        );
        return true;
      } else {
        GlobalFunction().showError(
          context,
          response.message ?? "Failed to close drawer",
        );
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error closing drawer: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Error closing drawer: $e");
      return false;
    } finally {
      _setDrawerLoading(false);
    }
  }

  //-✅--Save Drawer State (Without Closing)-------------------------------✅-//
  Future<bool> saveDrawerState(
    BuildContext context, {
    required String cashIn,
    required String cashOut,
    required String countedClosingCash,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      _setDrawerLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 API Request - POST /cash-drawer/save-only (save without closing)
      final dynamic responseRaw = await httpCtrl.request(
        method: 'POST',
        url: GlobalServiceURL.CashDrawerSaveOnlyUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
        body: {
          "cash_in": cashIn,
          "cash_out": cashOut,
          "counted_closing_cash": countedClosingCash,
        },
      );

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().showError(context, "Invalid response from server");
        return false;
      }

      final response = CashDrawerResponse.fromJson(responseRaw);

      if (response.success) {
        _setDrawer(response.drawer);
        GlobalFunction().debugFunction(
          "✅ Drawer State Saved Successfully (Still Open)",
        );
        showCustomToast(
          context: context,
          message: response.message ?? "Drawer state saved successfully",
          backgroundColor: GlobalAppColor.ButtonColor,
        );
        return true;
      } else {
        GlobalFunction().showError(
          context,
          response.message ?? "Failed to save drawer state",
        );
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error saving drawer state: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Error saving drawer state: $e");
      return false;
    } finally {
      _setDrawerLoading(false);
    }
  }

  //-✅--Reopen Drawer-----------------------------------------------------✅-//
  Future<bool> reopenDrawer(BuildContext context) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      _setDrawerLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 API Request
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: GlobalServiceURL.CashDrawerReopenUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().showError(context, "Invalid response from server");
        return false;
      }

      final response = CashDrawerResponse.fromJson(responseRaw);

      // 🔹 Handle ALREADY_OPEN case (not really an error)
      if (response.action == "ALREADY_OPEN") {
        await checkDrawerStatus(context);
        showCustomToast(
          context: context,
          message: response.message ?? "Drawer is already open",
          backgroundColor: GlobalAppColor.ButtonColor,
        );
        return true;
      }

      if (response.success) {
        // Always re-fetch full drawer state so isDrawerOpen reflects correctly
        // (reopen endpoint may not return the full drawer object)
        await checkDrawerStatus(context);
        _setLastAction(response.action ?? "REOPEN_SUCCESS");
        GlobalFunction().debugFunction("✅ Drawer Reopened Successfully");
        if (context.mounted) {
          showCustomToast(
            context: context,
            message: response.message ?? "Drawer reopened successfully",
            backgroundColor: GlobalAppColor.ButtonColor,
          );
        }
        return true;
      } else {
        GlobalFunction().showError(
          context,
          response.message ?? "Failed to reopen drawer",
        );
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error reopening drawer: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Error reopening drawer: $e");
      return false;
    } finally {
      _setDrawerLoading(false);
    }
  }

  //-✅--Reset Drawer State------------------------------------------------✅-//
  void resetDrawerState() {
    _currentDrawer = null;
    _lastDrawerAction = null;
    _isDrawerLoading = false;
    _methodSummary = [];
    notifyListeners();
  }
}

//-✅---------------------------------------------------------------------✅-//
