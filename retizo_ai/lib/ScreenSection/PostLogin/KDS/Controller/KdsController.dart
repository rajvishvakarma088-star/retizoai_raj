// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:collection/collection.dart';
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Model/FilterOrderModel.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Model/KitchenOrderModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
//-✅---------------------------------------------------------------------✅-//

class KdsProvider with ChangeNotifier {
  int? activeOrderId; // ID of order whose timer is currently active

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPreparedIdsInitialized = false;
  Set<int> _knownPreparedDetailIds = {};

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/prepared_notification.mp3'));
    } catch (e, stack) {
      debugPrint('Error playing notification sound: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void resetPreparedTracking() {
    _isPreparedIdsInitialized = false;
    _knownPreparedDetailIds.clear();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  //--✅--RealTimeUpdate Timer-----
  String formattedDateTime = "";

  // ✅ Auto Add Time (in seconds)
  int autoAddSeconds = 0; // default 5 minutes

  KdsProvider() {
    formattedDateTime = _formatDateTime();
    // Real-time clock update
    Timer.periodic(const Duration(seconds: 1), (_) {
      formattedDateTime = _formatDateTime();
      notifyListeners();
    });
  }

  String _formatDateTime() {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(DateTime.now());
  }

  //--✅--List-Orders----------------
  int readyOrders = 0;
  int completedOrders = 0;
  int cancelledOrders = 0;

  void updateStats({
    required int total,
    required int active,
    required int ready,
    required int cancelled,
  }) {
    readyOrders = ready;
    cancelledOrders = cancelled;
    notifyListeners();
  }

  //-✅--getCompletedOrderCount---------------------------------------✅-//
  int getCompletedOrderCount() {
    return completedOrders;
  }

  //-✅--getCancelledOrderCount---------------------------------------✅-//
  int getCancelledOrderCount() {
    return cancelledOrders;
  }

  //--✅--KitchenOrder----------------
  bool isKdsLoading = false;

  bool get isKdsLoader => isKdsLoading;

  void setKdsLoading(bool value) {
    if (isKdsLoading != value) {
      isKdsLoading = value;
      notifyListeners();
    }
  }

  List<KitchenOrderModel> KitchenOrderListing = [];

  /// 🔹 Ready-to-serve orders from /kitchen/ready endpoint
  List<KitchenOrderModel> ReadyToServeOrderListing = [];

  /// 🔹 Cache: productId → ProductInfoData (from /products-info endpoint)
  Map<int, ProductInfoData> productInfoCache = {};

  // ✅ Guards to prevent duplicate concurrent API calls
  bool _isKitchenFetching = false;
  bool _isReadyFetching = false;

  Future<void> GetKitchenOrderListService(
    BuildContext context,
    DateTime selectedDate, {
    bool silent = false,
  }) async {
    if (!context.mounted) return;
    if (_isKitchenFetching) return; // ✅ Prevent duplicate concurrent calls
    _isKitchenFetching = true;

    final httpCtrl = context.read<HttpServiceProvider>();
    final userInfo = context.read<UserInfoProvider>();
    final token = userInfo.AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    if (!silent) {
      setKdsLoading(true);
    }

    try {
      final responseRaw = await httpCtrl.request(
        method: 'GET',
        // ✅ FIXED: use the correct kitchen/active endpoint (branch + date + station filtered)
        url:
            "${FilterOrderListService}active?branch_id=${userInfo.branchId}&date=$dateStr&station_id=${selectedStationID ?? 'all'}",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // ✅ Kitchen endpoint returns {"success": bool, "data": [...]}
      if (responseRaw is! Map<String, dynamic>) {
        setKdsLoading(false);
        return;
      }

      final dataList = responseRaw['data'];
      if (dataList is! List) {
        setKdsLoading(false);
        return;
      }

      // ✅ Parse using fromKitchenJson — no client-side date filter needed (backend handles it)
      // ✅ FIX: Filter out completed/served/cancelled orders (backend safety + client-side validation)
      KitchenOrderListing = dataList
          .whereType<Map<String, dynamic>>()
          .map(KitchenOrderModel.fromKitchenJson)
          .where((order) {
            // Filter order-level status
            final status = order.orderStatus?.toLowerCase() ?? '';
            if (status == 'cancelled' ||
                status == 'completed' ||
                status == 'served') {
              return false;
            }
            // Filter orders with NO active items (all served/cancelled)
            final hasActiveItems = (order.details ?? []).any((d) {
              final itemStatus = d.status?.toLowerCase() ?? '';
              return itemStatus != 'cancelled' && itemStatus != 'served';
            });
            return hasActiveItems;
          })
          .toList();

      // --------------------------------------------------
      // PICK ACTIVE ORDER IF NOT SET
      // --------------------------------------------------
      if (activeOrderId == null) {
        final nextOrder = KitchenOrderListing.firstWhereOrNull(
          (o) => (o.details ?? []).any(
            (d) =>
                d.status == "preparing" ||
                d.status == "ordered" ||
                d.status == "pending",
          ),
        );
        if (nextOrder != null) activeOrderId = nextOrder.orderId;
      }

      // --------------------------------------------------
      // FETCH PRODUCTS-INFO FOR ITEMS MISSING DISH_PREP_TIME
      // --------------------------------------------------
      final missingPrepIds = <int>{};
      for (final order in KitchenOrderListing) {
        for (final d in order.details ?? []) {
          if ((d.product?.dishPrepTime ?? 0) == 0 && d.mProdId != null) {
            missingPrepIds.add(d.mProdId!);
          }
        }
      }
      if (missingPrepIds.isNotEmpty) {
        await getProductsInfoService(context, missingPrepIds.toList());
      }

      // --------------------------------------------------
      // INITIALIZE TIMERS ONLY FOR ACTIVE ORDER
      // --------------------------------------------------
      final activeOrder = KitchenOrderListing.firstWhereOrNull(
        (o) => o.orderId == activeOrderId,
      );

      if (activeOrder != null) {
        final now = DateTime.now();

        for (final d in activeOrder.details ?? []) {
          if (d.orderDetId == null) continue;

          // ✅ Skip prepared items
          if (d.status == "prepared") {
            detailTimers.remove(d.orderDetId);
            detailEndTimes.remove(d.orderDetId);
            autoExtended.remove(d.orderDetId);
            continue;
          }

          // If already running, don't override
          if (detailTimers.containsKey(d.orderDetId)) continue;

          // ACTIVE ORDER → calculate prep time
          // Use cached products-info as fallback when dishPrepTime is null/zero
          final rawPrepTime = d.product?.dishPrepTime ?? 0;
          final dishPrepTime = rawPrepTime > 0
              ? rawPrepTime
              : (d.mProdId != null
                    ? productInfoCache[d.mProdId]?.dishPrepTime ?? 0
                    : 0);
          final prepSeconds = dishPrepTime * (d.qty ?? 1) * 60;

          // ✅ FIX: For "preparing" items already started, use startPrep to
          // calculate accurate remaining time instead of resetting to full prep time.
          // This mirrors web app initializeTimers logic and prevents timer
          // jumping from negative → full prep time on every refresh.
          if (d.status == "preparing" &&
              d.startPrep != null &&
              d.startPrep != "N/A" &&
              d.startPrep!.isNotEmpty) {
            try {
              final startTime = DateTime.parse(d.startPrep!).toLocal();
              final endTime = startTime.add(Duration(seconds: prepSeconds));
              detailEndTimes[d.orderDetId!] = endTime;
              detailTimers[d.orderDetId!] = endTime.difference(now).inSeconds;
            } catch (_) {
              // startPrep parse failed → fall back to fresh countdown
              detailEndTimes[d.orderDetId!] = now.add(
                Duration(seconds: prepSeconds),
              );
              detailTimers[d.orderDetId!] = prepSeconds;
            }
          } else {
            // "ordered" status or no startPrep → start fresh countdown
            detailEndTimes[d.orderDetId!] = now.add(
              Duration(seconds: prepSeconds),
            );
            detailTimers[d.orderDetId!] = prepSeconds;
          }
          autoExtended.putIfAbsent(d.orderDetId!, () => false);
        }

        // Start global countdown ticking
        startGlobalTimer();
      } else {
        // no active order → no timers
        stopGlobalTimer();
        detailTimers.clear();
        detailEndTimes.clear();
        autoExtended.clear();
      }

      // --------------------------------------------------
      // SORT: ACTIVE ORDER AT TOP, THEN NEWEST FIRST
      // --------------------------------------------------
      reorderOrders();

      // Save timer state
      saveTimerState();

      // Note: Auto-print disabled for testing phase
      // Use manual Print button on KDS orders instead
    } finally {
      _isKitchenFetching = false;
      if (!silent) {
        setKdsLoading(false);
      }
      notifyListeners();
    }
  }

  //-✅--GetReadyOrderListService-----------------------------------------✅-//
  /// Fetches orders ready to serve from /kitchen/ready endpoint
  Future<void> GetReadyOrderListService(
    BuildContext context,
    DateTime selectedDate,
  ) async {
    if (!context.mounted) return;
    if (_isReadyFetching) return; // ✅ Prevent duplicate concurrent calls
    _isReadyFetching = true;

    final httpCtrl = context.read<HttpServiceProvider>();
    final userInfo = context.read<UserInfoProvider>();
    final token = userInfo.AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url:
            "${FilterOrderListService}ready?branch_id=${userInfo.branchId}&date=$dateStr&station_id=${selectedStationID ?? 'all'}",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (responseRaw is! Map<String, dynamic>) {
        ReadyToServeOrderListing = [];
        notifyListeners();
        return;
      }

      final dataList = responseRaw['data'];
      if (dataList is! List) {
        ReadyToServeOrderListing = [];
        notifyListeners();
        return;
      }

      ReadyToServeOrderListing = dataList
          .whereType<Map<String, dynamic>>()
          .map(KitchenOrderModel.fromKitchenJson)
          .where((order) {
            // ✅ Safety filter: Only show orders with prepared items (not served/cancelled)
            final hasReadyItems = (order.details ?? []).any((d) {
              final itemStatus = d.status?.toLowerCase() ?? '';
              return itemStatus == 'prepared';
            });
            return hasReadyItems;
          })
          .toList();

      // ✅ Sound trigger: compare current prepared items with previously known ones
      final currentPreparedIds = <int>{};
      for (final order in ReadyToServeOrderListing) {
        for (final detail in order.details ?? []) {
          if (detail.orderDetId != null &&
              detail.status?.toLowerCase() == 'prepared') {
            currentPreparedIds.add(detail.orderDetId!);
          }
        }
      }

      if (!_isPreparedIdsInitialized) {
        _knownPreparedDetailIds = currentPreparedIds;
        _isPreparedIdsInitialized = true;
      } else {
        final newPreparedIds = currentPreparedIds.difference(_knownPreparedDetailIds);
        if (newPreparedIds.isNotEmpty) {
          _playNotificationSound();
        }
        _knownPreparedDetailIds = currentPreparedIds;
      }
    } catch (e, stack) {
      ReadyToServeOrderListing = [];
      debugPrintStack(stackTrace: stack);
    } finally {
      _isReadyFetching = false;
      notifyListeners();
    }
  }

  //--🔹--getProductsInfoService----------------------------------------🔹--//
  /// Fetches product info (name, price, send_to_kds, dish_prep_time, station_id)
  /// for a list of product IDs from POST /order-master/products-info.
  /// Results are cached in [productInfoCache] for use in timer calculations.
  Future<void> getProductsInfoService(
    BuildContext context,
    List<int> productIds,
  ) async {
    if (!context.mounted || productIds.isEmpty) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token = context.read<UserInfoProvider>().AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final dynamic responseRaw = await httpCtrl.request(
        method: 'POST',
        url: ProductsInfoService,
        context: context,
        headers: authHeaders,
        body: {"product_ids": productIds},
        requireLogin: true,
      );

      if (responseRaw is Map<String, dynamic> &&
          responseRaw['success'] == true) {
        final data = responseRaw['data'];
        if (data is Map<String, dynamic>) {
          data.forEach((key, value) {
            final id = int.tryParse(key);
            if (id != null && value is Map<String, dynamic>) {
              productInfoCache[id] = ProductInfoData.fromJson(value);
            }
          });
        }
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      // Non-critical: silently fail — timers fall back to 0
    }
  }

  //-✅--TIMER SYSTEM-----------------------------------------------------✅-//
  Map<int, int> detailTimers = {};
  Map<int, bool> autoExtended = {};
  Map<int, DateTime> detailEndTimes = {};
  Timer? countdownTimer;

  void startGlobalTimer() {
    if (countdownTimer != null && countdownTimer!.isActive) return;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      // Update only the timers belonging to the active order
      final activeOrder = KitchenOrderListing.firstWhereOrNull(
        (o) => o.orderId == activeOrderId,
      );

      if (activeOrder == null) {
        // nothing to update
        stopGlobalTimer();
        notifyListeners();
        return;
      }

      // Collect active IDs set to restrict updates
      final activeIds = <int>{};
      for (final d in activeOrder.details ?? []) {
        if (d.orderDetId != null) activeIds.add(d.orderDetId!);
      }

      // Update only active ids; remove any detailTimers that don't belong to active order
      final nowIds = detailEndTimes.keys.toList();
      for (final id in nowIds) {
        if (!activeIds.contains(id)) {
          // keep storage clean: remove timers for non-active items
          detailTimers.remove(id);
          detailEndTimes.remove(id);
          autoExtended.remove(id);
        }
      }

      // Update remaining (active) timers
      for (final id in activeIds) {
        if (detailEndTimes.containsKey(id)) {
          detailTimers[id] = detailEndTimes[id]!.difference(now).inSeconds;
        } else {
          // fallback: if endTime missing set from existing detailTimers or 0
          detailTimers[id] = detailTimers[id] ?? 0;
        }
      }

      saveTimerState();
      notifyListeners();
    });
  }

  int getMaxTimerOfOrder(KitchenOrderModel order) {
    int maxValue = 0;
    final now = DateTime.now();

    for (final d in order.details ?? []) {
      if (d.status == "prepared") continue;

      int timer = 0;

      // ✅ Active order → live timer
      if (order.orderId == activeOrderId) {
        if (detailEndTimes.containsKey(d.orderDetId)) {
          timer = detailEndTimes[d.orderDetId]!.difference(now).inSeconds;
        } else if (detailTimers.containsKey(d.orderDetId)) {
          timer = detailTimers[d.orderDetId!]!;
        } else {
          timer = (d.product?.dishPrepTime ?? 0) * (d.qty ?? 1) * 60;
        }
        if (timer < 0) timer = 0;
      }
      // ✅ Non-active order → static prep time
      else {
        timer = (d.product?.dishPrepTime ?? 0) * (d.qty ?? 1) * 60;
      }

      if (timer > maxValue) maxValue = timer;
    }

    return maxValue;
  }

  void stopGlobalTimer() => countdownTimer?.cancel();

  String formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;

    final mm = m.abs().toString().padLeft(2, '0');
    final ss = s.abs().toString().padLeft(2, '0');

    return sec >= 0 ? "$mm:$ss" : "-$mm:$ss";
  }

  void initializeAllOrderTimers() {
    final now = DateTime.now();
    for (final order in KitchenOrderListing) {
      for (final d in order.details ?? []) {
        final prepSeconds =
            (d.product?.dishPrepTime ?? 0) * ((d.qty ?? 1)) * 60;

        detailTimers.putIfAbsent(d.orderDetId!, () => prepSeconds);
        autoExtended.putIfAbsent(d.orderDetId!, () => false);
        detailEndTimes.putIfAbsent(
          d.orderDetId!,
          () => now.add(Duration(seconds: detailTimers[d.orderDetId!]!)),
        );
      }
    }

    startGlobalTimer();
    saveTimerState();
    notifyListeners();
  }

  Future<void> saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefDetailTimersKey,
      jsonEncode(detailTimers.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _prefAutoExtKey,
      jsonEncode(autoExtended.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _prefDetailEndTimesKey,
      jsonEncode(
        detailEndTimes.map(
          (k, v) => MapEntry(k.toString(), v.toIso8601String()),
        ),
      ),
    );

    if (activeOrderId != null) {
      await prefs.setInt(_prefActiveOrderIdKey, activeOrderId!);
    } else {
      await prefs.remove(_prefActiveOrderIdKey);
    }
  }

  Future<void> restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTimers = prefs.getString(_prefDetailTimersKey);
    final storedAutoExt = prefs.getString(_prefAutoExtKey);
    final storedEndTimes = prefs.getString(_prefDetailEndTimesKey);
    final storedActiveOrder = prefs.getInt(_prefActiveOrderIdKey);

    if (storedTimers != null) {
      detailTimers = (jsonDecode(storedTimers) as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      );
    }

    if (storedAutoExt != null) {
      autoExtended = (jsonDecode(storedAutoExt) as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as bool),
      );
    }

    if (storedEndTimes != null) {
      detailEndTimes = (jsonDecode(storedEndTimes) as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), DateTime.parse(v as String)),
      );
    }

    // Restore active order id (if present)
    if (storedActiveOrder != null) {
      activeOrderId = storedActiveOrder;
    }

    // DO NOT start timer here — we will start it only after fetching orders in InitializeData
    notifyListeners();
  }

  void resetDetailTimer(int orderDetId) {
    final now = DateTime.now();

    detailTimers[orderDetId] = 0;
    autoExtended[orderDetId] = false;
    detailEndTimes[orderDetId] = now;

    saveTimerState();
    notifyListeners();
  }

  // ✅ Swipe / Single Item Serve
  void markDetailOrderItemAsServed(int orderId, int detailId) {
    // ✅ Remove from KitchenOrderListing (active panel)
    final order = KitchenOrderListing.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => KitchenOrderModel(),
    );
    if (order.orderId != null) {
      order.details?.removeWhere((d) => d.orderDetId == detailId);
    }

    // ✅ FIXED: Also remove from ReadyToServeOrderListing (ready panel)
    final readyOrder = ReadyToServeOrderListing.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => KitchenOrderModel(),
    );
    if (readyOrder.orderId != null) {
      readyOrder.details?.removeWhere((d) => d.orderDetId == detailId);
      ReadyToServeOrderListing.removeWhere((o) => (o.details ?? []).isEmpty);
    }

    // ✅ FIX: Remove order from KitchenOrderListing if all items served (like web app)
    if (order.details == null || order.details!.isEmpty) {
      KitchenOrderListing.removeWhere((o) => o.orderId == orderId);

      // Clear active order if it was active
      if (activeOrderId == orderId) {
        activeOrderId = null;
        stopGlobalTimer();
        _checkAndStartNextOrder(orderId);
      }
    }

    // ------ REMOVE TIMERS ------
    detailTimers.remove(detailId);
    detailEndTimes.remove(detailId);
    autoExtended.remove(detailId);
    _knownPreparedDetailIds.remove(detailId);

    // ✅ Check if current order finished
    if (order.details != null && order.details!.isNotEmpty) {
      _checkAndStartNextOrder(orderId);
    }

    reorderOrders();
    saveTimerState();
    notifyListeners();
  }

  // ✅ Select-All / Multiple Items Serve
  Future<void> markDetailOrderItemsAsServedAll(
    BuildContext context,
    int orderId,
    List<int> detailIds,
  ) async {
    final order = KitchenOrderListing.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => KitchenOrderModel(),
    );

    if (order.orderId == null) return;

    bool allServed = true;

    for (final detailId in detailIds) {
      final success = await OrderServedService(
        context,
        "served",
        orderId.toString(),
        detailId.toString(),
      );

      if (success) {
        // Remove locally
        order.details?.removeWhere((d) => d.orderDetId == detailId);
        detailTimers.remove(detailId);
        detailEndTimes.remove(detailId);
        autoExtended.remove(detailId);
        _knownPreparedDetailIds.remove(detailId);
      } else {
        allServed = false; // retry failed items later
      }
    }

    // ✅ FIX: Remove order from KitchenOrderListing if all items served
    if (order.details == null || order.details!.isEmpty) {
      KitchenOrderListing.removeWhere((o) => o.orderId == orderId);

      // Clear active order if it was active
      if (activeOrderId == orderId) {
        activeOrderId = null;
        stopGlobalTimer();
      }

      _checkAndStartNextOrder(orderId);
    }

    reorderOrders();
    saveTimerState();
    notifyListeners();
  }

  // 🔹 Helper function to check & start next order timer
  // 🔹 Helper function to check & start next order timer
  void _checkAndStartNextOrder(int finishedOrderId) {
    final finishedOrder = KitchenOrderListing.firstWhereOrNull(
      (o) => o.orderId == finishedOrderId,
    );

    // Remove timers for finished order (optional, only if fully prepared)
    if (finishedOrder != null &&
        (finishedOrder.details == null || finishedOrder.details!.isEmpty)) {
      for (final d in finishedOrder.details ?? []) {
        final id = d.orderDetId;
        if (id != null) {
          detailTimers.remove(id);
          detailEndTimes.remove(id);
          autoExtended.remove(id);
        }
      }
    }

    // If finished order was active, clear it
    if (activeOrderId == finishedOrderId) {
      activeOrderId = null;
      stopGlobalTimer();
    }

    // Pick next pending order
    final nextOrder = KitchenOrderListing.firstWhereOrNull(
      (o) => (o.details ?? []).any(
        (d) =>
            d.status == "preparing" ||
            d.status == "ordered" ||
            d.status == "pending",
      ),
    );

    if (nextOrder != null) {
      activeOrderId = nextOrder.orderId;
      initializeActiveOrderTimers(); // start timers only for new active order
      startGlobalTimer();
    }

    reorderOrders(); // UI: active order on top
    saveTimerState();
    notifyListeners();
  }

  bool isOrderLoading = false;

  bool get isOrderLoader => isOrderLoading;

  // ✅ Per-item undo loading — prevents global button lock-out during undo
  final Set<int> _undoLoadingIds = {};
  bool isItemUndoing(int detailId) => _undoLoadingIds.contains(detailId);

  void setOrderLoading(bool value) {
    if (isOrderLoading != value) {
      isOrderLoading = value;
      notifyListeners();
    }
  }

  //-✅--Order-Prepared---------------------------------------------------✅-//
  Future<bool> OrderPreparedService(
    BuildContext context,
    String Status,
    String OrderID,
    String orderDetId,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      setOrderLoading(true);
      notifyListeners();

      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        setOrderLoading(false);
        return false;
      }

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final Map<String, dynamic> requestBody = {
        "status": Status,
        "end_prep": DateTime.now().toUtc().toIso8601String(),
      };

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$orderDetId",
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // ✅ Accept: success flag OR data.status match OR already prepared (NO_CHANGES = item already correct)
      final bool success =
          response['success'] == true ||
          response['data']?['status'] == 'prepared' ||
          response['errorCode'] ==
              'NO_CHANGES'; // ✅ item already prepared — treat as success
      final String msg = response['message']?.toString() ?? 'Unknown response';

      if (success) {
        // Remove only the prepared item
        final order = KitchenOrderListing.firstWhere(
          (o) => o.orderId.toString() == OrderID,
          orElse: () => KitchenOrderModel(),
        );

        if (order.orderId == null) return false;

        // ✅ Remove prepared detail
        order.details?.removeWhere(
          (d) => d.orderDetId.toString() == orderDetId,
        );

        // ✅ Remove timers for this item only
        final detIdInt = int.tryParse(orderDetId);
        if (detIdInt != null) {
          detailTimers.remove(detIdInt);
          detailEndTimes.remove(detIdInt);
          autoExtended.remove(detIdInt);
        }

        // ✅ FIX: Sync order status BEFORE UI update (prevent race condition - web app pattern)
        await _syncOrderMasterStatus(context, OrderID);

        // ✅ If all items prepared → remove from active listing
        if (order.details == null || order.details!.isEmpty) {
          KitchenOrderListing.removeWhere(
            (o) => o.orderId.toString() == OrderID,
          );

          // Clear active order if it was active
          if (activeOrderId == order.orderId) {
            activeOrderId = null;
            stopGlobalTimer();
          }

          _checkAndStartNextOrder(order.orderId!);
        }

        notifyListeners();
      } else {
        showCustomToast(context: context, message: msg);
        return false;
      }

      return true; // ✅ Swipe Confirm
    } catch (_) {
      return false; // ❌ Swipe Rollback
    } finally {
      setOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--getPendingKitchenOrderCount--------------------------------------✅-//
  int getPendingKitchenOrderCount() {
    return KitchenOrderListing.where((order) {
      final details = order.details ?? [];
      return details.any(
        (d) => d.status == "preparing" || d.status == "ordered",
      );
    }).length;
  }

  //-✅--getReadyToServeOrderCount----------------------------------------✅-//
  int getReadyToServeOrderCount() {
    // ✅ FIXED: Use dedicated ReadyToServeOrderListing from /kitchen/ready endpoint
    return ReadyToServeOrderListing.length;
  }

  //-✅--Order-Served-----------------------------------------------------✅-//
  Future<bool> OrderServedService(
    BuildContext context,
    String Status,
    String OrderID,
    String orderDetId,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      setOrderLoading(true);
      notifyListeners();

      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        setOrderLoading(false);
        return false;
      }

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final Map<String, dynamic> requestBody = {"status": Status};

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$orderDetId",
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // ✅ Accept: success flag OR data.status match OR already served (NO_CHANGES = item already correct)
      final bool success =
          response['success'] == true ||
          response['data']?['status'] == 'served' ||
          response['errorCode'] ==
              'NO_CHANGES'; // ✅ item already served — treat as success
      final String msg = response['message']?.toString() ?? 'Unknown response';

      if (!success) {
        showCustomToast(context: context, message: msg);
        return false;
      }

      // ✅ Sync order_master.order_status so ORDER screen filters work
      await _syncOrderMasterStatus(context, OrderID);

      return true; // ✅ Swipe Confirm
    } catch (_) {
      return false; // ❌ Swipe Rollback
    } finally {
      setOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--startItemPreparation---------------------------------------------✅-//
  /// 🔹 NEW: Manually start an item (ordered → preparing)
  /// Web equivalent: startItemPreparationWithTimer()
  Future<bool> startItemPreparation(
    BuildContext context,
    String orderId,
    String orderDetId,
  ) async {
    if (!context.mounted) return false;

    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setOrderLoading(true);
      notifyListeners();

      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        setOrderLoading(false);
        return false;
      }

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // ✅ Mark item as "preparing" and record start time
      final Map<String, dynamic> requestBody = {
        "status": "preparing",
        "start_prep": DateTime.now().toUtc().toIso8601String(),
      };

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$orderDetId",
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      final bool success =
          response['success'] == true ||
          response['data']?['status'] == 'preparing' ||
          response['errorCode'] == 'NO_CHANGES';

      if (!success) {
        final String msg = response['message']?.toString() ?? 'Failed to start';
        showCustomToast(context: context, message: msg);
        return false;
      }

      // ✅ Initialize timer for this specific item
      final detIdInt = int.tryParse(orderDetId);
      if (detIdInt != null) {
        // Find the item to get its prep time
        final order = KitchenOrderListing.firstWhereOrNull(
          (o) => o.orderId.toString() == orderId,
        );
        if (order != null) {
          final detail = order.details?.firstWhereOrNull(
            (d) => d.orderDetId == detIdInt,
          );
          if (detail != null) {
            final prepSeconds =
                (detail.product?.dishPrepTime ?? 0) * (detail.qty ?? 1) * 60;
            final now = DateTime.now();
            detailEndTimes[detIdInt] = now.add(Duration(seconds: prepSeconds));
            detailTimers[detIdInt] = prepSeconds;
            autoExtended.putIfAbsent(detIdInt, () => false);

            // ✅ Update item status locally
            detail.status = "preparing";
          }
        }
      }

      // ✅ Save timer state and refresh UI
      saveTimerState();
      notifyListeners();

      // ✅ Sync order master status
      await _syncOrderMasterStatus(context, orderId);

      return true;
    } catch (e) {
      debugPrint("❌ startItemPreparation error: $e");
      return false;
    } finally {
      setOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--_syncOrderMasterStatus-------------------------------------------✅-//
  /// Mirrors the web app's `updateOrderMasterStatus`.
  /// After any KDS item status change, re-fetch the full order from the backend,
  /// compute the aggregate order status from all non-cancelled item statuses,
  /// and persist it via PUT /order-master/{id}.
  /// Without this, order_master.order_status stays "ordered" even after KDS marks
  /// all items prepared — causing the ORDER screen "Prepared" filter to return 0.
  Future<void> _syncOrderMasterStatus(
    BuildContext context,
    String orderId,
  ) async {
    if (!context.mounted) return;
    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // 1️⃣  Fetch full order to get current item statuses
      final resp = await httpCtrl.request(
        method: 'GET',
        url: "$OrderListService$orderId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );
      if (resp is! Map<String, dynamic>) return;

      // Response may be wrapped under 'data' key or returned directly
      final dynamic orderData = resp['data'] ?? resp;
      if (orderData is! Map<String, dynamic>) return;

      // 2️⃣  Collect non-cancelled item statuses
      final rawDetails =
          orderData['details'] ?? orderData['order_details'] ?? [];
      if (rawDetails is! List || rawDetails.isEmpty) return;

      final List<String> statuses = rawDetails
          .map<String>((d) => (d['status'] ?? '').toString())
          .where((s) => s != 'cancelled')
          .toList();
      if (statuses.isEmpty) return;

      // 3️⃣  Determine aggregate status (same logic as web app)
      String newStatus;
      if (statuses.every((s) => s == 'served')) {
        newStatus = 'served';
      } else if (statuses.every((s) => s == 'prepared' || s == 'served')) {
        newStatus = 'prepared';
      } else if (statuses.any((s) => s == 'preparing')) {
        newStatus = 'preparing';
      } else {
        newStatus = 'ordered';
      }

      // 4️⃣  Skip if already in sync
      final String currentStatus = (orderData['order_status'] ?? '').toString();
      if (currentStatus == newStatus) return;

      // 5️⃣  Persist the updated order status
      await httpCtrl.request(
        method: 'PUT',
        url: "$OrderListService$orderId",
        context: context,
        headers: authHeaders,
        body: {'order_status': newStatus},
        requireLogin: true,
      );
    } catch (_) {
      // Non-critical — swipe already succeeded, so fail silently
    }
  }

  //-✅--reorderOrders----------------------------------------------------✅-//
  /// Sort: active order first, then remaining orders newest → oldest.
  /// This ensures new orders always appear at the top, below the active order.
  void reorderOrders() {
    KitchenOrderListing.sort((a, b) {
      // Active order always at top
      if (a.orderId == activeOrderId) return -1;
      if (b.orderId == activeOrderId) return 1;
      // Secondary: newest order date first
      final aDate = a.orderDate != null
          ? DateTime.tryParse(a.orderDate!)
          : null;
      final bDate = b.orderDate != null
          ? DateTime.tryParse(b.orderDate!)
          : null;
      if (aDate != null && bDate != null) return bDate.compareTo(aDate);
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return 0;
    });
  }

  //-✅--initializeActiveOrderTimers--------------------------------------✅-//
  void initializeActiveOrderTimers() {
    final now = DateTime.now();
    final activeOrder = KitchenOrderListing.firstWhereOrNull(
      (o) => o.orderId == activeOrderId,
    );
    if (activeOrder == null) return;

    final activeIds = <int>{};
    for (final d in activeOrder.details ?? []) {
      if (d.orderDetId != null && d.status != "prepared") {
        activeIds.add(d.orderDetId!);
      }
    }

    // Clear only timers not in active order
    final existingIds = detailEndTimes.keys.toList();
    for (final id in existingIds) {
      if (!activeIds.contains(id)) {
        detailTimers.remove(id);
        detailEndTimes.remove(id);
        autoExtended.remove(id);
      }
    }

    // Initialize or sync timers
    for (final d in activeOrder.details ?? []) {
      final id = d.orderDetId;
      if (id == null || d.status == "prepared") continue;

      final prepSeconds = (d.product?.dishPrepTime ?? 0) * (d.qty ?? 1) * 60;

      // ✅ FIX: For "preparing" items, always recompute from startPrep so
      // the timer correctly reflects elapsed time (may be negative = overdue).
      // For "ordered" items, only reset if no valid endTime exists.
      if (d.status == "preparing" &&
          d.startPrep != null &&
          d.startPrep != "N/A" &&
          d.startPrep!.isNotEmpty) {
        try {
          final startTime = DateTime.parse(d.startPrep!).toLocal();
          detailEndTimes[id] = startTime.add(Duration(seconds: prepSeconds));
        } catch (_) {
          // parse failed → only reset if completely missing
          if (!detailEndTimes.containsKey(id)) {
            detailEndTimes[id] = now.add(Duration(seconds: prepSeconds));
          }
        }
      } else if (!detailEndTimes.containsKey(id) ||
          detailEndTimes[id]!.isBefore(now)) {
        // "ordered" or no startPrep → fresh countdown
        detailEndTimes[id] = now.add(Duration(seconds: prepSeconds));
      }

      // Update detailTimers
      detailTimers[id] = detailEndTimes[id]!.difference(now).inSeconds;

      autoExtended.putIfAbsent(id, () => false);
    }
  }

  //-✅--undoItemToPreparingService---------------------------------------✅-//
  /// Reverts a single "prepared" item back to "preparing" status.
  /// Used by the Undo button in the Ready-to-Serve panel.
  /// Only calls the API and returns success/fail — the caller is responsible
  /// for refreshing both KitchenOrderListing and ReadyToServeOrderListing.
  Future<bool> undoItemToPreparingService(
    BuildContext context,
    String orderId,
    String detailId,
  ) async {
    if (!context.mounted) return false;
    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    // ✅ Register per-item loading immediately so UI shows spinner
    final int? detIdInt = int.tryParse(detailId);
    if (detIdInt != null) {
      _undoLoadingIds.add(detIdInt);
      notifyListeners();
    }
    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$detailId",
        context: context,
        headers: authHeaders,
        body: {"status": "preparing"},
        requireLogin: true,
      );

      final bool success =
          response['success'] == true ||
          response['data']?['status'] == 'preparing' ||
          response['errorCode'] == 'NO_CHANGES';

      return success;
    } catch (_) {
      return false;
    } finally {
      if (detIdInt != null) _undoLoadingIds.remove(detIdInt);
      notifyListeners();
    }
  }

  //-✅--undoItemToOrderedService-----------------------------------------✅-//
  /// Reverts a single "preparing" item back to "ordered" status.
  /// Used by the Undo button in the Kitchen Orders panel for preparing items.
  /// Stops the timer for the item and clears timer state.
  /// The caller is responsible for refreshing the kitchen order listing.
  Future<bool> undoItemToOrderedService(
    BuildContext context,
    String orderId,
    String detailId,
  ) async {
    if (!context.mounted) return false;
    final httpCtrl = context.read<HttpServiceProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    // ✅ Register per-item loading immediately so UI shows spinner
    final int? detIdInt = int.tryParse(detailId);
    if (detIdInt != null) {
      _undoLoadingIds.add(detIdInt);
      notifyListeners();
    }
    try {
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) return false;

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final response = await httpCtrl.request(
        method: 'PUT',
        url: "$OrderNowService$detailId",
        context: context,
        headers: authHeaders,
        body: {"status": "ordered"},
        requireLogin: true,
      );

      final bool success =
          response['success'] == true ||
          response['data']?['status'] == 'ordered' ||
          response['errorCode'] == 'NO_CHANGES';

      // ✅ If successful, stop timer and clear timer state
      if (success && detIdInt != null) {
        detailTimers.remove(detIdInt);
        detailEndTimes.remove(detIdInt);
        autoExtended.remove(detIdInt);
        await saveTimerState();
      }

      return success;
    } catch (_) {
      return false;
    } finally {
      if (detIdInt != null) _undoLoadingIds.remove(detIdInt);
      notifyListeners();
    }
  }

  //-✅--Header-Search-Filter-Refresh-------------------------------------✅-//
  //-- Date Selection -------------------------------------------------//
  DateTime selectedKDSDate = DateTime.now(); // Default: today
  TextEditingController SearchKDSController = TextEditingController();
  final FocusNode myFocusNodeSearchKDS = FocusNode();

  /// Opens a simple date picker dialog and updates `selectedKDSDate`
  Future<void> selectKDSDate(BuildContext context) async {
    final minDate = DateTime(1970, 1, 1);
    final maxDate = DateTime.now();
    DateTime? pickedDate = selectedKDSDate;

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
            contentPadding: EdgeInsets.all(AppDimensions.sm),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.sm,
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
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.md,
                                      ),
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
      updateSelectedDate(pickedDate!);
      if (selectedFilterOrderTab == 0) {
        await GetFilterOrderListService(
          context,
          "active",
          selectedKDSDate.toString(),
        );
      }
      if (selectedFilterOrderTab == 1) {
        await GetFilterOrderListService(
          context,
          "ready",
          selectedKDSDate.toString(),
        );
      }
      if (selectedFilterOrderTab == 2) {
        await GetFilterOrderListService(
          context,
          "completed",
          selectedKDSDate.toString(),
        );
      }
      if (selectedFilterOrderTab == 3) {
        await GetFilterOrderListService(
          context,
          "cancelled",
          selectedKDSDate.toString(),
        );
      }
      await GetKitchenOrderListService(context, selectedKDSDate);
      await GetReadyOrderListService(context, selectedKDSDate);
      SearchKDSController.clear();
      myFocusNodeSearchKDS.unfocus();
    }
  }

  /// Updates the selected date (from calendar or any other source)
  void updateSelectedDate(DateTime newDate) {
    selectedKDSDate = newDate;
    resetPreparedTracking();
    notifyListeners();
  }

  //-- StationList -------------------------------------------------//

  List<StationModel> StationListing = [];
  String? selectedStationType;
  String? selectedStationID;

  Future<void> GetStationListService(BuildContext context) async {
    if (!context.mounted) return;
    StationListing.clear();
    selectedStationType = null;
    selectedStationID = null;

    final httpCtrl = context.read<HttpServiceProvider>();
    final isOnlineProvider = context.read<CheckInternetProvider>();
    final userInfo = context.read<UserInfoProvider>();

    final isOnline = isOnlineProvider.isConnected;
    final token = userInfo.AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    if (!isOnline) return;

    setKdsLoading(true);
    notifyListeners();

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$StationListService${userInfo.branchId}",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (responseRaw is List) {
        StationListing = responseRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => StationModel.fromJson(e))
            .toList();

        // ✅ By default first item select if list not empty
        if (StationListing.isNotEmpty) {
          selectedStationType = StationListing[0].stationName;
          selectedStationID = StationListing[0].stationId.toString();
        }
      } else {
        StationListing = [];
        GlobalFunction().showError(context, "⚠️ Unexpected response format");
      }

      notifyListeners();
    } catch (e, stack) {
      StationListing = [];
      debugPrintStack(stackTrace: stack);
    } finally {
      setKdsLoading(false);
      notifyListeners();
    }
  }

  // ✅ Dropdown selection update
  void updateStation(String? stationName) {
    if (stationName == null) return;

    selectedStationType = stationName;

    final selectedModel = StationListing.firstWhere(
      (station) => station.stationName == stationName,
      orElse: () => StationModel(),
    );

    selectedStationID = selectedModel.stationId.toString();

    GlobalFunction().debugFunction("✅ Selected Station: $selectedStationType");
    GlobalFunction().debugFunction(
      "🔍 Selected Station ID: $selectedStationID",
    );

    resetPreparedTracking();
    notifyListeners();
  }

  //-- FilterOrderList -------------------------------------------------//
  bool isFilterDisplay = false;
  List<FilterOrderData> FilterOrderListing = [];

  // ✅ Modal states (like web app)
  bool showCompletedModal = false;
  bool showCancelledModal = false;
  List<FilterOrderData> completedOrdersList = [];
  List<FilterOrderData> cancelledOrdersList = [];

  void toggleCompletedModal(bool show) {
    showCompletedModal = show;
    notifyListeners();
  }

  void toggleCancelledModal(bool show) {
    showCancelledModal = show;
    notifyListeners();
  }

  Future<void> GetFilterOrderListService(
    BuildContext context,
    String OrderAPI,
    String SelectedDate, {
    bool silent = false,
  }) async {
    if (!context.mounted) return;
    if (!silent) {
      setKdsLoading(true);
      notifyListeners();
      FilterOrderListing.clear();
    }

    final httpCtrl = context.read<HttpServiceProvider>();
    final isOnlineProvider = context.read<CheckInternetProvider>();
    final userInfo = context.read<UserInfoProvider>();

    final isOnline = isOnlineProvider.isConnected;
    final token = userInfo.AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    if (!isOnline) return;

    // ✅ FIXED: Always send YYYY-MM-DD only — DateTime.toString() gives full timestamp
    // e.g. "2026-03-03 10:36:16.809249" → "2026-03-03"
    final dateStr = SelectedDate.length >= 10
        ? SelectedDate.substring(0, 10)
        : SelectedDate;

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url:
            "$FilterOrderListService$OrderAPI?branch_id=${userInfo.branchId}&date=$dateStr&station_id=${selectedStationID ?? 'all'}",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔥 FIX: API RESPONSE IS A MAP, NOT A LIST
      if (responseRaw is Map<String, dynamic>) {
        final dataList = responseRaw["data"];

        if (dataList is List) {
          FilterOrderListing = dataList
              .whereType<Map<String, dynamic>>()
              .map((e) => FilterOrderData.fromJson(e))
              .toList();

          // ✅ Populate modal lists and cache counts (web app pattern)
          if (OrderAPI == "completed") {
            completedOrders = FilterOrderListing.length;
            completedOrdersList = List.from(FilterOrderListing);
          } else if (OrderAPI == "cancelled") {
            cancelledOrders = FilterOrderListing.length;
            cancelledOrdersList = List.from(FilterOrderListing);
          }

          // ✅ HIDE filter table for Active(0)/Ready(1)/Completed(1)/Cancelled(2)
          // Only show Kitchen Orders + Ready to Serve panels (like web app)
          // Completed/Cancelled now use modals
          isFilterDisplay = false;
        } else {
          FilterOrderListing = [];
          isFilterDisplay = false;
        }
      } else {
        FilterOrderListing = [];
        isFilterDisplay = false;
        GlobalFunction().showError(context, "⚠️ Unexpected response format");
      }

      notifyListeners();
    } catch (e, stack) {
      FilterOrderListing = [];
      debugPrintStack(stackTrace: stack);
    } finally {
      if (!silent) {
        setKdsLoading(false);
      }
      notifyListeners();
    }
  }

  int selectedFilterOrderTab = 0;

  void updateSelectedFilterTab(int index) {
    selectedFilterOrderTab = index;
    notifyListeners();
  }

  // -----------------------------
  // Updated: InitializeData
  // -----------------------------
  Future<void> InitializeData(BuildContext context) async {
    if (!context.mounted) return;

    resetPreparedTracking();
    setKdsLoading(true);
    KitchenOrderListing = [];

    // STEP A: Get fresh kitchen orders (ordered/preparing status)
    await GetKitchenOrderListService(context, selectedKDSDate);

    // STEP A2: Get ready-to-serve orders (prepared status) from /kitchen/ready
    await GetReadyOrderListService(context, selectedKDSDate);

    // STEP B: Restore previous timers (and possibly persisted activeOrderId)
    await restoreTimerState();

    // STEP C: Now reconcile restored activeOrderId with current orders
    final existingActive = KitchenOrderListing.firstWhereOrNull(
      (o) => o.orderId == activeOrderId,
    );

    if (existingActive == null) {
      // persisted active not present or null => pick next pending
      activeOrderId = KitchenOrderListing.firstWhereOrNull(
        (o) => (o.details ?? []).any(
          (d) =>
              d.status == "preparing" ||
              d.status == "ordered" ||
              d.status == "pending",
        ),
      )?.orderId;
    }

    // STEP D: Initialize timers only for active order and start ticker
    if (activeOrderId != null) {
      initializeActiveOrderTimers();
      startGlobalTimer();
    } else {
      stopGlobalTimer();
    }

    // UI reset
    SearchKDSController.clear();
    myFocusNodeSearchKDS.unfocus();

    // Load Stations
    StationListing = [];
    selectedStationType = null;
    selectedStationID = null;
    await GetStationListService(context);

    // ✅ FIX: Load initial completed/cancelled counts (web app pattern)
    // This ensures counts show immediately on first load
    await GetFilterOrderListService(
      context,
      "completed",
      selectedKDSDate.toString(),
    );
    await GetFilterOrderListService(
      context,
      "cancelled",
      selectedKDSDate.toString(),
    );

    // STEP E: Pre-populate filter table on init.
    // If there are ready orders, show them in the filter table immediately
    // (tab 1 = Ready) so users see actionable data without needing to tap.
    // If no ready orders, try active (tab 0).
    if (ReadyToServeOrderListing.isNotEmpty) {
      selectedFilterOrderTab = 1;
      await GetFilterOrderListService(
        context,
        "ready",
        selectedKDSDate.toString(),
      );
    } else if (KitchenOrderListing.isNotEmpty) {
      selectedFilterOrderTab = 0;
      await GetFilterOrderListService(
        context,
        "active",
        selectedKDSDate.toString(),
      );
    }
    // else: leave isFilterDisplay=false, no table shown

    notifyListeners();
  }

  // preferences key
  static const String _prefDetailTimersKey = "detailTimers";
  static const String _prefAutoExtKey = "autoExtended";
  static const String _prefDetailEndTimesKey = "detailEndTimes";
  static const String _prefActiveOrderIdKey = "activeOrderId";

  /// Helper: Returns display seconds for a detail depending on whether the order is active.
  int getDisplaySecondsForDetail(KitchenOrderModel order, Details detail) {
    final id = detail.orderDetId;
    if (id == null) return 0;

    // ========== ACTIVE ORDER ==========
    if (order.orderId != null && order.orderId == activeOrderId) {
      // If running timer exists (live countdown)
      if (detailTimers.containsKey(id)) {
        return detailTimers[id]!;
      }

      // If countdown was running before and endTime is stored
      if (detailEndTimes.containsKey(id)) {
        return detailEndTimes[id]!.difference(DateTime.now()).inSeconds;
      }

      // Fallback → use startPrep or dishPrep time
      return _calculateStartPrepSeconds(detail);
    }

    // ========== INACTIVE ORDER ==========
    // Always return static startPrep value, even if timer is negative
    return _calculateStartPrepSeconds(detail);
  }

  int _calculateStartPrepSeconds(Details detail) {
    // ✅ Parse ISO 8601 datetime from API (e.g. "2026-02-26T09:16:00.000Z")
    // Previously this was broken — it tried to parse ISO string as HH:mm:ss
    if (detail.startPrep != null && detail.startPrep != "N/A") {
      try {
        final startTime = DateTime.parse(detail.startPrep!).toLocal();
        final prepSecs =
            (detail.product?.dishPrepTime ?? 0) * (detail.qty ?? 1) * 60;
        final expectedEndTime = startTime.add(Duration(seconds: prepSecs));
        return expectedEndTime.difference(DateTime.now()).inSeconds;
      } catch (_) {}
    }
    // fallback = dishPrepTime * qty * 60
    return (detail.product?.dishPrepTime ?? 0) * (detail.qty ?? 1) * 60;
  }

  //-✅--Elapsed Time Helpers---------------------------------------------✅-//

  /// Returns a human-readable elapsed time string.
  /// e.g. "2m ago", "1h 23m ago", "just now"
  String getElapsedTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty || dateTimeStr == "N/A") {
      return "--";
    }
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? "${h}h ${m}m ago" : "${h}h ago";
    } catch (_) {
      return "--";
    }
  }

  /// Returns elapsed minutes since an ISO 8601 datetime string.
  /// Returns -1 if parse fails.
  int getElapsedMinutes(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty || dateTimeStr == "N/A") {
      return -1;
    }
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateTime.now().difference(dt).inMinutes;
    } catch (_) {
      return -1;
    }
  }

  /// Returns a Color indicating urgency for an order based on elapsed time vs
  /// expected prep time (minutes).
  ///   green  → within expected time
  ///   orange → 0–50 % over expected
  ///   red    → more than 50 % over expected
  Color getUrgencyColor(String? orderDateStr, int expectedMinutes) {
    final elapsed = getElapsedMinutes(orderDateStr);
    if (elapsed < 0 || expectedMinutes <= 0) return const Color(0xFF6B7280);
    if (elapsed <= expectedMinutes) {
      return const Color(0xFF16A34A);
    } // green
    if (elapsed <= expectedMinutes * 1.5) {
      return const Color(0xFFF97316); // orange
    }
    return const Color(0xFFDC2626); // red
  }

  /// Returns a Color for a running timer value (seconds remaining).
  ///   green  → > 50 % time left
  ///   orange → 0–50 % time left
  ///   red    → overdue (negative seconds) — always red regardless of prep time
  Color getTimerColor(int secondsRemaining, int totalSeconds) {
    // ✅ FIX: Check overdue FIRST — even 0-prep-time items must show red when elapsed
    // (matches web app: seconds <= 0 → text-red-600 font-bold, bg-red-100)
    if (secondsRemaining <= 0) return const Color(0xFFDC2626); // red — overdue
    if (totalSeconds <= 0)
      return const Color(0xFF6B7280); // gray — no prep time set
    final ratio = secondsRemaining / totalSeconds;
    if (ratio > 0.5) return const Color(0xFF16A34A); // green
    if (ratio > 0) return const Color(0xFFF97316); // orange
    return const Color(0xFFDC2626); // red
  }
}

//-✅---------------------------------------------------------------------✅-//
