// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/HomeScreen/Model/NotificationsModel.dart';
import 'package:culai/ScreenSection/PostLogin/HomeScreen/Model/PaymentMethodsPayBillModel.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrintingDeviceProvider.dart';
import 'package:culai/services/printer_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

// In-memory logo cache — org logo never changes mid-session so we
// download once and reuse on every subsequent print (mirrors web browser cache).
String? _cachedLogoBase64;
String? _cachedLogoUrl;

/// Renders ZATCA TLV base64 string as a 120×120 QR PNG and returns base64.
/// Mirrors web: QRCode.toDataURL(payload) → resizeImageToBase64(120, 120) → addImage.
Future<String?> _generateQrPngBase64(String data) async {
  try {
    final painter = QrPainter(data: data, version: QrVersions.auto);
    final imageData = await painter.toImageData(120.0);
    if (imageData == null) return null;
    return base64Encode(imageData.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

//-✅---------------------------------------------------------------------✅-//
class HomeProvider with ChangeNotifier {
  //--🔹--Order Filter---------------------------------------------------🔹--//
  String selectedFilter = "current";
  bool isHomeLoading = false;
  String? payBillLoadingAction;

  String get selectedFilterValue => selectedFilter;

  bool get isHomeLoader => isHomeLoading;

  bool get isPayBillPayLoading =>
      isHomeLoading && payBillLoadingAction == 'pay';

  bool get isPayBillCompleteLoading =>
      isHomeLoading && payBillLoadingAction == 'complete';

  void updateSelectedFilter(String value) {
    if (selectedFilter != value) {
      selectedFilter = value;
      notifyListeners();
    }
  }

  void setHomeLoading(bool value) {
    if (isHomeLoading != value) {
      isHomeLoading = value;
      notifyListeners();
    }
  }

  //--🔹--Pending Refresh Flag-------------------------------------------🔹--//
  // ✅ Set by AddNewOrder after successful order creation.
  // HomeScreen listens and triggers InitializeData when this is true.
  bool _pendingRefresh = false;
  bool get pendingRefresh => _pendingRefresh;

  void setPendingRefresh(bool value) {
    _pendingRefresh = value;
    if (value) notifyListeners();
  }

  //--🔹--DropDownOne----------------------------------------------------🔹--//
  String? selectedDropDownOne;
  List<DropDownOneListModel> dropDownOneListing = [];

  List<DropDownOneListModel> get DropDownOne => dropDownOneListing;

  Future<void> loadDropDownOneList() async {
    final response = [
      {"id": 1, "Title": "Draft"},
      {"id": 2, "Title": "Ordered"},
      {"id": 3, "Title": "Preparing"},
      {"id": 4, "Title": "Prepared"},
      {"id": 5, "Title": "Served"},
      {"id": 6, "Title": "Completed"},
    ];

    dropDownOneListing = response.map(DropDownOneListModel.fromJson).toList();
    // 🔹 Default selected value (optional, for global filter)
    selectedDropDownOne = dropDownOneListing.isNotEmpty
        ? dropDownOneListing[0].title
        : null;
    notifyListeners();
  }

  void updateDropDownOne(String newValue) {
    selectedDropDownOne = newValue;
    notifyListeners();

    final selectedModel = dropDownOneListing.firstWhere(
      (item) => item.title == newValue,
      orElse: () => DropDownOneListModel(id: '', title: ''),
    );
    /*    GlobalFunction().debugFunction("✅ Selected Filter: $selectedDropDownOne");
    GlobalFunction().debugFunction(
      "🔍 Selected DropDownOne Json: ${selectedModel.toJson()}",
    );*/
  }

  //--🔹--DropDownTwo----------------------------------------------------🔹--//
  String? selectedDropDownTwo;
  List<DropDownTwoListModel> dropDownTwoListing = [];

  List<DropDownTwoListModel> get DropDownTwo => dropDownTwoListing;

  Future<void> loadDropDownTwoList() async {
    final response = [
      {"id": 1, "Title": "Normal"},
      {"id": 2, "Title": "High"},
      {"id": 3, "Title": "Urgent"},
    ];

    dropDownTwoListing = response.map(DropDownTwoListModel.fromJson).toList();
    // 🔹 Default selected value (optional, for global filter)
    selectedDropDownTwo = dropDownTwoListing.isNotEmpty
        ? dropDownTwoListing[0].title
        : null;
    notifyListeners();
  }

  void updateDropDownTwo(String newValue) {
    selectedDropDownTwo = newValue;
    notifyListeners();

    final selectedModel = dropDownTwoListing.firstWhere(
      (item) => item.title == newValue,
      orElse: () => DropDownTwoListModel(id: '', title: ''),
    );
    /*    GlobalFunction().debugFunction("✅ Selected Filter: $selectedDropDownTwo");
    GlobalFunction().debugFunction(
      "🔍 Selected DropDownTwo Json: ${selectedModel.toJson()}",
    );*/
  }

  //--🔹--Search Controller---------------------------------------------🔹--//
  TextEditingController SearchOrderController = TextEditingController();
  final FocusNode myFocusNodeSearchOrder = FocusNode();

  //--🔹--Order Listing-------------------------------------------------🔹--//
  List<OrderData> OrderListing = [];
  List<OrderData> filteredOrderListing = [];

  // ✅ Race-condition guard: each call gets a unique token;
  // if a newer call starts before this one finishes, this result is discarded.
  int _orderListRequestToken = 0;

  Future<void> getOrderListService(
    BuildContext context,
    String SelectedFilter,
    String SelectedDate, {
    bool silent = false,
  }) async {
    if (!context.mounted) return;

    // ✅ Capture token for this request; bump the counter so any older
    // in-flight request that arrives after us will be ignored.
    final int myToken = ++_orderListRequestToken;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // 🔹 Show loader only for manual refresh; silent (auto-refresh) skips skeleton
      if (!silent) {
        setHomeLoading(true);
        notifyListeners();
      }
      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        updateSelectedFilter(selectedFilter);
        OrderListing.clear();
        filteredOrderListing.clear();
        setHomeLoading(false);
        return;
      }

      // 🔹 API Request
      // Format date to YYYY-MM-DD only (remove timestamp)
      String formattedDate = SelectedDate;
      try {
        final parsedDate = DateTime.parse(SelectedDate);
        formattedDate =
            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (_) {
        // If parsing fails, use as-is
      }

      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url:
            "$OrderListService"
            "filter/orders?status=$SelectedFilter&date=$formattedDate",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Session check
      if (responseRaw is Map<String, dynamic> &&
          responseRaw.containsKey('success')) {
        final bool success = responseRaw['success'] ?? false;
        if (!success) {
          await CommonWidget.AlertSessionBottomSheet(context: context);
          setHomeLoading(false);
          return;
        }
      }

      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().showError(context, "Invalid API format");
        return;
      }

      // ✅ Stale-response guard: if a newer request has already started,
      // discard this (older) response to prevent out-of-order overwrites.
      if (myToken != _orderListRequestToken) return;

      final List<dynamic> dataList = responseRaw["data"] ?? [];
      // 🔹  list clear
      OrderListing.clear();
      filteredOrderListing.clear();
      // 🔹 Check: data empty or not empty
      if (dataList.isNotEmpty) {
        for (var item in dataList) {
          final order = OrderData.fromJson(item);
          OrderListing.add(order);

          // 🔍 DEBUG: Log order items to identify missing items
          if (order.details.isNotEmpty) {
            GlobalFunction().debugFunction(
              "📦 Order #${order.orderNo} has ${order.details.length} items:",
            );
            for (var detail in order.details) {
              GlobalFunction().debugFunction(
                "   - ${detail.product.mPName} (SAR ${detail.price}) × ${detail.quantity} = SAR ${detail.subtotal}",
              );
            }
            GlobalFunction().debugFunction(
              "   💰 Subtotal: SAR ${order.calculatedSubtotalStr} | Tax: SAR ${order.displayTotalTax.toStringAsFixed(2)} | Total: SAR ${order.grandTotal.toStringAsFixed(2)}",
            );
          }
        }
        filteredOrderListing = List.from(OrderListing);
      } else {
        OrderListing.clear();
        filteredOrderListing.clear();
      }
      // 🔹 Notify once after all processing
      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Order List: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //--🔹--Date Selection-------------------------------------------------🔹--//
  DateTime selectedDate = DateTime.now();

  void updateSelectedDate(BuildContext context, DateTime date) async {
    SearchOrderController.clear();
    selectedDate = date;

    filteredOrderListing = OrderListing.where((order) {
      try {
        final orderDate = DateTime.parse(order.orderDate.split(' ')[0]);
        return orderDate.year == selectedDate.year &&
            orderDate.month == selectedDate.month &&
            orderDate.day == selectedDate.day;
      } catch (_) {
        return false;
      }
    }).toList();

    // Reset dropdowns for filtered items
    for (var order in filteredOrderListing) {
      order.selectedDropDownOne = dropDownOneListing.isNotEmpty
          ? dropDownOneListing[0].title
          : null;
      order.selectedDropDownTwo = dropDownTwoListing.isNotEmpty
          ? dropDownTwoListing[0].title
          : null;
    }

    updateSelectedFilter(selectedFilter);
    GlobalFunction.hideKeyboard(context);
    SearchOrderController.clear();
    // Format date to YYYY-MM-DD
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    await getOrderListService(context, selectedFilter, formattedDate);
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    final minDate = DateTime(1970, 1, 1);
    final maxDate = DateTime.now();
    DateTime? pickedDate = selectedDate;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // ⭐ FIXED HEIGHT BASED ON ORIENTATION
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final dialogHeight = isLandscape
        ? screenHeight *
              0.85 // Landscape → more height
        : (screenHeight > 700 ? 420.0 : screenHeight * 0.55);

    pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(10),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          datePickerTheme: DatePickerThemeData(
                            dayBackgroundColor:
                                MaterialStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey.withOpacity(0.3);
                                  }
                                  if (states.contains(MaterialState.selected)) {
                                    return GlobalAppColor.ButtonColor;
                                  }
                                  if (states.contains(MaterialState.hovered)) {
                                    return GlobalAppColor.ButtonColor;
                                  }
                                  return null;
                                }),
                            dayForegroundColor:
                                MaterialStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey;
                                  }
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.black;
                                }),
                            dayShape:
                                MaterialStateProperty.resolveWith<
                                  OutlinedBorder?
                                >((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    );
                                  }
                                  return const CircleBorder();
                                }),
                            dayStyle: CommonWidget.CommonTitleTextStyle(),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: pickedDate!,
                          firstDate: minDate,
                          lastDate: maxDate,
                          onDateChanged: (date) {
                            setState(() => pickedDate = date);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CommonWidget().CustomElevatedButton(
                        backgroundColor: GlobalAppColor.ButtonColor.withOpacity(
                          .6,
                        ),
                        height: 45,
                        title: "Cancel",
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      CommonWidget().CustomElevatedButton(
                        height: 45,
                        title: "Done",
                        onPressed: () => Navigator.pop(context, pickedDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (pickedDate != null) {
      updateSelectedDate(context, pickedDate!);
    }
  }

  //--🔹--refreshFilteredOrders------------------------------------------🔹--//
  void SearchFilteredOrders({String? searchQuery}) {
    if (OrderListing.isEmpty) {
      filteredOrderListing = [];
      notifyListeners();
      return;
    }

    // 🔹 Step 1: Start with full list
    filteredOrderListing = List.from(OrderListing);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();

      filteredOrderListing = filteredOrderListing.where((order) {
        // 🔹 Dynamically convert order to map and search
        final Map<String, dynamic> orderMap = order.toJson();

        // 🔹 Flatten all fields into a single string (except details handled separately)
        String searchStr = orderMap.entries
            .where((e) => e.key != 'details') // skip details for now
            .map((e) => e.value?.toString().toLowerCase() ?? '')
            .join(' ');

        // 🔹 Include product names from order details
        final detailProducts = order.details
            .map((d) => d.product.mPName.toLowerCase())
            .join(' ');

        searchStr += ' $detailProducts';

        bool match = searchStr.contains(query);

        return match;
      }).toList();
    }

    notifyListeners();
  }

  //--🔹--PayBillButton--------------------------------------------------🔹--//
  OrderData? selectedOrder; // 🔹 Current selected order for payment panel
  bool _isPanelOpen = false;

  bool get isPanelOpen => _isPanelOpen;

  //-✅--PayBill Discount State------------------------------------------✅-//
  /// Editable discount percentage shown in the Pay Bill panel.
  /// Initialised from the order's stored discount_per when the panel opens.
  /// Locked by default; manager auth is required to change it.
  double _payBillDiscountPer = 0.0;
  bool _payBillDiscountUnlocked = false;
  final TextEditingController payBillDiscountController =
      TextEditingController();

  /// Pre-computed table charge for the currently-open Pay Bill order.
  /// Async-filled by [computePayBillTableCharge]; reset when panel opens/closes.
  double _payBillTableCharge = 0.0;

  /// Minimum spend for the currently-open Pay Bill order's table.
  /// Cached so [paymentTableChargeForOrder] can dynamically recompute the
  /// top-up charge when the manager changes the Pay Bill discount percentage,
  /// ensuring the minimum-spend rule is always enforced against the
  /// POST-discount subtotal.
  double _payBillMinimumSpend = 0.0;

  double get payBillDiscountPer => _payBillDiscountPer;
  bool get payBillDiscountUnlocked => _payBillDiscountUnlocked;

  void setPayBillDiscount(double percent) {
    _payBillDiscountPer = percent.clamp(0.0, 100.0);
    payBillDiscountController.text =
        _payBillDiscountPer == _payBillDiscountPer.truncateToDouble()
            ? _payBillDiscountPer.toInt().toString()
            : _payBillDiscountPer.toStringAsFixed(2);
    notifyListeners();
  }

  void setPayBillDiscountUnlocked(bool unlocked) {
    _payBillDiscountUnlocked = unlocked;
    notifyListeners();
  }

  /// Shows the manager password dialog and, if authorized, calls [onAuthorized].
  Future<void> showPayBillDiscountAuthDialog(
    BuildContext context, {
    required void Function() onAuthorized,
  }) async {
    final email =
        Provider.of<UserInfoProvider>(context, listen: false).email ?? '';
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String? errorMsg;

    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF5C5C8A),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manager Authorization',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD066)),
                  ),
                  child: Text(
                    'Applying a discount requires manager authorization. Enter your password to continue.',
                    style: CommonWidget.CommonTitleTextStyle(
                      color: const Color(0xFF7A5500),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'Password',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                    errorText: errorMsg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C5C8A),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      final pwd = passwordCtrl.text.trim();
                      if (pwd.isEmpty) {
                        setDlg(() => errorMsg = 'Please enter password');
                        return;
                      }
                      setDlg(() {
                        loading = true;
                        errorMsg = null;
                      });
                      try {
                        final response = await http
                            .post(
                              Uri.parse(GlobalServiceURL.preLoginUrl),
                              headers: {
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'email': email,
                                'password': pwd,
                              }),
                            )
                            .timeout(const Duration(seconds: 10));
                        final body = jsonDecode(response.body)
                            as Map<String, dynamic>?;
                        if (response.statusCode == 200 &&
                            (body?['success'] == true ||
                                body?['token'] != null)) {
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } else {
                          String msg =
                              body?['message']?.toString() ??
                              'Incorrect password. Try again.';
                          if (msg.toLowerCase().contains('email') ||
                              msg.toLowerCase().contains('password')) {
                            msg = 'Invalid manager password';
                          }
                          setDlg(() {
                            loading = false;
                            errorMsg = msg;
                          });
                        }
                      } catch (_) {
                        setDlg(() {
                          loading = false;
                          errorMsg = 'Verification failed. Check your connection.';
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Authorize',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );

    if (authorized == true) {
      setPayBillDiscountUnlocked(true);
      onAuthorized();
    }
  }

  // 🔹 Open panel with selected order data
  void openPanelWithData(OrderData order) {
    isPanelNotificationOpen = false;
    selectedOrder = order;
    _isPanelOpen = true;
    selectedTipsAmount = TipsAmountListing.isNotEmpty
        ? TipsAmountListing[1].title
        : null;
    selectedPaymentMethod = PaymentMethodListing.isNotEmpty
        ? PaymentMethodListing[0].title
        : null;
    resetAdjustState();
    tableOccupied = null;
    tableStatusMessage = '';
    isFetchingTableStatus = false;
    // ── Discount: seed from stored order value, always start locked ──
    _payBillDiscountPer =
        double.tryParse(order.discountPer.isNotEmpty ? order.discountPer : '0')
            ?? 0.0;
    _payBillDiscountUnlocked = false;
    payBillDiscountController.text =
        _payBillDiscountPer == _payBillDiscountPer.truncateToDouble()
            ? _payBillDiscountPer.toInt().toString()
            : _payBillDiscountPer.toStringAsFixed(2);
    _payBillTableCharge = 0.0; // reset so stale charge from a previous order is never shown
    _payBillMinimumSpend = 0.0;
    notifyListeners();
  }

  // 🔹 Close panel
  void closePanel() {
    _isPanelOpen = false;
    selectedOrder = null;
    resetAdjustState();
    tableOccupied = null;
    tableStatusMessage = '';
    // Reset discount state
    _payBillDiscountPer = 0.0;
    _payBillDiscountUnlocked = false;
    payBillDiscountController.clear();
    _payBillTableCharge = 0.0;
    _payBillMinimumSpend = 0.0;
    notifyListeners();
  }
  String? selectedTipsAmount;
  List<TipsAmountListModel> TipsAmountListing = [];

  List<TipsAmountListModel> get TipsAmount => TipsAmountListing;

  Future<void> loadTipsAmountList() async {
    final response = [
      {"id": 1, "Title": "1", "IconData": Symbols.credit_card},
      {"id": 2, "Title": "2", "IconData": Symbols.credit_card},
      {"id": 3, "Title": "5", "IconData": Symbols.credit_card},
      {"id": 4, "Title": "10", "IconData": Symbols.credit_card},
      {"id": 5, "Title": "15", "IconData": Symbols.credit_card},
      {"id": 6, "Title": "20", "IconData": Symbols.credit_card},
      {"id": 7, "Title": "No Tips", "IconData": Symbols.credit_card},
    ];

    TipsAmountListing = response
        .map((e) => TipsAmountListModel.fromJson(e))
        .toList();
    selectedTipsAmount = TipsAmountListing.isNotEmpty
        ? TipsAmountListing[1].title
        : null;
    notifyListeners();
  }

  void updateTipsAmount(String newValue) {
    selectedTipsAmount = newValue;
    notifyListeners();

    final selectedModel = TipsAmountListing.firstWhere(
      (item) => item.title == newValue,
      orElse: () =>
          TipsAmountListModel(id: '', title: '', icon: Icons.attach_money),
    );

    /*GlobalFunction().debugFunction("✅ Selected Filter: $selectedTipsAmount");
    GlobalFunction().debugFunction(
      "🔍 Selected TipsAmount Json: ${selectedModel.toJson()}",
    );*/
  }

  //--🔹--Payment-Method-------------------------------------------------🔹--//
  String? selectedPaymentMethod;
  List<PaymentMethodListModel> PaymentMethodListing = [];

  List<PaymentMethodListModel> get PaymentMethod => PaymentMethodListing;

  Future<void> loadPaymentMethodList() async {
    final response = [
      {"id": 1, "Title": "Cash"},
      {"id": 1, "Title": "Debit Card"},
      {"id": 1, "Title": "E-Wallet"},
    ];

    PaymentMethodListing = response
        .map((e) => PaymentMethodListModel.fromJson(e))
        .toList();
    selectedPaymentMethod = PaymentMethodListing.isNotEmpty
        ? PaymentMethodListing[1].title
        : null;
    notifyListeners();
  }

  void updatePaymentMethod(String newValue) {
    selectedPaymentMethod = newValue;
    notifyListeners();

    final selectedModel = PaymentMethodListing.firstWhere(
      (item) => item.title == newValue,
      orElse: () => PaymentMethodListModel(id: '', title: ''),
    );

    /*    GlobalFunction().debugFunction("✅ Selected Filter: $selectedPaymentMethod");
    GlobalFunction().debugFunction(
      "🔍 Selected PaymentMethod Json: ${selectedModel.toJson()}",
    );*/
  }

  //-✅--UpdatePriorityOrderStatusService---------------------------------✅-//
  Future<bool> UpdatePriorityOrderStatusService(
    BuildContext context,
    String OrderID,
    String Type,
    String OrderType,
  ) async {
    final userInfoCtrl = context.read<UserInfoProvider>();
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // ✅ Step 1: Internet Check (Safe)
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );

      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return false; // 🧠 Stop execution here — API will not call
      }
      setHomeLoading(true);
      notifyListeners();
      // ✅ Step 2: Prepare for API call
      if (!httpCtrl.isApiActive) {
        httpCtrl.startHttpClient();
        GlobalFunction().debugFunction("🌐 Http client started");
      }
      // 🔹 Step 3: Prepare request body
      final Map<String, dynamic> requestBody =
          OrderType.toLowerCase() == "priority"
          ? {"priority": Type.toLowerCase()}
          : {"order_status": Type.toLowerCase()};

      // ✅ Step 4: Call API
      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderListService$OrderID",
        context: context,
        body: requestBody,
        headers: authHeaders,
        requireLogin: true,
      );

      // ✅ Step 5: Handle Response
      final String message = response['message'] ?? "Unknown error";
      if (response.containsKey('order') && response['order'] != null) {
        // ✅ Order successfully updated
        showCustomToast(context: context, message: message);

        // 🔹 Optional: update local OrderListing / Provider if needed
        final updatedOrder = response['order'];
        // Example: update your OrderListing in provider
        // Clear search controller
        SearchOrderController.clear();
        myFocusNodeSearchOrder.unfocus();

        // Format date to YYYY-MM-DD
        final formattedDate =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        // Fetch orders fresh
        await getOrderListService(context, selectedFilter, formattedDate);
        notifyListeners();
        return true;
      } else if (message.toLowerCase().contains("order not found")) {
        // ⚠ Order not found
        PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", message);
        notifyListeners();
        return false;
      } else {
        // 🔹 Any other case (e.g. 400 "Please pay first")
        PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", message);
        notifyListeners();
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in Api Service: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(context: context, message: "Something Wring try again.");
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--DeleteOrderService-----------------------------------------------✅-//
  Future<void> DeleteOrderService(BuildContext context, String OrderID) async {
    if (!context.mounted) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      // 🔹 Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return;
      }

      setHomeLoading(true);
      notifyListeners();

      // 🔹 Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Step 3: Call API
      final response = await httpCtrl.request(
        method: 'DELETE',
        url: "$OrderListService$OrderID",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      final String message = response['message'] ?? "Unknown error";

      // 🔹 Step 4: Handle response

      if (message.toLowerCase().contains("order not found")) {
        // ⚠ Order not found
        PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", message);
      } else if (message.toLowerCase().contains("deleted successfully")) {
        // ✅ Order deleted successfully
        showCustomToast(context: context, message: message);

        // Clear search & unfocus
        SearchOrderController.clear();
        myFocusNodeSearchOrder.unfocus();
        Navigator.pop(context);

        // Format date to YYYY-MM-DD
        final formattedDate =
            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

        // Refresh order list
        await getOrderListService(context, selectedFilter, formattedDate);
      } else {
        // 🔹 Any other unexpected case
        PopupAlertHelper.showPopupFailedAlert(context, "Failed", "", message);
      }

      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in DeleteOrderService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Something went wrong. Try again.",
      );
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--GetOrderCountService--------------------------------------------✅-//
  String? PreparingCount;
  String? PreparedCount;

  Future<void> GetOrderCountService(BuildContext context) async {
    if (!context.mounted) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    final isOnlineProvider = context.read<CheckInternetProvider>();
    final isOnline = isOnlineProvider.isConnected;

    try {
      if (!isOnline) {
        GlobalFunction().debugFunction("🚫 Offline mode — API call skipped");
        return;
      }

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'GET',
        url:
            "${HomeCountsService}date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      final success = response['success'] as bool? ?? false;
      final data = response['data'] as Map<String, dynamic>?;

      if (success && data != null) {
        // 🔥 Direct map access (SAFE)
        PreparingCount = data["preparing"]?.toString() ?? "0";
        PreparedCount = data["prepared"]?.toString() ?? "0";

        notifyListeners();
      } else {
        GlobalFunction().debugFunction("⚠️ No data found or API failed.");
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Tickets List: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      notifyListeners();
    }
  }

  //--🔹--ViewAllNotificationButton--------------------------------------🔹--//
  bool isPanelNotificationOpen = false;

  bool get isNotificationPanelOpen => isPanelNotificationOpen;

  // 🔹 Open panel with selected order data
  void openNotificationPanelWithData() {
    _isPanelOpen = false;
    isPanelNotificationOpen = true;
    notifyListeners();
  }

  // 🔹 Close panel
  void closeNotificationPanel() {
    isPanelNotificationOpen = false;
    notifyListeners();
  }

  //-✅--GetNotificationListService----------------------------------------✅-//
  List<NotificationsData> NotificationListing = [];

  Future<void> GetNotificationListService(BuildContext context) async {
    if (!context.mounted) return;

    try {
      setHomeLoading(true);
      notifyListeners();

      // ── Primary source: build from already-loaded OrderListing ──
      // The /order-master/notifications/prepared API endpoint does not populate
      // its table when KDS marks items as "prepared", so we derive the list
      // directly from the order data that the home screen already has loaded.
      final List<NotificationsData> derived = [];
      for (final order in OrderListing) {
        for (final detail in order.details) {
          if (detail.status.toLowerCase() == 'prepared') {
            final String itemName = detail.product.mPName.isNotEmpty
                ? detail.product.mPName
                : (detail.name != 'N/A' ? detail.name : '');
            derived.add(
              NotificationsData(
                orderId: order.orderNo,
                tableId: order.tableId,
                customerName: order.customer,
                itemId: detail.orderDetId,
                itemName: itemName,
                quantity: detail.quantity,
                stationId: 0,
                preparedAt:
                    order.orderPreparedTime != 'N/A' &&
                        order.orderPreparedTime.isNotEmpty
                    ? order.orderPreparedTime
                    : order.orderDate,
                orderStatus: order.orderStatus,
                paymentStatus: order.paymentStatus,
                priority: order.priority,
              ),
            );
          }
        }
      }

      if (derived.isNotEmpty) {
        NotificationListing = derived;
        return;
      }

      // ── Fallback: attempt the dedicated notifications API ──
      final httpCtrl = context.read<HttpServiceProvider>();
      final isOnline = context.read<CheckInternetProvider>().isConnected;
      if (!isOnline) {
        NotificationListing = [];
        return;
      }

      final token = context.read<UserInfoProvider>().AccessToken ?? "";
      final authHeaders = APIHelper.buildAuthHeaders(token);
      final DateTime now = DateTime.now();
      final String todayDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String yesterdayISO = now
          .subtract(const Duration(days: 1))
          .toIso8601String();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'GET',
        url:
            "${HomeNotificationsListService}date=$todayDate&since=$yesterdayISO",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      final model = NotificationsListModel.fromJson(response);
      if (model.success && model.data.isNotEmpty) {
        NotificationListing = model.data;
      } else {
        NotificationListing = [];
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching notification list: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--CancelOrderItemService----------------------------------------✅-//
  Future<void> CancelOrderItemService(BuildContext context, String Url) async {
    if (!context.mounted) return;

    final isOnline = context.read<CheckInternetProvider>().isConnected;
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json', // optional but safe
    };

    try {
      // Loader ON
      setHomeLoading(true);
      notifyListeners();

      if (!isOnline) {
        return;
      }

      // ---- 🔥 POST REQUEST ----
      final uri = Uri.parse(Url);

      final response = await http.post(uri, headers: headers);

      debugPrint('Url: $Url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      // ---- 🔥 SAFE RESPONSE HANDLING ----
      bool success = false;
      String message = "Something went wrong";

      if (response.statusCode == 200) {
        final res = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        if (res != null) {
          success = res["success"] == true;
          message = res["message"]?.toString() ?? message;
        }
      } else {
        message = "Server error ${response.statusCode}";
      }

      if (success) {
        showCustomToast(context: context, message: message);
        // ✅ Targeted refresh — preserves current date/filter/search state
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        await GetOrderCountService(context);
      } else {
        showCustomToast(context: context, message: message);
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error CancelOrderItemService: $e");
      debugPrintStack(stackTrace: stack);

      showCustomToast(context: context, message: "Something went wrong");
    } finally {
      setHomeLoading(false);
      Navigator.pop(context);
      notifyListeners();
    }
  }

  //-✅--cancelOrderService (with password) ---------------------------✅-//
  /// POST /order-master/:orderId/cancel  body: {password}
  /// Matches web app handleCancelOrder flow exactly.
  Future<bool> cancelOrderService(
    BuildContext context,
    int orderId,
    String password,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'POST',
        url: '$BookingOrderService/$orderId/cancel',
        context: context,
        headers: authHeaders,
        body: {'password': password},
        requireLogin: true,
        ignoreUnauthorized: true, // ⚠️ Don't log out if manager password wrong
      );

      final bool success = response['success'] as bool? ?? false;
      String message = (response['message'] ?? 'Unknown error').toString();

      // 🔹 Show clearer error for wrong password
      if (!success &&
          (message.toLowerCase().contains('email') ||
              message.toLowerCase().contains('password'))) {
        message = 'Invalid manager password';
      }

      showCustomToast(context: context, message: message);

      if (success) {
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        await GetOrderCountService(context);
        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction('❌ Error in cancelOrderService: $e');
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: 'Failed to cancel order. Please try again.',
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--cancelItemService (with password + qty + reason) -------------✅-//
  /// POST /order-master/item/:itemId/cancel
  /// body: {password, cancel_quantity, cancel_reason}
  /// Matches web app handleCancelOrderItem flow exactly.
  Future<bool> cancelItemService(
    BuildContext context,
    int itemId,
    String password,
    int cancelQuantity,
    String cancelReason,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'POST',
        url: '$BookingOrderService/item/$itemId/cancel',
        context: context,
        headers: authHeaders,
        body: {
          'password': password,
          'cancel_quantity': cancelQuantity,
          'cancel_reason': cancelReason.trim(),
        },
        requireLogin: true,
        ignoreUnauthorized: true, // ⚠️ Don't log out if manager password wrong
      );

      final bool success = response['success'] as bool? ?? false;
      String message = (response['message'] ?? 'Unknown error').toString();

      // 🔹 Show clearer error for wrong password
      if (!success &&
          (message.toLowerCase().contains('email') ||
              message.toLowerCase().contains('password'))) {
        message = 'Invalid manager password';
      }

      showCustomToast(context: context, message: message);

      if (success) {
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        await GetOrderCountService(context);
        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction('❌ Error in cancelItemService: $e');
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: 'Failed to cancel item. Please try again.',
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--DeleteOrderItemService (NEW - Production)---------------------✅-//
  /// 🔹 Delete a single order item using RESTful DELETE method
  /// 📍 Standardized implementation for proper order item deletion
  Future<bool> deleteOrderItemService(
    BuildContext context,
    int orderDetailId,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      // 🔹 Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return false;
      }

      setHomeLoading(true);
      notifyListeners();

      // 🔹 Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Step 3: API Call - DELETE request
      final response = await httpCtrl.request(
        method: 'DELETE',
        url: "$OrderNowService$orderDetailId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Step 4: Parse Response
      final String message =
          (response['message'] ?? 'Item deleted successfully')
              .toString()
              .trim();

      showCustomToast(context: context, message: message);

      // 🔹 Step 5: Refresh order list
      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      await getOrderListService(context, selectedFilter, formattedDate);

      return true;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in deleteOrderItemService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to delete item. Please try again.",
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--GetOrderDetailsByOrderService (NEW - Production)---------------✅-//
  /// 🔹 Get all order items for a specific order
  /// 📍 Used for editing orders - loads all items of the selected order
  List<OrderDetail> orderDetailsForEdit = [];

  Future<List<OrderDetail>> getOrderDetailsByOrderService(
    BuildContext context,
    int orderId,
  ) async {
    if (!context.mounted) return [];

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      // 🔹 Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return [];
      }

      setHomeLoading(true);
      notifyListeners();

      // 🔹 Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Step 3: API Call - GET order details by order ID
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderDetailsByOrderService$orderId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Step 4: Parse Response
      if (responseRaw is! List) {
        GlobalFunction().debugFunction(
          "⚠️ Unexpected response format for order details",
        );
        return [];
      }

      // 🔹 Clear previous data
      orderDetailsForEdit.clear();

      // 🔹 Convert response to OrderDetail list
      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        GlobalFunction().debugFunction(
          "ℹ️ No order details found for order $orderId",
        );
        return [];
      }

      // 🔹 Map to OrderDetail model
      orderDetailsForEdit = records.map((e) {
        return OrderDetail.fromJson(e);
      }).toList();

      GlobalFunction().debugFunction(
        "✅ Loaded ${orderDetailsForEdit.length} items for order $orderId",
      );

      notifyListeners();
      return orderDetailsForEdit;
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        "❌ Error in getOrderDetailsByOrderService: $e",
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to load order items. Please try again.",
      );
      return [];
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--GetOrderDescriptionService (NEW - Production)------------------✅-//
  /// 🔹 Get complete order information with all details
  /// 📍 Used before payment processing to ensure accurate data
  OrderData? orderDescriptionData;

  Future<OrderData?> getOrderDescriptionService(
    BuildContext context,
    int orderId,
  ) async {
    if (!context.mounted) return null;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      // 🔹 Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return null;
      }

      setHomeLoading(true);
      notifyListeners();

      // 🔹 Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Step 3: API Call - GET order description
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderDescriptionService$orderId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Step 4: Parse Response
      if (responseRaw is! Map<String, dynamic>) {
        GlobalFunction().debugFunction(
          "⚠️ Unexpected response format for order description",
        );
        return null;
      }

      // 🔹 Convert to OrderData model
      orderDescriptionData = OrderData.fromJson(responseRaw);

      GlobalFunction().debugFunction(
        "✅ Loaded order description for order #${orderDescriptionData?.orderNo}",
      );

      notifyListeners();
      return orderDescriptionData;
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        "❌ Error in getOrderDescriptionService: $e",
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to load order details. Please try again.",
      );
      return null;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--UpdateOrderItemService (NEW - Production)----------------------✅-//
  /// Update an existing order item (quantity, note, status, etc.)
  /// PUT /api/order-details/{id}
  ///
  /// @param orderDetailId - The order detail ID to update
  /// @param qty - New quantity (optional)
  /// @param note - Order note/special instructions (optional)
  /// @param status - Order status: "ordered", "preparing", "served" (optional)
  /// @param rate - New rate/price (optional)
  /// @returns bool - true if updated successfully
  Future<bool> updateOrderItemService(
    BuildContext context,
    int orderDetailId, {
    int? qty,
    String? note,
    String? status,
    double? rate,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setHomeLoading(false);
        return false;
      }

      GlobalFunction().debugFunction(
        "ℹ️ Updating order item #$orderDetailId...",
      );

      // Build request body with only provided fields
      Map<String, dynamic> requestBody = {};
      if (qty != null) requestBody['qty'] = qty;
      if (note != null) requestBody['note'] = note;
      if (status != null) requestBody['status'] = status;
      if (rate != null) {
        requestBody['rate'] = rate;
        if (qty != null) {
          requestBody['net_amt'] = qty * rate;
        }
      }

      final dynamic responseRaw = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderDetailByIdService$orderDetailId",
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      if (!context.mounted) return false;

      if (responseRaw is Map<String, dynamic>) {
        // ✅ FIX: Support both response formats
        // Backend returns: { "errorCode": "SUCCESS", ... }
        // Other endpoints return: { "success": true, ... }
        final String errorCode = responseRaw['errorCode']?.toString() ?? '';
        final bool success =
            errorCode == 'SUCCESS' || responseRaw['success'] == true;

        if (success) {
          GlobalFunction().debugFunction(
            "✅ Order item #$orderDetailId updated successfully",
          );

          showCustomToast(
            context: context,
            message: "Item updated successfully!",
          );

          // Refresh order list to show updated data
          if (context.mounted) {
            final formattedDate =
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
            await getOrderListService(context, selectedFilter, formattedDate);
          }

          return true;
        }
      }

      GlobalFunction().debugFunction("❌ Failed to update order item");

      showCustomToast(context: context, message: "Failed to update item");
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in updateOrderItemService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to update item. Please try again.",
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--UpdateItemNoteService------------------------------------------✅-//
  /// PATCH /api/order-details/notes?orderId={orderId}&order_det_id={orderDetId}
  /// body: {"notePayload": {"note": "..."}}
  Future<bool> updateItemNoteService(
    BuildContext context,
    int orderId,
    int orderDetId,
    String note,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final dynamic responseRaw = await httpCtrl.request(
        method: 'PATCH',
        url:
            "$OrderDetailNoteService?orderId=$orderId&order_det_id=$orderDetId",
        context: context,
        headers: authHeaders,
        body: {
          "notePayload": {"note": note},
        },
        requireLogin: true,
      );

      if (!context.mounted) return false;

      if (responseRaw is Map<String, dynamic>) {
        final String errorCode = responseRaw['errorCode']?.toString() ?? '';
        final bool success =
            errorCode == 'SUCCESS' || responseRaw['success'] == true;

        if (success) {
          showCustomToast(context: context, message: "Note saved!");
          final formattedDate =
              "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
          await getOrderListService(context, selectedFilter, formattedDate);
          return true;
        }
      }

      showCustomToast(context: context, message: "Failed to save note");
      return false;
    } catch (e) {
      GlobalFunction().debugFunction("❌ Error in updateItemNoteService: $e");
      showCustomToast(
        context: context,
        message: "Failed to save note. Please try again.",
      );
      return false;
    }
  }

  //-✅--GetOrderDetailByIdService (NEW - Production)-------------------✅-//
  /// Load a single order detail/item by its ID
  /// GET /api/order-details/{id}
  ///
  /// @param orderDetailId - The order detail ID
  /// @returns OrderDetail? - The order detail object or null
  OrderDetail? singleOrderDetail;

  Future<OrderDetail?> getOrderDetailByIdService(
    BuildContext context,
    int orderDetailId,
  ) async {
    if (!context.mounted) return null;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setHomeLoading(false);
        return null;
      }

      GlobalFunction().debugFunction(
        "ℹ️ Loading order detail #$orderDetailId...",
      );

      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderDetailByIdService$orderDetailId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (!context.mounted) return null;

      if (responseRaw is Map<String, dynamic>) {
        final data = responseRaw['data'];
        if (data != null) {
          singleOrderDetail = OrderDetail.fromJson(data);

          GlobalFunction().debugFunction(
            "✅ Loaded order detail #$orderDetailId - Product: ${singleOrderDetail?.product.mPName}",
          );

          notifyListeners();
          return singleOrderDetail;
        }
      }

      GlobalFunction().debugFunction("❌ Failed to load order detail");

      showCustomToast(context: context, message: "Failed to load item details");
      return null;
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        "❌ Error in getOrderDetailByIdService: $e",
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to load item details. Please try again.",
      );
      return null;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--GetOrderDetailsByBranchService (NEW - Production)--------------✅-//
  /// Load all order details for the current branch.
  /// GET /api/order-details/branch/{branch_id}
  /// Useful for reports, analytics, or admin views.
  ///
  /// [branchId] - The branch ID.
  /// Returns List of all order details for the branch.
  List<OrderDetail> branchOrderDetails = [];

  Future<List<OrderDetail>> getOrderDetailsByBranchService(
    BuildContext context,
    int branchId,
  ) async {
    if (!context.mounted) return [];

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setHomeLoading(false);
        return [];
      }

      GlobalFunction().debugFunction(
        "ℹ️ Loading all order details for branch #$branchId...",
      );

      // Clear previous data
      branchOrderDetails.clear();

      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderDetailsByBranchService$branchId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (!context.mounted) return [];

      if (responseRaw is Map<String, dynamic>) {
        final dataList = responseRaw['data'];
        if (dataList is List) {
          branchOrderDetails = dataList
              .map((item) => OrderDetail.fromJson(item))
              .toList();

          GlobalFunction().debugFunction(
            "✅ Loaded ${branchOrderDetails.length} order details for branch #$branchId",
          );

          notifyListeners();
          return branchOrderDetails;
        }
      }

      GlobalFunction().debugFunction("❌ Failed to load branch order details");

      showCustomToast(
        context: context,
        message: "Failed to load order details",
      );
      return [];
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        "❌ Error in getOrderDetailsByBranchService: $e",
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to load order details. Please try again.",
      );
      return [];
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  // 🔹 API: getPayBillPaymentMethodsListService
  List<PaymentMethodsPayBillModel> PayBillPaymentListing = [];

  List<PaymentMethodsPayBillModel> get PayBillPayment => PayBillPaymentListing;

  String? PayMethodID;
  String? PayMethodName;
  String? PayMethodType;
  PaymentMethodsPayBillModel? selectedPaymentMethodsData; // Selected Model
  Future<void> getPayBillPaymentMethodsListService(BuildContext context) async {
    PayBillPaymentListing = [];
    PayMethodID = null;
    PayMethodName = null;
    PayMethodType = null;
    selectedPaymentMethodsData = null;
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        PayBillPaymentListing.clear();
        return;
      }
      setHomeLoading(true);
      notifyListeners();
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: PayBillPaymentListService,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Reset old list
      PayBillPaymentListing.clear();

      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        GlobalFunction().debugFunction("ℹ️ No tables found.");
        return;
      }

      PayBillPaymentListing = records
          .map((e) => PaymentMethodsPayBillModel.fromJson(e))
          .toList();
      // ===== AUTO SELECT FIRST VALUE =====
      if (PayBillPaymentListing.isNotEmpty) {
        selectedPaymentMethodsData = PayBillPaymentListing.first;
        PayMethodID = selectedPaymentMethodsData!.payMId.toString();
        PayMethodName = selectedPaymentMethodsData!.name;
        PayMethodType = selectedPaymentMethodsData!.type;
      } else {
        PayBillPaymentListing = [];
        selectedPaymentMethodsData = null;
        PayMethodID = null;
        PayMethodName = null;
        PayMethodType = null;
      }
      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Charges List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load charges");
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling
  void updatedDPOrderPaymentMethods(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      PayMethodID = null;
      PayMethodName = null;
      PayMethodType = null;
      selectedPaymentMethodsData = null;
      //GlobalFunction().debugFunction("⚠️ No charge selected");
      notifyListeners();
      return;
    }

    final selectedModel = PayBillPaymentListing.firstWhere(
      (item) => item.name == newValue,
      orElse: () => PaymentMethodsPayBillModel(),
    );

    PayMethodID = selectedModel.payMId.toString();
    PayMethodName = selectedModel.name;
    PayMethodType = selectedModel.type;
    selectedPaymentMethodsData = selectedModel;

    GlobalFunction().debugFunction(
      "✅ Selected Payment Methods ID: $PayMethodID",
    );
    GlobalFunction().debugFunction(
      "✅ Selected PaymentMethods Name: $PayMethodName",
    );
    GlobalFunction().debugFunction(
      "✅ Selected PaymentMethods Type: $PayMethodType",
    );
    GlobalFunction().debugFunction(
      "🔍 Selected PaymentMethods JSON: ${selectedModel.toJson()}",
    );

    // ✅ AUTO-SPLIT PAYMENT AMOUNTS (Fix Issue #3)
    // When SPLIT payment method is selected, automatically divide total 50-50
    if (PayMethodType?.toUpperCase() == "SPLIT" &&
        selectedOrder?.fullPayableTotal != null) {
      final payableAmount = selectedOrder!.fullPayableTotal;

      // Get providers from context - we'll set this from the widget
      // For now, store the amount to be set when widget rebuilds
      GlobalFunction().debugFunction(
        "💰 Auto-splitting amount: $payableAmount -> ${payableAmount / 2} each",
      );
    }

    notifyListeners();
  }

  //-✅--PayBillPaymentServiceAPI----------------------------------------✅-//
  double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));
  double _roundGrandTotal(double value) => normalizeFormattedAmount(value);

  double paymentTableChargeForOrder(BuildContext context, OrderData? order) {
    if (order == null) return 0.0;

    // When the panel has a cached minimum-spend value, recompute the table
    // charge dynamically — the shortfall must be measured against the
    // POST-discount subtotal so the minimum-spend rule holds even when the
    // manager applies a Pay Bill discount.
    if (_payBillMinimumSpend > 0) {
      final origSubtotal =
          order.calculatedSubtotal + (double.tryParse(order.discountAmt) ?? 0.0);
      final subtotalAfterDiscount = _payBillDiscountPer > 0
          ? origSubtotal * (1.0 - _payBillDiscountPer / 100.0)
          : order.calculatedSubtotal;
      // Minimum-spend shortfall is measured against the post-discount item
      // subtotal ONLY. Adjustments (Addition/Deduction) are separate and must
      // NOT reduce the shortfall — they are added on top of the grand total.
      final shortfall = _payBillMinimumSpend - subtotalAfterDiscount;
      return shortfall > 0 ? _roundMoney(shortfall) : 0.0;
    }

    // Pre-computed async table charge (set by computePayBillTableCharge) takes priority.
    if (_payBillTableCharge > 0) return _payBillTableCharge;

    // If the backend already has a table charge, keep using that stored value.
    if (order.tableCharge > 0) return _roundMoney(order.tableCharge);

    // Handle both 'Dine In' (app-created) and 'dine-in' (web-created) order types.
    if (!order.type.toLowerCase().contains('dine') || order.tableId <= 0) {
      return 0.0;
    }

    final addOrderCtrl = context.read<AddOrderProvider>();
    final matchingTables = addOrderCtrl.OrderTableListing.where(
      (table) => table.tableID == order.tableId,
    );
    if (matchingTables.isEmpty) return 0.0;

    final table = matchingTables.first;
    if (!table.isPremium) return 0.0;

    final fixedCharge = table.tableChargeAmount;
    final minimumSpend = table.minimumSpendAmount;
    if (minimumSpend <= 0) return _roundMoney(fixedCharge);

    // Fallback path: apply discount to subtotal before computing the shortfall
    // so the minimum-spend rule is correctly enforced here too.
    // Adjustments (Addition/Deduction) are NOT included — they are added on top.
    final origSubtotal =
        order.calculatedSubtotal + (double.tryParse(order.discountAmt) ?? 0.0);
    final subtotalAfterDiscount = _payBillDiscountPer > 0
        ? origSubtotal * (1.0 - _payBillDiscountPer / 100.0)
        : order.calculatedSubtotal;
    final shortfall = minimumSpend - subtotalAfterDiscount;
    return shortfall > 0 ? _roundMoney(shortfall) : 0.0;
  }

  /// Asynchronously computes the table charge for [order] and caches it in
  /// [_payBillTableCharge]. Call this when the Pay Bill panel opens so the
  /// charge is available even for unpaid orders where [order.tableCharge]
  /// has not yet been persisted by the backend.
  Future<void> computePayBillTableCharge(
    BuildContext context,
    OrderData order,
  ) async {
    // Quick path: backend already stored the charge on the order.
    if (order.tableCharge > 0) {
      _payBillTableCharge = _roundMoney(order.tableCharge);
      notifyListeners();
      return;
    }
    // Non-dine-in or no table — charge is always 0.
    // Handle both 'Dine In' (app-created) and 'dine-in' (web-created) order types.
    if (!order.type.toLowerCase().contains('dine') || order.tableId <= 0) {
      return;
    }
    if (!context.mounted) return;
    final addOrderCtrl = context.read<AddOrderProvider>();
    // Load table data if not yet available.
    if (addOrderCtrl.OrderTableListing.isEmpty) {
      await addOrderCtrl.getOrderTableListService(context);
    }
    if (!context.mounted) return;
    final matchingTables = addOrderCtrl.OrderTableListing.where(
      (t) => t.tableID == order.tableId,
    );
    if (matchingTables.isEmpty) return;
    final table = matchingTables.first;
    if (!table.isPremium) return;
    final fixedCharge = table.tableChargeAmount;
    final minimumSpend = table.minimumSpendAmount;
    if (minimumSpend <= 0) {
      _payBillTableCharge = _roundMoney(fixedCharge);
      notifyListeners();
      return;
    }
    // Cache the minimum spend so paymentTableChargeForOrder can dynamically
    // recompute the shortfall against the post-discount subtotal whenever
    // the manager changes the Pay Bill discount percentage.
    _payBillMinimumSpend = minimumSpend;
    // Shortfall is against item subtotal ONLY — adjustments are not included.
    final shortfall = minimumSpend - order.calculatedSubtotal;
    _payBillTableCharge = shortfall > 0 ? _roundMoney(shortfall) : 0.0;
    notifyListeners();
  }

  double payableTotalForOrder(BuildContext context, OrderData? order) {
    if (order == null) return 0.0;
    final adjust = double.tryParse(order.adjustAmt) ?? 0.0;
    final tableCharge = paymentTableChargeForOrder(context, order);

    // order.calculatedSubtotal (= total_amt) is already POST-discount.
    // (Backend stores total_amt = subtotal - discount_amt.)
    // Always recover the original pre-discount subtotal so we apply the
    // manager-entered rate to the right base (handles 0% correctly too).
    final originalSubtotal =
        order.calculatedSubtotal +
        (double.tryParse(order.discountAmt) ?? 0.0);
    if (_payBillDiscountPer > 0) {
      final newDiscountAmt = (originalSubtotal * _payBillDiscountPer) / 100.0;
      return _roundGrandTotal(
          originalSubtotal - newDiscountAmt + adjust + tableCharge);
    }
    return _roundGrandTotal(originalSubtotal + adjust + tableCharge);
  }

  double remainingPayableForOrder(BuildContext context, OrderData? order) {
    if (order == null) return 0.0;
    // Reuse payableTotalForOrder so the discount is reflected correctly
    final discountedTotal = payableTotalForOrder(context, order);
    return _roundMoney(
      (discountedTotal - order.totalPaidAmount).clamp(0.0, double.infinity),
    );
  }

  String _tableDisplayName(OrderData order) {
    if (order.tableName != 'N/A' && order.tableName.trim().isNotEmpty) {
      return order.tableName;
    }
    if (order.tableId > 0) {
      return 'T${order.tableId.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  Future<void> PayBillPaymentServiceAPI(
    BuildContext context, {
    bool markCompleted = false,
  }) async {
    GlobalFunction().debugFunction("====PayBillPaymentServiceAPI====");
    if (!context.mounted) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final UserInfoCtrl = context.read<UserInfoProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    final PayBillCashAmountCtrl = context.read<PayBillCashAmountProvider>();
    final PayBillCardAmountCtrl = context.read<PayBillCardAmountProvider>();
    final MultiPaymentCtrl = context.read<MultiPaymentProvider>();

    try {
      // ✅ VALIDATION: Check payment method specific requirements
      // Check type AND name to handle methods named "Split Payment" with type "SPLIT"
      final bool isSplit =
          PayMethodName.toString().toUpperCase() == "SPLIT" ||
          PayMethodType?.toUpperCase() == "SPLIT";
      final bool isMultiPayment =
          PayMethodName.toString().toUpperCase() == "MULTI-PAYMENT" ||
          PayMethodName.toString().toUpperCase() == "MULTI" ||
          PayMethodType?.toUpperCase() == "MULTI-PAYMENT" ||
          PayMethodType?.toUpperCase() == "MULTI";
      final double fullPayableAmt = payableTotalForOrder(
        context,
        selectedOrder,
      );

      final double refundAmt = ((selectedOrder?.totalPaidAmount ?? 0.0) - fullPayableAmt).clamp(0.0, double.infinity);
      final bool isRefund = refundAmt > 0.01;

      // ✅ CRITICAL FIX: For partial payment orders, use remaining balance instead of full amount
      final bool isPartialPayment =
          selectedOrder?.paymentStatus.toLowerCase() == 'partial';
      final double amountToPay = isPartialPayment
          ? remainingPayableForOrder(context, selectedOrder)
          : fullPayableAmt;

      print('💰 Pay Bill Calculation:');
      print('   Order #${selectedOrder?.orderNo}');
      print('   Payment Status: ${selectedOrder?.paymentStatus}');
      print('   Full Payable Amount: SAR ${fullPayableAmt.toStringAsFixed(2)}');
      if (isPartialPayment) {
        print(
          '   Total Paid Already: SAR ${selectedOrder?.totalPaidAmount.toStringAsFixed(2)}',
        );
        print(
          '   ✅ Amount to Pay (Remaining): SAR ${amountToPay.toStringAsFixed(2)}',
        );
      } else {
        print('   Amount to Pay: SAR ${amountToPay.toStringAsFixed(2)}');
      }

      // Parse numeric amounts safely
      double parseAmt(String? v) => double.tryParse(v ?? '0') ?? 0.0;

      // ✅ SPLIT PAYMENT VALIDATION (validate against remaining balance for partial orders)
      if (isSplit) {
        final double cashAmt = parseAmt(
          PayBillCashAmountCtrl.controller.text.trim(),
        );
        final double cardAmt = parseAmt(
          PayBillCardAmountCtrl.controller.text.trim(),
        );
        final double splitTotal = cashAmt + cardAmt;
        final double difference = (splitTotal - amountToPay).abs();

        if (cashAmt <= 0 && cardAmt <= 0) {
          showCustomToast(
            context: context,
            message: "Please enter cash and card amounts for split payment",
          );
          return;
        }

        if (difference > 0.01) {
          showCustomToast(
            context: context,
            message:
                "Split total (${splitTotal.toStringAsFixed(2)}) doesn't match ${isPartialPayment ? 'remaining balance' : 'payable amount'} (${amountToPay.toStringAsFixed(2)})",
          );
          return;
        }
      }

      // ✅ MULTI-PAYMENT VALIDATION (validate against remaining balance for partial orders)
      if (isMultiPayment) {
        if (MultiPaymentCtrl.entries.isEmpty) {
          showCustomToast(
            context: context,
            message: "Please add at least one payment entry",
          );
          return;
        }

        if (!MultiPaymentCtrl.allEntriesValid) {
          showCustomToast(
            context: context,
            message:
                "Please complete all payment entries (amount and method required)",
          );
          return;
        }

        if (!MultiPaymentCtrl.validateTotal(amountToPay)) {
          final diff = MultiPaymentCtrl.totalAmount - amountToPay;
          final amountLabel = isPartialPayment
              ? 'remaining balance'
              : 'payable amount';
          final message = diff > 0
              ? "Multi-payment total exceeds $amountLabel by ${diff.toStringAsFixed(2)} SAR"
              : "Multi-payment total is short by ${(-diff).toStringAsFixed(2)} SAR";
          showCustomToast(context: context, message: message);
          return;
        }
      }

      // ✅ Loader ON
      GlobalFunction.hideKeyboard(context);
      payBillLoadingAction = markCompleted ? 'complete' : 'pay';
      setHomeLoading(true);
      notifyListeners();

      // ✅ Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        setHomeLoading(false);
        return;
      }

      // ✅ Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) {
        httpCtrl.startHttpClient();
        GlobalFunction().debugFunction("🌐 Http client started");
      }

      // ✅ Step 3: Prepare Request Body (full production body)
      // Send as double (number) so backend can parse and create individual Cash/Card payment entries
      final double cashoutVal = isSplit
          ? (double.tryParse(PayBillCashAmountCtrl.controller.text.trim()) ??
                0.0)
          : 0.0;
      final double cardoutVal = isSplit
          ? (double.tryParse(PayBillCardAmountCtrl.controller.text.trim()) ??
                0.0)
          : 0.0;

      // Use the live PayBill discount (seeded from order on panel open, editable by manager).
      // Do NOT fall back to the stored order value — 0 is a valid explicit user intent.
      final double discountPer = _payBillDiscountPer;
      // Discount must be calculated on the ORIGINAL pre-discount subtotal.
      // calculatedSubtotal is already post-discount, so add back stored discountAmt.
      final double _originalSubtotal =
          (selectedOrder?.calculatedSubtotal ?? 0.0) +
          parseAmt(selectedOrder?.discountAmt);
      final double discountAmt = discountPer > 0
          ? _roundMoney((_originalSubtotal * discountPer) / 100.0)
          : 0.0;
      final double taxAmt = parseAmt(selectedOrder?.taxAmt);
      // ✅ Use fullPayableTotal — includes product + modifier prices
      final double netAmt = parseAmt(selectedOrder?.netAmt);
      final double tableChargeAmt = paymentTableChargeForOrder(
        context,
        selectedOrder,
      );
      final double advPayment = parseAmt(selectedOrder?.advPayment);

      // ✅ Build multi-payments array for multi-payment mode
      // Web sends: { amount, pay_method_id, remark, ref_no, method_name, payment_type }
      // Backend expects "pay_method_id" not "payment_method_id"
      final List<Map<String, dynamic>> multiPaymentsArray = isMultiPayment
          ? MultiPaymentCtrl.entries
                .map(
                  (entry) => {
                    "amount": entry.amount,
                    "pay_method_id": entry.paymentMethodId,
                    "method_name": entry.paymentMethodName,
                    "payment_type":
                        entry.paymentMethodType?.toLowerCase() ?? "",
                    "remark": entry.remark ?? "",
                    "ref_no": "",
                  },
                )
                .toList()
          : [];

      final List<Map<String, dynamic>> currentPaymentDistribution = isSplit
          ? [
              if (cashoutVal > 0) {'method': 'Cash', 'amount': cashoutVal},
              if (cardoutVal > 0) {'method': 'Card', 'amount': cardoutVal},
            ]
          : isMultiPayment
          ? MultiPaymentCtrl.entries
                .where((entry) => entry.amount > 0)
                .map(
                  (entry) => {
                    'method': entry.paymentMethodName ?? 'Payment',
                    'amount': entry.amount,
                  },
                )
                .toList()
          : selectedOrder?.payments.isNotEmpty == true
          ? [
              {
                'method':
                    PayMethodName ??
                    selectedOrder?.paymentTypeLabel ??
                    'Payment',
                'amount': amountToPay,
              },
            ]
          : [];
      final previousPaymentDistribution =
          selectedOrder?.payments
              .map((p) => {'method': p.methodName, 'amount': p.amount})
              .toList() ??
          [];
      final List<Map<String, dynamic>> autopayPaymentDistribution = [
        ...previousPaymentDistribution,
        ...currentPaymentDistribution,
      ];

      final Map<String, dynamic> requestBody = {
        "order_id": selectedOrder?.orderId,
        "payment_status": isRefund ? "refund" : "paid",
        // Web sends lowercase: "split", "multi", or method type (lowercase).
        // Backend is CASE-SENSITIVE — "SPLIT" is NOT recognized, only "split".
        // Confirmed: Postman with "SPLIT" returns cashout:"0.00" (values ignored by backend).
        "payment_type": isRefund
            ? "refund"
            : isSplit
            ? "split"
            : isMultiPayment
            ? "multi"
            : (PayMethodType?.toLowerCase() ??
                  PayMethodName.toString().toLowerCase()),
        "cashout": cashoutVal,
        "cardout": cardoutVal,
        "table_charge": tableChargeAmt,
        "isMarkCompleted": markCompleted,
        "is_mark_completed": markCompleted,
        if (markCompleted) "order_status": "completed",
        "multi_payments": multiPaymentsArray,
        "discount_per": discountPer,
        "discount_amt": discountAmt,
        "discount_type": "percentage",
        "tax_amt": taxAmt,
        // ✅ CRITICAL FIX: Send remaining balance for partial orders, full amount for new orders
        "total_amt": amountToPay,
        "net_amt": netAmt,
        // ✅ Send the actual stored adjustment (already applied via adjustOrderService).
        // Sending 0 caused the backend to overwrite the previously-saved adjustment,
        // making the completed order show the wrong (pre-adjustment) total.
        "adjust_amt": double.tryParse(selectedOrder?.adjustAmt ?? '0') ?? 0.0,
        // ✅ CRITICAL FIX: Send remaining balance for partial orders, full amount for new orders
        "grand_total": amountToPay,
        "adv_payment": advPayment,
        // Send as int to match web (web sends payment_method_id as number, not string)
        "payment_method_id": int.tryParse(PayMethodID ?? "0") ?? 0,
        "payment_method_name": PayMethodName.toString(),
      };

      //GlobalFunction().debugFunction("📤 AddCustomer Body: $requestBody");

      // ✅ Step 4: API Call
      final response = await httpCtrl.request(
        method: 'POST',
        url: ProcessPayBillPaymentService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // ✅ Debug full response
      //GlobalFunction().debugFunction("📩 API Response: $response");

      // ✅ Step 5: Parse Response
      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? '').toString().trim();

      showCustomToast(context: context, message: message);
      if (success) {
        // ✅ Clear multi-payment entries after successful payment
        if (isMultiPayment) {
          MultiPaymentCtrl.clear();
        }

        // Capture the orderId and all print-related metadata NOW, before
        // getOrderListService and closePanel() change/clear state.
        final int _paidOrderId = selectedOrder!.orderId;
        final double _capturedPaidAmount = amountToPay;
        final bool _capturedIsPartial = isPartialPayment;
        final bool _capturedIsMulti = isMultiPayment;
        final bool _capturedIsSplit = isSplit;
        final List<Map<String, dynamic>> _capturedPayDist =
            List.unmodifiable(autopayPaymentDistribution);

        // ✅ Refresh first — so the auto-print gets fresh backend data
        // (correct discount_amt, discount_per, tax_breakdown after payment).
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        await GetOrderCountService(context);

        // ── Auto-print with FRESH order (post-payment correct taxes & discount) ──
        if (context.mounted) {
          // Find fresh order in refreshed list (fast path).
          // Falls back to targeted Completed-status fetch when the paid order
          // has moved out of the current filter (e.g. Ordered → Completed).
          final OrderData? freshOrder = await _fetchFreshOrderForPrint(
            context,
            _paidOrderId,
            formattedDate,
          );
          if (context.mounted) {
            _triggerBillAutoPrint(
              context,
              order: freshOrder ?? selectedOrder!,
              paidAmount: _capturedPaidAmount,
              isPartialCompletion: _capturedIsPartial,
              isMultiPayment: _capturedIsMulti,
              isSplit: _capturedIsSplit,
              paymentDistribution: _capturedPayDist,
            );
          }
        }

        closePanel();
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in AddCustomerServiceAPI: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(context: context, message: "Something went wrong");
    } finally {
      // ✅ Loader OFF (Always)
      payBillLoadingAction = null;
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Fresh Order Fetch (for Auto-Print)-------------------------------✅-//
  /// After payment the order moves to Completed and may leave the current
  /// filter's result set.  This helper tries:
  ///   1. OrderListing (already refreshed) — fast path, zero extra calls.
  ///   2. A targeted GET for Completed orders today — reliable fallback.
  /// Returns null only if both fail; the caller falls back to stale selectedOrder.
  Future<OrderData?> _fetchFreshOrderForPrint(
    BuildContext context,
    int orderId,
    String formattedDate,
  ) async {
    // Fast path: order is still in the refreshed list.
    try {
      return OrderListing.firstWhere((o) => o.orderId == orderId);
    } catch (_) {}

    // Slow path: order moved to Completed — fetch that bucket.
    if (!context.mounted) return null;
    try {
      final httpCtrl = context.read<HttpServiceProvider>();
      final token =
          Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? '';
      final authHeaders = APIHelper.buildAuthHeaders(token);
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final dynamic resp = await httpCtrl.request(
        method: 'GET',
        url: '${OrderListService}filter/orders?status=Completed&date=$formattedDate',
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );
      if (resp is Map<String, dynamic>) {
        final List<dynamic> data = resp['data'] ?? [];
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final o = OrderData.fromJson(item);
            if (o.orderId == orderId) return o;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️  [AutoPrint] Fresh order fetch failed: $e');
    }
    return null;
  }

  //-✅--Bill Auto-Print--------------------------------------------------✅-//
  /// Called immediately after a successful PayBillPaymentServiceAPI response,
  /// BEFORE closePanel() clears [selectedOrder].  Fire-and-forget — never throws.
  /// [isPartialCompletion] — true when this payment completes a partial order.
  /// [isMultiPayment] — true when the payment uses multiple payment methods.
  /// In both cases selectedOrder.payments[] is stale so we derive totalPaidAmount
  /// from fullPayableTotal instead of the stale payments[] sum.
  void _triggerBillAutoPrint(
    BuildContext context, {
    required OrderData order,
    required double paidAmount,
    bool isPartialCompletion = false,
    bool isMultiPayment = false,
    bool isSplit = false,
    List<Map<String, dynamic>> paymentDistribution = const [],
  }) {
    if (!context.mounted) return;

    // Capture all providers before any async gaps.
    final printingDeviceProvider = context.read<PrintingDeviceProvider>();
    final printerProvider = context.read<PrinterIntegrationProvider>();
    final userData = Provider.of<UserInfoProvider>(
      context,
      listen: false,
    ).getUserData;
    final addOrderCtrl = Provider.of<AddOrderProvider>(context, listen: false);
    final taxRate =
        addOrderCtrl.selectedTaxRate ??
        (addOrderCtrl.OrderTaxListing.isNotEmpty
            ? double.tryParse(addOrderCtrl.OrderTaxListing.first.rate) ?? 15.0
            : 15.0);

    // ── Build items — mirrors _BillPrintDialog._printBill exactly ──────────
    final allDetails = order.details;
    final List<PrintJobItem> items = [];

    // Include ALL products (cancelled ones included with status:'cancelled').
    // Voided items appear on the receipt for transparency; totals already
    // exclude them since they were never charged.
    final productDetails = allDetails
        .where((d) => d.itemType == 'product')
        .toList();

    int itemIndex = 1;
    for (final product in productDetails) {
      final isCancelled = product.status.toLowerCase() == 'cancelled';
      
      // Calculate cancelled quantity
      int cancelledQty = product.originalQty - product.quantity;
      if (product.cancelledQty > cancelledQty) {
        cancelledQty = product.cancelledQty;
      }
      if (cancelledQty <= 0 && isCancelled) {
        final fallbackQty = product.originalQty > 0
            ? product.originalQty
            : (product.qty > 0 ? product.qty : product.quantity);
        cancelledQty = fallbackQty > 0 ? fallbackQty : 1;
      }

      // 1. Add active portion if quantity > 0 and status is not fully cancelled
      final int activeQty = product.quantity;
      final bool hasActivePortion = !isCancelled && activeQty > 0;
      if (hasActivePortion) {
        items.add(
          PrintJobItem(
            name: '$itemIndex. ${product.product.mPName}',
            quantity: activeQty,
            price: double.tryParse(product.rate) ?? 0.0,
            notes: (product.note.isEmpty || product.note == 'N/A')
                ? null
                : product.note,
            status: null,
          ),
        );

        // Include active portion of modifiers
        final linkedModifiers = allDetails
            .where(
              (mod) =>
                  mod.itemType == 'modifier' &&
                  mod.link == product.orderDetId.toString(),
            )
            .toList();

        for (final mod in linkedModifiers) {
          final bool modCancelled = mod.status.toLowerCase() == 'cancelled';
          final int modActiveQty = mod.quantity;
          if (!modCancelled && modActiveQty > 0) {
            items.add(
              PrintJobItem(
                name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
                quantity: modActiveQty,
                price: double.tryParse(mod.rate) ?? 0.0,
                notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
                status: null,
              ),
            );
          }
        }
        itemIndex++;
      }

      // 2. Add cancelled portion if cancelledQty > 0
      if (cancelledQty > 0) {
        items.add(
          PrintJobItem(
            name: product.product.mPName,
            quantity: cancelledQty,
            price: double.tryParse(product.rate) ?? 0.0,
            notes: (product.note.isEmpty || product.note == 'N/A')
                ? null
                : product.note,
            status: 'cancelled',
          ),
        );

        // Include cancelled portion of modifiers
        final linkedModifiers = allDetails
            .where(
              (mod) =>
                  mod.itemType == 'modifier' &&
                  mod.link == product.orderDetId.toString(),
            )
            .toList();

        for (final mod in linkedModifiers) {
          final bool modCancelled = isCancelled || mod.status.toLowerCase() == 'cancelled';
          int modCancelledQty = mod.originalQty - mod.quantity;
          if (mod.cancelledQty > modCancelledQty) {
            modCancelledQty = mod.cancelledQty;
          }
          if (modCancelledQty <= 0 && modCancelled) {
            final fallbackQty = mod.originalQty > 0
                ? mod.originalQty
                : (mod.qty > 0 ? mod.qty : mod.quantity);
            modCancelledQty = fallbackQty > 0 ? fallbackQty : 1;
          }

          if (modCancelledQty > 0) {
            items.add(
              PrintJobItem(
                name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
                quantity: modCancelledQty,
                price: double.tryParse(mod.rate) ?? 0.0,
                notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
                status: 'cancelled',
              ),
            );
          }
        }
      }
    }

    // Removed block that prevented printing when all items were cancelled

    // ── Compute totals ──────────────────────────────────────────────────────
    final receiptTableCharge = paymentTableChargeForOrder(context, order);
    final totalAmount = payableTotalForOrder(context, order);
    // Fresh order's totalPaidAmount already includes the current payment.
    // Mirror manual print: for a fully-paid order use totalPaidAmount directly;
    // for a partial/stale fallback still add paidAmount to cover the gap.
    final bool _isNowPaid = order.paymentStatus.toLowerCase() == 'paid';
    final cumulativePaidAmount = _isNowPaid
        ? (order.totalPaidAmount > 0 ? order.totalPaidAmount : totalAmount)
        : _roundMoney(order.totalPaidAmount + paidAmount);
    final taxAmt = order.displayTotalTax;
    final netAmount = order.displayNetAmount > 0
        ? order.displayNetAmount
        : totalAmount - taxAmt;
    // Fresh order carries backend-computed discount_amt after payment.
    final double discount = double.tryParse(order.discountAmt) ?? 0.0;

    // ── Format date / time from order timestamp ─────────────────────────────
    final orderDateTime = DateTime.tryParse(order.orderDate) ?? DateTime.now();
    final date =
        '${orderDateTime.day.toString().padLeft(2, '0')}/${orderDateTime.month.toString().padLeft(2, '0')}/${orderDateTime.year}';
    final time =
        '${orderDateTime.hour.toString().padLeft(2, '0')}:${orderDateTime.minute.toString().padLeft(2, '0')}';

    // ── Pass to PrintingDeviceProvider which handles connect + print ────────

    // Invoice number from API invoice_no field (e.g. 842), falls back to order_no
    final orderNum = order.orderNo.toString().padLeft(4, '0');
    final invoiceNum = order.invoiceNo > 0
        ? order.invoiceNo.toString().padLeft(4, '0')
        : orderNum;

    // Generate ZATCA-compliant QR code for Saudi tax invoices
    final List<int> zatcaTlv = [];
    void addZatcaField(int tag, String value) {
      final bytes = utf8.encode(value);
      zatcaTlv.add(tag);
      zatcaTlv.add(bytes.length);
      zatcaTlv.addAll(bytes);
    }

    addZatcaField(1, userData?.orgName ?? 'Restaurant');
    addZatcaField(
      2,
      userData?.vatNo.isNotEmpty == true ? userData!.vatNo : '000000000000000',
    );
    addZatcaField(
      3,
      order.orderDate.isNotEmpty
          ? order.orderDate
          : DateTime.now().toIso8601String(),
    );
    addZatcaField(4, totalAmount.toStringAsFixed(2));
    addZatcaField(5, taxAmt.toStringAsFixed(2));
    final qrData = base64Encode(zatcaTlv);

    // Async block: download logo then fire print (fire-and-forget, errors caught)
    () async {
      // Download org logo (cached in-memory after first success — mirrors
      // web browser caching; eliminates per-print network dependency)
      String? logoBase64;
      if (userData?.orgPicture.isNotEmpty == true) {
        final logoUrl =
            '${GlobalServiceURL.ImageBaseUrl}${userData!.orgPicture}';
        if (_cachedLogoBase64 != null && _cachedLogoUrl == logoUrl) {
          logoBase64 = _cachedLogoBase64;
        } else {
          for (int attempt = 0; attempt < 2; attempt++) {
            try {
              final response = await http
                  .get(Uri.parse(logoUrl))
                  .timeout(const Duration(milliseconds: 5000));
              if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
                _cachedLogoUrl = logoUrl;
                _cachedLogoBase64 = base64Encode(response.bodyBytes);
                logoBase64 = _cachedLogoBase64;
                break;
              }
            } catch (_) {
              // Retry once on timeout/network error
            }
          }
        }
      }

      // Render ZATCA TLV as QR PNG bitmap (matches web: QRCode→canvas→addImage)
      final qrImageBase64 = await _generateQrPngBase64(qrData);

      await printingDeviceProvider
          .autoPrintBill(
            printerProvider: printerProvider,
            orderData: {
              'storeName': userData?.orgName ?? 'Restaurant',
              'vatNumber': (userData?.vatNo.isNotEmpty == true)
                  ? userData!.vatNo
                  : null,
              'branchName': userData?.branchName ?? 'Main Branch',
              'storeAddress': (userData?.branchAddress.isNotEmpty == true)
                  ? userData!.branchAddress
                  : null,
              'orderNumber': orderNum,
              'invoiceNumber': invoiceNum,
              'orderType': order.type.toUpperCase().replaceAll('_', '-'),
              'tableName': _tableDisplayName(order),
              'customerName':
                  (order.customer.isNotEmpty && order.customer != 'N/A')
                  ? order.customer
                  : 'Guest Customer',
              'date': date,
              'time': time,
              'items': items,
              'netAmount': netAmount,
              'tax': taxAmt,
              'taxRate': taxRate,
              'total': totalAmount,
              // Fresh order's payments[] is authoritative — mirrors manual print exactly.
              // payments.length > 2 → MULTI, == 2 → SPLIT, 1 → single method label.
              'paymentMethod': order.payments.length > 2
                  ? 'MULTI'
                  : (order.payments.length == 2
                        ? 'SPLIT'
                        : (PayMethodName ?? order.paymentTypeLabel)),
              'paymentStatus': 'PAID',
              'discount': discount,
              'adjustmentAmount': double.tryParse(order.adjustAmt) ?? 0.0,
              'refundAmount': order.calculatedRefund,
              'paidAmount': cumulativePaidAmount,
              'tableCharge': receiptTableCharge,
              // After this payment, order is fully paid. Show "Total Partial" line
              // if there were ANY previous payments (partial completion, multi-payment,
              // or if payments[] was already populated by _applyInstantUpdate).
              // This ensures the receipt matches manual print regardless of timing.
              'totalPaidAmount':
                  (isPartialCompletion ||
                      isMultiPayment ||
                      order.totalPaidAmount > 0)
                  ? cumulativePaidAmount
                  : 0.0,
              'qrCodeData': qrImageBase64,
              'logoBase64': logoBase64,
              // Fresh order has backend-computed tax_breakdown after payment
              // (reflects the final discount_per applied at payment time).
              'taxBreakdown': order.displayTaxesMap?.map(
                (k, v) => MapEntry(
                  k,
                  v is num
                      ? v.toDouble()
                      : (double.tryParse(v.toString()) ?? 0.0),
                ),
              ),
              'paymentDistribution': paymentDistribution.isNotEmpty
                  ? paymentDistribution
                  : order.payments.isNotEmpty
                  ? order.payments
                        .map(
                          (p) => {'method': p.methodName, 'amount': p.amount},
                        )
                        .toList()
                  : null,
            },
          )
          .then((success) {
            if (success) {
              debugPrint(
                '✅ [AutoPrint] Bill auto-print completed for order $orderNum',
              );
            } else {
              debugPrint(
                '⚠️  [AutoPrint] Bill auto-print skipped or failed for order $orderNum',
              );
            }
          })
          .catchError((e) {
            debugPrint('⚠️  [AutoPrint] Bill auto-print error: $e');
          });
    }().catchError((e) {
      debugPrint('⚠️  [AutoPrint] Bill auto-print error: $e');
    });
  }

  //-✅--Order-Served-----------------------------------------------------✅-//
  Future<bool> OrderServedService(
    BuildContext context,
    String Status,
    String OrderID,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setHomeLoading(true);
      notifyListeners();

      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        setHomeLoading(false);
        return false;
      }

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final Map<String, dynamic> requestBody = {"status": Status};

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$OrderID",
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // 🔹 Check if 'data' exists and status is "served"
      final String returnedStatus =
          response['data']?['status']?.toString() ?? '';
      final String msg = response['message']?.toString() ?? "Unknown response";

      if (returnedStatus.toLowerCase() == "served") {
        // ✅ Targeted refresh — preserves current date/filter/search state
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        await GetOrderCountService(context);
        // Re-derive notification list so the served item disappears immediately
        await GetNotificationListService(context);
        return true; // ✅ Success
      } else {
        showCustomToast(
          context: context,
          message: msg,
        ); // ⚠️ Show error message
        return false;
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //--🔹--InitializeData-------------------------------------------------🔹--//
  Future<void> InitializeData(BuildContext context) async {
    PreparingCount = "0";
    PreparedCount = "0";
    // Reset loading
    isHomeLoading = true;
    setHomeLoading(true);
    // Reload dropdowns
    dropDownOneListing = [];
    await loadDropDownOneList();
    dropDownTwoListing = [];
    await loadDropDownTwoList();

    // Clear all orders and filtered lists
    OrderListing.clear();
    filteredOrderListing.clear();

    // Reset filters and dropdowns
    // 🔹 Step 1: Default filter hamesha "current"
    updateSelectedFilter("current");
    selectedDropDownOne = null;
    selectedDropDownTwo = null;

    // Reset date to today
    selectedDate = DateTime.now();

    // Clear search controller
    SearchOrderController.clear();
    myFocusNodeSearchOrder.unfocus();

    // Format date to YYYY-MM-DD
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    // Fetch orders fresh
    await getOrderListService(context, selectedFilter, formattedDate);

    // Load tables list for premium table checks and styling
    try {
      final addOrderCtrl = Provider.of<AddOrderProvider>(context, listen: false);
      if (addOrderCtrl.OrderTableListing.isEmpty) {
        await addOrderCtrl.getOrderTableListService(context);
      }
    } catch (_) {}

    _isPanelOpen = false;
    isPanelNotificationOpen = false;
    selectedTipsAmount = null;
    TipsAmountListing = [];
    await loadTipsAmountList();
    PaymentMethodListing = [];
    await loadPaymentMethodList();
    await GetOrderCountService(context);
    await getPayBillPaymentMethodsListService(context);
    notifyListeners();
  }

  //-✅--AddItemToOrderService (NEW - Production)------------------------✅-//
  /// 🔹 Add a new item to an existing order
  /// 📍 Used when user wants to add items to an existing order from Home Screen
  Future<bool> addItemToOrderService(
    BuildContext context, {
    required int orderId,
    required int productId,
    required int quantity,
    required double rate,
    String? note,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      // 🔹 Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        return false;
      }

      setHomeLoading(true);
      notifyListeners();

      // 🔹 Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Step 3: Prepare Request Body
      final double netAmount = quantity * rate;
      final Map<String, dynamic> requestBody = {
        "order_id": orderId,
        "m_prod_id": productId,
        "qty": quantity,
        "rate": rate,
        "net_amt": netAmount,
      };

      // Add optional note if provided
      if (note != null && note.trim().isNotEmpty) {
        requestBody["note"] = note.trim();
      }

      GlobalFunction().debugFunction("📤 Add Item Body: $requestBody");

      // 🔹 Step 4: API Call
      final response = await httpCtrl.request(
        method: 'POST',
        url: OrderNowService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // 🔹 Step 5: Parse Response
      final String message = (response['message'] ?? 'Item added successfully')
          .toString()
          .trim();

      showCustomToast(context: context, message: message);

      // 🔹 Step 6: Refresh order list
      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      await getOrderListService(context, selectedFilter, formattedDate);

      return true;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in addItemToOrderService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to add item. Please try again.",
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Group Orders State + Service--------------------------------------✅-//

  /// Returns true when [orderDate] falls on today's local date.
  /// Matches web app isTodayOrder logic.
  bool _isTodayOrder(String orderDate) {
    try {
      final date = DateTime.parse(orderDate.split(' ')[0]);
      final today = DateTime.now();
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    } catch (_) {
      return false;
    }
  }

  /// Orders eligible for grouping:
  /// • today's orders only (matches web app isTodayOrder check)
  /// • not yet grouped (groupId == 0, matches web app isUngroupedOrder check)
  /// • unpaid, not completed, not cancelled
  List<OrderData> get eligibleOrdersForGrouping => filteredOrderListing
      .where(
        (o) =>
            o.paymentStatus.toLowerCase() != 'paid' &&
            o.orderStatus.toLowerCase() != 'completed' &&
            o.orderStatus.toLowerCase() != 'cancelled' &&
            o.groupId == 0 &&
            _isTodayOrder(o.orderDate),
      )
      .toList();

  int? groupParentOrderId;
  List<int> groupChildOrderIds = [];

  void setGroupParentOrder(int? orderId) {
    groupParentOrderId = orderId;
    // Cannot be both parent and child
    if (orderId != null) groupChildOrderIds.remove(orderId);
    notifyListeners();
  }

  void toggleGroupChildOrder(int orderId) {
    // Cannot select parent as child
    if (orderId == groupParentOrderId) return;
    if (groupChildOrderIds.contains(orderId)) {
      groupChildOrderIds.remove(orderId);
    } else {
      groupChildOrderIds.add(orderId);
    }
    notifyListeners();
  }

  void resetGroupOrdersSelection() {
    groupParentOrderId = null;
    groupChildOrderIds = [];
    notifyListeners();
  }

  /// POST /order-master/group-orders
  Future<bool> groupOrdersService(BuildContext context) async {
    if (!context.mounted) return false;

    if (groupParentOrderId == null || groupChildOrderIds.isEmpty) {
      showCustomToast(
        context: context,
        message: 'Please select a parent order and at least one child order.',
      );
      return false;
    }

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final Map<String, dynamic> requestBody = {
        'parent_order_id': groupParentOrderId,
        'child_order_ids': groupChildOrderIds,
      };

      GlobalFunction().debugFunction('📤 Group Orders Body: $requestBody');

      final response = await httpCtrl.request(
        method: 'POST',
        url: GroupOrdersService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? 'Unknown error')
          .toString();

      if (success) {
        showCustomToast(context: context, message: message);
        resetGroupOrdersSelection();
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        await getOrderListService(context, selectedFilter, formattedDate);
        return true;
      } else {
        showCustomToast(context: context, message: message);
        return false;
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction('❌ Error in groupOrdersService: $e');
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: 'Failed to group orders. Please try again.',
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Refund Order Service----------------------------------------------✅-//

  /// POST /order-master/orders/refund
  /// Only works on PAID orders.
  Future<bool> refundOrderService(
    BuildContext context, {
    required int orderId,
    required double refundAmount,
    required int refundPaymentMethodId,
    required String refundRemark,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      // NOTE: setHomeLoading intentionally omitted — inline panel operation.

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // ✅ Backend expects integer pay_m_id for refund_payment_method (matches web app)
      final Map<String, dynamic> requestBody = {
        'order_id': orderId,
        'refund_amount': refundAmount,
        'refund_payment_method': refundPaymentMethodId,
        'refund_remark': refundRemark.trim(),
        'order_status': 'paid',
        'payment_status': 'paid',
        'is_mark_completed': false,
        'isMarkCompleted': false,
      };

      GlobalFunction().debugFunction('📤 Refund Order Body: $requestBody');

      final response = await httpCtrl.request(
        method: 'POST',
        url: RefundOrderService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? 'Unknown error')
          .toString();

      showCustomToast(context: context, message: message);

      if (success) {
        // ── INSTANT UI UPDATE (panel + list card) ────────────────────────
        // Compute the new cumulative refund total, then apply it to all
        // in-memory stores so the UI reflects the change without waiting
        // for the background list refresh.
        final OrderData? base = selectedOrder?.orderId == orderId
            ? selectedOrder
            : () {
                final i = OrderListing.indexWhere((o) => o.orderId == orderId);
                return i != -1 ? OrderListing[i] : null;
              }();

        if (base != null) {
          final currentRefund = double.tryParse(base.refundAmt) ?? 0.0;
          _applyInstantUpdate(orderId, {
            'refund_amt': (currentRefund + refundAmount).toString(),
          });
          notifyListeners(); // refreshes panel + list card instantly

          final updatedOrder = selectedOrder?.orderId == orderId
              ? selectedOrder!
              : OrderListing.firstWhere((o) => o.orderId == orderId, orElse: () => base!);

          _triggerBillAutoPrint(context, order: updatedOrder, paidAmount: 0.0);
        }

        // Background: sync full list from server (silent — no shimmer).
        // SKIPPED: We don't fetch from the server immediately after a refund so 
        // the backend doesn't force the order to disappear into the "completed" filter.
        // The UI is already instantly updated via `_applyInstantUpdate` above.
        // final formattedDate =
        //     '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        // getOrderListService(
        //   context,
        //   selectedFilter,
        //   formattedDate,
        //   silent: true,
        // );

        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction('❌ Error in refundOrderService: $e');
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: 'Failed to process refund. Please try again.',
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Create Partial Payment Service-----------------------------------✅-//

  /// POST /order-master/partial-pay
  /// Available for unpaid/partial orders. Allows multiple partial payments.
  Future<bool> createPartialPaymentService(
    BuildContext context, {
    required int orderId,
    required double amount,
    required int paymentMethodId,
    String? remark,
    String? refNo,
  }) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      // NOTE: setHomeLoading intentionally omitted — this is an inline
      // panel operation and the shimmer would disrupt the payment workflow.

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final OrderData? targetOrder = selectedOrder?.orderId == orderId
          ? selectedOrder
          : () {
              final i = OrderListing.indexWhere((o) => o.orderId == orderId);
              return i != -1 ? OrderListing[i] : null;
            }();
      final double tableChargeAmt = paymentTableChargeForOrder(
        context,
        targetOrder,
      );

      final Map<String, dynamic> requestBody = {
        'order_id': orderId,
        'amount': amount,
        'pay_method_id': paymentMethodId,
        'table_charge': tableChargeAmt,
      };

      // Add optional fields if provided
      if (remark != null && remark.isNotEmpty) {
        requestBody['remark'] = remark;
      }
      if (refNo != null && refNo.isNotEmpty) {
        requestBody['ref_no'] = refNo;
      }
      ;

      GlobalFunction().debugFunction('📤 Partial Payment Body: $requestBody');

      final response = await httpCtrl.request(
        method: 'POST',
        url: PartialPaymentCreateService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? 'Unknown error')
          .toString();

      showCustomToast(context: context, message: message);

      if (success) {
        // ── INSTANT UI UPDATE (panel + list card) ────────────────────────
        // Build the new payment entry — use API response data, with known
        // request values as guaranteed fallbacks.
        final responseData = response['data'] as Map<String, dynamic>?;
        final paymentData = responseData?['payment'] as Map<String, dynamic>?;
        final orderData = responseData?['order'] as Map<String, dynamic>?;

        final newPayment = OrderPaymentEntry(
          orderPayId: (paymentData?['order_pay_id'] as int?) ?? 0,
          amount: (paymentData?['amount'] as num?)?.toDouble() ?? amount,
          methodName: () {
            final methodId =
                (paymentData?['pay_method_id'] as int?) ?? paymentMethodId;
            if (PayBillPaymentListing.isNotEmpty) {
              return PayBillPaymentListing.firstWhere(
                (m) => m.payMId == methodId,
                orElse: () => PayBillPaymentListing.first,
              ).name;
            }
            return 'Cash';
          }(),
        );

        // Locate the base object and build the updated payments list.
        // (base may be selectedOrder or an OrderListing entry)
        final OrderData? base = selectedOrder?.orderId == orderId
            ? selectedOrder
            : () {
                final i = OrderListing.indexWhere((o) => o.orderId == orderId);
                return i != -1 ? OrderListing[i] : null;
              }();

        if (base != null) {
          final updatedPayments = List<OrderPaymentEntry>.from(base.payments)
            ..add(newPayment);

          _applyInstantUpdate(orderId, {
            'payment_status':
                orderData?['payment_status']?.toString() ?? 'partial',
            if (orderData?['paid_amount'] != null)
              'Adv_payment': orderData!['paid_amount'].toString(),
            if (tableChargeAmt > 0) 'table_charge': tableChargeAmt,
            'payments': updatedPayments.map((p) => p.toJson()).toList(),
          });
          notifyListeners(); // refreshes panel + list card instantly
        }

        // Background: sync full list from server (silent — no shimmer).
        final formattedDate =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        getOrderListService(
          context,
          selectedFilter,
          formattedDate,
          silent: true,
        );
        GetOrderCountService(context);

        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        '❌ Error in createPartialPaymentService: $e',
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: 'Failed to process partial payment. Please try again.',
      );
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Adjust Order State + Service-------------------------------------✅-//
  final TextEditingController adjustAmtController = TextEditingController();
  final TextEditingController adjustReasonController = TextEditingController();
  final TextEditingController adjustPasswordController =
      TextEditingController();

  String adjustIsFor =
      'amount'; // always "amount" — backend only accepts "amount" or "payment"
  String adjustDirection = 'addition'; // "addition" (+) or "deduction" (-)
  bool isAdjustExpanded = false;
  bool isAdjustApplied = false;
  double? appliedAdjustAmt;

  void setAdjustIsFor(String val) {
    adjustIsFor = val;
    notifyListeners();
  }

  void setAdjustDirection(String val) {
    adjustDirection = val;
    notifyListeners();
  }

  void toggleAdjustExpand() {
    isAdjustExpanded = !isAdjustExpanded;
    notifyListeners();
  }

  void resetAdjustState() {
    adjustAmtController.clear();
    adjustReasonController.clear();
    adjustPasswordController.clear();
    adjustIsFor = 'amount';
    adjustDirection = 'addition';
    isAdjustExpanded = false;
    isAdjustApplied = false;
    appliedAdjustAmt = null;
    notifyListeners();
  }

  /// PUT /order-master/adjust
  Future<bool> adjustOrderService(
    BuildContext context, {
    OrderData? targetOrder,
  }) async {
    if (!context.mounted) return false;

    final order = targetOrder ?? selectedOrder;
    final double? amt = double.tryParse(adjustAmtController.text.trim());
    if (amt == null || amt <= 0) {
      showCustomToast(
        context: context,
        message: 'Enter a valid adjustment amount',
      );
      return false;
    }
    if (adjustPasswordController.text.trim().isEmpty) {
      showCustomToast(
        context: context,
        message: 'Manager password is required',
      );
      return false;
    }

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      // NOTE: setHomeLoading intentionally omitted — inline panel operation.

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final isSplit = PayMethodName?.toString().toUpperCase() == 'SPLIT';
      final cashCtrl = context.read<PayBillCashAmountProvider>();
      final cardCtrl = context.read<PayBillCardAmountProvider>();

      final Map<String, dynamic> requestBody = {
        // Resolve a valid pay_m_id: prefer order's existing one, else first active payment method.
        // order.payMId defaults to 'N/A' for unpaid orders → int.tryParse returns null → fallback.
        'pay_m_id': () {
          final fromOrder = int.tryParse(order?.payMId ?? '');
          if (fromOrder != null && fromOrder > 0) return fromOrder;
          final active = PayBillPaymentListing.where(
            (m) => m.status.toLowerCase() == 'active' && m.payMId > 0,
          ).firstOrNull;
          if (active != null) return active.payMId;
          final first = PayBillPaymentListing.where(
            (m) => m.payMId > 0,
          ).firstOrNull;
          return first?.payMId ?? 0;
        }(),
        // Positive = addition (surcharge), negative = deduction (discount)
        'adjust_amt': adjustDirection == 'deduction' ? -amt : amt,
        'adjust_reason': adjustReasonController.text.trim().isEmpty
            ? 'Adjustment'
            : adjustReasonController.text.trim(),
        'password': adjustPasswordController.text.trim(),
        'isFor': 'amount',
        'order_id': order?.orderId,
        'cashout': isSplit
            ? double.tryParse(cashCtrl.controller.text.trim()) ?? 0
            : 0,
        'cardout': isSplit
            ? double.tryParse(cardCtrl.controller.text.trim()) ?? 0
            : 0,
      };

      GlobalFunction().debugFunction('📤 Adjust Order Body: $requestBody');

      final response = await httpCtrl.request(
        method: 'PUT',
        url: AdjustOrderService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? 'Unknown error')
          .toString();

      if (context.mounted) {
        showCustomToast(context: context, message: message);
      }

      if (success) {
        isAdjustApplied = true;
        appliedAdjustAmt = amt;

        // ── INSTANT UI UPDATE (panel + list card) ────────────────────────
        // Compute new cumulative adjust_amt and apply to all in-memory stores.
        // fullPayableTotal is a computed getter that reads adjustAmt, so this
        // instantly corrects the displayed total in the sidebar card AND panel.
        final patchedOid = order?.orderId ?? 0;
        if (patchedOid > 0) {
          final adjustValue = adjustDirection == 'deduction' ? -amt : amt;

          final OrderData? base = selectedOrder?.orderId == patchedOid
              ? selectedOrder
              : () {
                  final i = OrderListing.indexWhere(
                    (o) => o.orderId == patchedOid,
                  );
                  return i != -1 ? OrderListing[i] : null;
                }();

          if (base != null) {
            final currentAdjust = double.tryParse(base.adjustAmt) ?? 0.0;
            _applyInstantUpdate(patchedOid, {
              'adjust_amt': (currentAdjust + adjustValue).toString(),
              'adjust_reason': adjustReasonController.text.trim().isEmpty
                  ? 'Adjustment'
                  : adjustReasonController.text.trim(),
            });
            notifyListeners(); // refreshes panel + list card instantly
          }
        }

        // Background: sync full list from server (silent — no shimmer).
        if (patchedOid > 0 && context.mounted) {
          final formattedDate =
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          getOrderListService(
            context,
            selectedFilter,
            formattedDate,
            silent: true,
          );
        }

        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction('❌ Error in adjustOrderService: $e');
      debugPrintStack(stackTrace: stack);
      if (context.mounted) {
        showCustomToast(
          context: context,
          message: 'Failed to apply adjustment. Please try again.',
        );
      }
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  /// PUT /order-master/adjust  (isFor: 'payment')
  /// Updates the payment method on an existing order without changing the total.
  Future<bool> updateOrderPaymentMethodService(
    BuildContext context, {
    required OrderData order,
    required int newPayMId,
    double cashout = 0,
    double cardout = 0,
  }) async {
    if (!context.mounted) return false;

    if (adjustPasswordController.text.trim().isEmpty) {
      showCustomToast(
        context: context,
        message: 'Manager password is required',
      );
      return false;
    }

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      setHomeLoading(true);
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final Map<String, dynamic> requestBody = {
        'pay_m_id': newPayMId,
        'adjust_amt': 0,
        'adjust_reason': '',
        'password': adjustPasswordController.text.trim(),
        'isFor': 'payment',
        'order_id': order.orderId,
        'cashout': cashout,
        'cardout': cardout,
      };

      GlobalFunction().debugFunction(
        '📤 Update Payment Method Body: $requestBody',
      );

      final response = await httpCtrl.request(
        method: 'PUT',
        url: AdjustOrderService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      final String message = (response['message'] ?? 'Unknown error')
          .toString();

      if (context.mounted) {
        showCustomToast(context: context, message: message);
      }

      if (success) {
        final patchedOid = order.orderId;
        if (patchedOid > 0 && context.mounted) {
          final patched = await getOrderPaymentStatusService(
            context,
            patchedOid,
          );
          if (patched == null && context.mounted) {
            final formattedDate =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
            await getOrderListService(context, selectedFilter, formattedDate);
          }
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        '❌ Error in updateOrderPaymentMethodService: $e',
      );
      debugPrintStack(stackTrace: stack);
      if (context.mounted) {
        showCustomToast(
          context: context,
          message: 'Failed to update payment method. Please try again.',
        );
      }
      return false;
    } finally {
      setHomeLoading(false);
      notifyListeners();
    }
  }

  //-✅--Order Payment Status Service------------------------------------✅-//

  /// Tracks whether a single-order status refresh is in progress.
  /// Does NOT block the full screen — used only for subtle panel indicator.
  bool isFetchingOrderStatus = false;

  //-✅--Order Table Status State---------------------------------------✅-//
  /// null = not yet fetched, true = table occupied, false = table free
  bool? tableOccupied;
  String tableStatusMessage = '';
  bool isFetchingTableStatus = false;

  /// GET /order-master/payment-status/:orderId
  ///
  /// Lightweight refresh: patches [OrderListing], [filteredOrderListing], and
  /// [selectedOrder] in-memory without triggering a full list reload.
  ///
  /// Returns the raw `data` map from the response, or null on failure.
  Future<Map<String, dynamic>?> getOrderPaymentStatusService(
    BuildContext context,
    int orderId,
  ) async {
    if (!context.mounted || orderId <= 0) return null;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      isFetchingOrderStatus = true;
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'GET',
        url: '$OrderPaymentStatusService$orderId',
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      if (!success) return null;

      final Map<String, dynamic>? data =
          response['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      GlobalFunction().debugFunction(
        '✅ Payment Status #$orderId: ${data['payment_status']} | ${data['order_status']} | total: ${data['total_amount']}',
      );

      // Patch in-memory — no full list reload needed
      _patchOrderInMemory(orderId, data);
      notifyListeners();
      return data;
    } catch (e) {
      GlobalFunction().debugFunction(
        '❌ Error in getOrderPaymentStatusService: $e',
      );
      return null;
    } finally {
      isFetchingOrderStatus = false;
      notifyListeners();
    }
  }

  //-✅--Order Table Status Service-------------------------------------✅-//
  /// GET /order-master/{orderId}/table
  ///
  /// Returns occupancy status for the table belonging to [orderId].
  /// Result stored in [tableOccupied] + [tableStatusMessage].
  /// Non-blocking — does NOT set isHomeLoading.
  Future<void> getOrderTableStatusService(
    BuildContext context,
    int orderId,
  ) async {
    if (!context.mounted || orderId <= 0) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      isFetchingTableStatus = true;
      notifyListeners();

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final tableUrl =
          '${GlobalServiceURL.baseUrl}/order-master/$orderId/table';

      final response = await httpCtrl.request(
        method: 'GET',
        url: tableUrl,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      final bool success = response['success'] as bool? ?? false;
      if (!success) {
        tableOccupied = null;
        tableStatusMessage = 'Status unavailable';
        notifyListeners();
        return;
      }

      tableOccupied = response['occupied'] as bool? ?? false;
      tableStatusMessage = response['message']?.toString() ?? '';

      GlobalFunction().debugFunction(
        '🪑 Table status for Order #$orderId: '
        'occupied=$tableOccupied ($tableStatusMessage)',
      );
    } catch (e) {
      GlobalFunction().debugFunction(
        '❌ Error in getOrderTableStatusService: $e',
      );
      tableOccupied = null;
      tableStatusMessage = '';
    } finally {
      isFetchingTableStatus = false;
      notifyListeners();
    }
  }

  /// Instantly applies [jsonOverrides] to an order in all in-memory stores.
  ///
  /// Looks up the base [OrderData] by [orderId] (prefers [selectedOrder] when
  /// it matches — it is most up-to-date), rebuilds it via JSON round-trip,
  /// then writes the result into [OrderListing], [filteredOrderListing], and
  /// [selectedOrder] (when the panel is showing that order).
  ///
  /// Does NOT call [notifyListeners()] — the caller must do so.
  void _applyInstantUpdate(int orderId, Map<String, dynamic> jsonOverrides) {
    // Locate base object. selectedOrder is preferred because it may have
    // data (e.g. payments[]) that was not yet synced back to OrderListing.
    OrderData? base;
    if (selectedOrder?.orderId == orderId) {
      base = selectedOrder;
    } else {
      final idx = OrderListing.indexWhere((o) => o.orderId == orderId);
      if (idx != -1) base = OrderListing[idx];
    }
    if (base == null) return; // nothing to update

    final updated = OrderData.fromJson({...base.toJson(), ...jsonOverrides});

    // Update the order list (drives sidebar cards).
    final idx = OrderListing.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      OrderListing[idx] = updated;
      final fidx = filteredOrderListing.indexWhere((o) => o.orderId == orderId);
      if (fidx != -1) filteredOrderListing[fidx] = updated;
    }

    // Update the panel (drives OPayBillWidget).
    if (selectedOrder?.orderId == orderId) selectedOrder = updated;
  }

  /// Patches [OrderListing], [filteredOrderListing], and [selectedOrder]
  /// with the fresh payment/order fields returned by the status endpoint.
  void _patchOrderInMemory(int orderId, Map<String, dynamic> statusData) {
    final newPaymentStatus = statusData['payment_status']?.toString();
    final newOrderStatus = statusData['order_status']?.toString();
    final newTotalAmt = statusData['total_amount']?.toString();

    OrderData applyPatch(OrderData existing) {
      // Round-trip through toJson/fromJson preserves all fields
      final patched = OrderData.fromJson({
        ...existing.toJson(),
        if (newPaymentStatus != null) 'payment_status': newPaymentStatus,
        if (newOrderStatus != null) 'order_status': newOrderStatus,
        if (newTotalAmt != null) 'total_amt': newTotalAmt,
      });
      // Preserve mutable UI-only state that toJson omits
      patched.selectedDropDownOne = existing.selectedDropDownOne;
      patched.selectedDropDownTwo = existing.selectedDropDownTwo;
      return patched;
    }

    final idx = OrderListing.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      final patched = applyPatch(OrderListing[idx]);
      OrderListing[idx] = patched;

      final fidx = filteredOrderListing.indexWhere((o) => o.orderId == orderId);
      if (fidx != -1) filteredOrderListing[fidx] = patched;

      // Keep panel in sync
      if (selectedOrder?.orderId == orderId) {
        selectedOrder = patched;
      }
    }
  }
}

//-✅---------------------------------------------------------------------✅-//