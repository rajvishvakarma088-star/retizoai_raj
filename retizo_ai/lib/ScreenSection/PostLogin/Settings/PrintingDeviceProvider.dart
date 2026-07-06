// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../HTTPRepository/GlobalServiceURL.dart';
import '../../../services/epson_printer_plugin.dart';
import '../../../services/printer_models.dart';
import '../KDS/Controller/PrinterIntegrationProvider.dart';

/// Model for a single printing device returned by GET /api/printingDevice
class PrintingDevice {
  final int deviceId;
  final String orgId;
  final int branchId;
  final String deviceName;

  /// "kds" or "cashier"
  final String type;
  final String ipAddress;
  final int portNumber;

  const PrintingDevice({
    required this.deviceId,
    required this.orgId,
    required this.branchId,
    required this.deviceName,
    required this.type,
    required this.ipAddress,
    required this.portNumber,
  });

  factory PrintingDevice.fromJson(Map<String, dynamic> json) {
    return PrintingDevice(
      deviceId: (json['device_id'] as num?)?.toInt() ?? 0,
      orgId: json['org_id']?.toString() ?? '',
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      deviceName: json['device_name']?.toString() ?? 'Unknown',
      type: json['type']?.toString().toLowerCase() ?? 'cashier',
      ipAddress: json['ip_address']?.toString() ?? '',
      portNumber: (json['port_number'] as num?)?.toInt() ?? 9100,
    );
  }

  /// Epson SDK target string, e.g. "TCP:192.168.29.115"
  String get tcpTarget => 'TCP:$ipAddress';

  bool get isKds => type == 'kds';
  bool get isCashier => type == 'cashier';
}

/// Provider that manages printing devices from the backend.
///
/// Responsibilities:
///   1. Fetch device list from GET /api/printingDevice
///   2. Auto-connect the first KDS device on fetch
///   3. Persist the KDS config so the existing restore-on-startup logic
///      in PrinterIntegrationProvider picks it up automatically
///   4. Expose autoPrintKDS() for order-creation auto-print
class PrintingDeviceProvider with ChangeNotifier {
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  List<PrintingDevice> _devices = [];
  bool _isLoading = false;
  String? _error;
  bool _kdsConnected = false;
  bool _cashierConnected = false;

  // ── Public getters ──────────────────────────────────────────────────────
  List<PrintingDevice> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get kdsConnected => _kdsConnected;
  bool get cashierConnected => _cashierConnected;

  /// All KDS devices from backend (type == "kds")
  List<PrintingDevice> get kdsDevices =>
      _devices.where((d) => d.isKds).toList();

  /// All cashier devices from backend (type == "cashier")
  List<PrintingDevice> get cashierDevices =>
      _devices.where((d) => d.isCashier).toList();

  /// Primary KDS device — index[0] of kds-type devices, per backend team spec.
  PrintingDevice? get primaryKdsDevice =>
      kdsDevices.isNotEmpty ? kdsDevices.first : null;

  /// Primary cashier device — index[0] of cashier-type devices.
  PrintingDevice? get primaryCashierDevice =>
      cashierDevices.isNotEmpty ? cashierDevices.first : null;

  // ── Fetch devices from backend ──────────────────────────────────────────
  /// Fetches the device list and auto-connects the primary KDS printer.
  /// Call this after login (from BackgroundApiProvider or wherever
  /// post-login init happens).
  Future<void> fetchAndConnect(String accessToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse(GlobalServiceURL.PrintingDeviceUrl),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        _devices = json
            .map((d) => PrintingDevice.fromJson(d as Map<String, dynamic>))
            .toList();
        debugPrint(
          '📡 [PrintingDevice] Fetched ${_devices.length} devices '
          '(${kdsDevices.length} KDS, ${cashierDevices.length} cashier)',
        );

        // Auto-connect primary KDS and cashier devices, persist their configs
        await _autoConnectKds();
        await _autoConnectCashier();
      } else {
        _error = 'Failed to load printing devices (${response.statusCode})';
        debugPrint('❌ [PrintingDevice] $_error');
      }
    } catch (e) {
      _error = 'Network error loading printing devices: $e';
      debugPrint('❌ [PrintingDevice] $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── KDS auto-connect ────────────────────────────────────────────────────
  /// Connects to the primary KDS printer and persists the config.
  Future<void> _autoConnectKds() async {
    final kds = primaryKdsDevice;
    if (kds == null) {
      debugPrint('⚠️  [PrintingDevice] No KDS device in backend response');
      return;
    }

    // Use 'regular' (standard ESC/POS Printer class, port 9100) rather than
    // 'kds' (LFCPrinter, port 8008).  The physical KDS kitchen printer in this
    // restaurant is a regular Epson thermal receipt printer — it speaks ESC/POS
    // on port 9100, not the LFC display protocol on port 8008.  Using 'kds'
    // caused ERR_NOT_FOUND because LFCPrinter.connect() could never reach the
    // device.  Manual IP connect worked because it always uses 'regular'.
    // Kitchen tickets still print via the printKitchenTicket fallback path.
    const series =
        'TM_M30III'; // Generic fallback — works for any ESC/POS Epson over TCP
    final target = kds.tcpTarget;

    // Persist config BEFORE connecting — ensures _restoreKDSOnStartup() has
    // the correct target on next app launch even if the connection fails
    // (e.g. on startup when local LAN isn't fully ready yet).
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kds_printer_config',
        jsonEncode({
          'target': target,
          'series': series,
          'lang': 'MODEL_ANK',
          'printerType': 'regular',
        }),
      );
    } catch (_) {}

    final config = PrinterConfig(
      target: target,
      printerType: 'regular',
      series: series,
      lang: 'MODEL_ANK',
    );

    try {
      await _plugin.connectPrinter(config);
      _kdsConnected = true;
      debugPrint(
        '✅ [PrintingDevice] KDS auto-connected: ${kds.deviceName} @ ${kds.ipAddress}',
      );
    } catch (e) {
      _kdsConnected = false;
      // ERR_NOT_FOUND on startup = local LAN not ready yet.
      // Schedule background retries without blocking the caller.
      debugPrint(
        '⚠️  [PrintingDevice] KDS auto-connect attempt 1 failed, scheduling retry: $e',
      );
      _scheduleKdsRetry(config, kds.deviceName, attempt: 2);
    }

    notifyListeners();
  }

  /// Background retry for KDS connection.
  /// Attempt 2 fires after 5 s, attempt 3 after a further 10 s.
  void _scheduleKdsRetry(
    PrinterConfig config,
    String deviceName, {
    required int attempt,
  }) {
    final delaySeconds = attempt == 2 ? 5 : 10;
    Future.delayed(Duration(seconds: delaySeconds), () async {
      if (_kdsConnected) return; // already connected via another path
      try {
        await _plugin.connectPrinter(config);
        _kdsConnected = true;
        debugPrint(
          '✅ [PrintingDevice] KDS retry $attempt succeeded: $deviceName',
        );
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️  [PrintingDevice] KDS retry $attempt failed: $e');
        if (attempt < 3) {
          _scheduleKdsRetry(config, deviceName, attempt: attempt + 1);
        } else {
          debugPrint(
            '❌ [PrintingDevice] KDS auto-connect failed after all retries',
          );
          notifyListeners();
        }
      }
    });
  }

  // ── Cashier auto-connect ───────────────────────────────────────────────
  /// Connects to the primary cashier printer and persists the config under
  /// 'cashier_printer_config' in SharedPreferences.  Mirrors _autoConnectKds().
  Future<void> _autoConnectCashier() async {
    final cashier = primaryCashierDevice;
    if (cashier == null) {
      debugPrint('⚠️  [PrintingDevice] No cashier device in backend response');
      return;
    }

    const series = 'TM_M30III';
    final target = cashier.tcpTarget;

    // Persist config BEFORE connecting so restore-on-startup has the correct
    // target even if the initial connection attempt fails.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cashier_printer_config',
        jsonEncode({
          'target': target,
          'series': series,
          'lang': 'MODEL_ANK',
          'printerType': 'regular',
        }),
      );
    } catch (_) {}

    final config = PrinterConfig(
      target: target,
      printerType: 'regular',
      series: series,
      lang: 'MODEL_ANK',
    );

    try {
      await _plugin.connectPrinter(config);
      _cashierConnected = true;
      debugPrint(
        '✅ [PrintingDevice] Cashier auto-connected: ${cashier.deviceName} @ ${cashier.ipAddress}',
      );
    } catch (e) {
      _cashierConnected = false;
      debugPrint(
        '⚠️  [PrintingDevice] Cashier auto-connect attempt 1 failed, scheduling retry: $e',
      );
      _scheduleCashierRetry(config, cashier.deviceName, attempt: 2);
    }

    notifyListeners();
  }

  /// Background retry for cashier connection (mirrors _scheduleKdsRetry).
  void _scheduleCashierRetry(
    PrinterConfig config,
    String deviceName, {
    required int attempt,
  }) {
    final delaySeconds = attempt == 2 ? 5 : 10;
    Future.delayed(Duration(seconds: delaySeconds), () async {
      if (_cashierConnected) return;
      try {
        await _plugin.connectPrinter(config);
        _cashierConnected = true;
        debugPrint(
          '✅ [PrintingDevice] Cashier retry $attempt succeeded: $deviceName',
        );
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️  [PrintingDevice] Cashier retry $attempt failed: $e');
        if (attempt < 3) {
          _scheduleCashierRetry(config, deviceName, attempt: attempt + 1);
        } else {
          debugPrint(
            '❌ [PrintingDevice] Cashier auto-connect failed after all retries',
          );
          notifyListeners();
        }
      }
    });
  }

  // ── Warm-up helper ────────────────────────────────────────────────────
  /// Reads the cached printer config from SharedPreferences and calls
  /// connectPrinter once.  This sets the native `lastRegularTarget` that
  /// printReceipt / printKitchenTicket need for auto-reconnect.
  /// Best-effort only — failures are swallowed; the queue retry + native
  /// auto-reconnect remain the safety net.
  Future<void> _ensureNativeTargetSet(String prefsKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(prefsKey);
      if (configJson == null) return;
      final data = jsonDecode(configJson) as Map<String, dynamic>;
      final target = data['target'] as String? ?? '';
      if (target.isEmpty) return;
      await _plugin.connectPrinter(
        PrinterConfig(
          target: target,
          printerType: data['printerType'] as String? ?? 'regular',
          series: data['series'] as String? ?? 'TM_M30III',
          lang: data['lang'] as String? ?? 'MODEL_ANK',
        ),
      );
    } catch (_) {
      // Non-critical — native auto-reconnect or queue retry will handle it.
    }
  }

  //            auto-print bill after full payment
  /// called by homeProvider.PayBillPaymentServiceAPI immediately after a
  /// successful full payment.  Fire-and-forget — never throws; order flow
  /// must not be blocked by a print failure.
  ///
  /// [orderData] mirrors the structure used by _BillPrintDialog._printBill:
  ///   storeName, vatNumber, branchName, storeAddress, orderNumber,
  ///   invoiceNumber, orderType, tableName, customerName, date, time,
  ///   items (List<PrintJobItem>), netAmount, tax, taxRate, total,
  ///   paymentMethod, paymentStatus, discount.
  /// returns `true` when the print job was submitted successfully,
  /// `false` when it was skipped or failed.  Errors are caught internally;
  /// the caller is never blocked.
  Future<bool> autoPrintBill({
    required PrinterIntegrationProvider printerProvider,
    required Map<String, dynamic> orderData,
  }) async {
    // guard: need either a backend-loaded cashier device OR a cached config
    // from a previous session. If neither exists, fall back to the KDS printer
    // so single-printer setups (testing / small restaurants) can print bills
    // on the same physical printer that handles KDS tickets.
    // On fresh install / restart, fetchAndConnect() runs fire-and-forget and
    // may not have completed yet.  Wait briefly for the config to appear.
    var cashier = primaryCashierDevice;
    String warmUpKey = 'cashier_printer_config';

    if (cashier == null) {
      final prefs = await SharedPreferences.getInstance();
      var cached = prefs.getString('cashier_printer_config');
      if (cached == null) {
        // fetchAndConnect might still be in-flight — poll for up to 6 seconds
        for (int i = 0; i < 6; i++) {
          await Future.delayed(const Duration(seconds: 1));
          cashier = primaryCashierDevice;
          if (cashier != null) break;
          cached = prefs.getString('cashier_printer_config');
          if (cached != null) break;
        }
        if (cashier == null && cached == null) {
          // ── Fallback: use KDS printer for cashier bills too ──────────
          // Single-printer setups only have a KDS device in the backend.
          // Re-use its config so bills print on the same physical printer.
          final kdsCached = prefs.getString('kds_printer_config');
          if (kdsCached != null || primaryKdsDevice != null) {
            debugPrint(
              '🧾 [AutoPrint] No cashier device — falling back to KDS printer for bill',
            );
            warmUpKey = 'kds_printer_config';
          } else {
            debugPrint(
              '⚠️  [AutoPrint] No printer configured at all — skipping bill auto-print',
            );
            return false;
          }
        }
      }
      if (cached != null) {
        debugPrint(
          '🧾 [AutoPrint] Using cached cashier config for bill auto-print',
        );
      }
    }

    debugPrint(
      '🧾 [AutoPrint] Triggering cashier bill auto-print for order ${orderData['orderNumber']} (config: $warmUpKey)',
    );

    // Warm-up: ensure the native layer has lastRegularTarget set so that
    // the auto-reconnect inside printReceipt works on the very first print.
    await _ensureNativeTargetSet(warmUpKey);

    // ── queue the print ────────────────────────────────────────────────────
    // useQueue:true lets PrintQueueManager handle retry + back-off.  The queue
    // was fixed to remove jobs immediately after sendData succeeds (avoiding
    // the double-print bug) and the onPrintComplete handler no longer touches
    // the queue (avoiding the cross-job deletion bug).  Queue path is what
    // the working iOS build uses for auto-printing.
    try {
      final items = (orderData['items'] as List<PrintJobItem>?) ?? [];
      await printerProvider.printReceipt(
        storeName: orderData['storeName'] as String? ?? '',
        vatNumber: orderData['vatNumber'] as String?,
        branchName: orderData['branchName'] as String?,
        storeAddress: orderData['storeAddress'] as String?,
        orderNumber: orderData['orderNumber'] as String? ?? '',
        invoiceNumber: orderData['invoiceNumber'] as String?,
        orderType: orderData['orderType'] as String?,
        tableNumber: orderData['tableName'] as String?,
        customerName: orderData['customerName'] as String?,
        date: orderData['date'] as String?,
        time: orderData['time'] as String?,
        items: items,
        netAmount: (orderData['netAmount'] as num?)?.toDouble() ?? 0.0,
        tax: (orderData['tax'] as num?)?.toDouble() ?? 0.0,
        taxRate: (orderData['taxRate'] as num?)?.toDouble() ?? 15.0,
        total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: orderData['paymentMethod'] as String?,
        paymentStatus: orderData['paymentStatus'] as String?,
        qrCodeData: orderData['qrCodeData'] as String?,
        logoBase64: orderData['logoBase64'] as String?,
        discount: (orderData['discount'] as num?)?.toDouble() ?? 0.0,
        adjustmentAmount:
            (orderData['adjustmentAmount'] as num?)?.toDouble() ?? 0.0,
        totalPaidAmount:
            (orderData['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (orderData['paidAmount'] as num?)?.toDouble() ?? 0.0,
        tableCharge: (orderData['tableCharge'] as num?)?.toDouble() ?? 0.0,
        refundAmount: (orderData['refundAmount'] as num?)?.toDouble() ?? 0.0,
        taxBreakdown: (orderData['taxBreakdown'] as Map?)?.map(
          (k, v) => MapEntry(
            k as String,
            v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0),
          ),
        ),
        paymentDistribution: (orderData['paymentDistribution'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(),
        openDrawer: false,
        useQueue: true,
      );
      debugPrint('✅ [AutoPrint] Cashier bill queued successfully');
      return true;
    } catch (e) {
      debugPrint('⚠️  [AutoPrint] Cashier bill print failed (non-fatal): $e');
      return false;
    }
  }

  // ── Auto-print KDS after order creation ────────────────────────────────
  /// Called by AddNewOrderController immediately after a successful order POST.
  ///
  /// Returns `true` when the print job was submitted successfully,
  /// `false` when it was skipped or failed.
  Future<bool> autoPrintKDS({
    required PrinterIntegrationProvider printerProvider,
    required Map<String, dynamic> orderData,
  }) async {
    // Guard: need either a backend-loaded KDS device OR a cached config.
    // On fresh install / restart, fetchAndConnect() runs fire-and-forget and
    // may not have completed yet.  Wait briefly for the config to appear
    // before giving up — prevents silent skip on the first auto-print.
    var kds = primaryKdsDevice;
    if (kds == null) {
      final prefs = await SharedPreferences.getInstance();
      var cached = prefs.getString('kds_printer_config');
      if (cached == null) {
        // fetchAndConnect might still be in-flight — poll for up to 6 seconds
        for (int i = 0; i < 6; i++) {
          await Future.delayed(const Duration(seconds: 1));
          kds = primaryKdsDevice;
          if (kds != null) break;
          cached = prefs.getString('kds_printer_config');
          if (cached != null) break;
        }
        if (kds == null && cached == null) {
          debugPrint(
            '⚠️  [AutoPrint] No KDS device configured — skipping KDS print',
          );
          return false;
        }
      }
      if (cached != null) {
        debugPrint('🖨️  [AutoPrint] Using cached KDS config for auto-print');
      }
    }

    debugPrint(
      '🖨️  [AutoPrint] Triggering KDS auto-print for order ${orderData['orderNumber']}',
    );

    // Warm-up: ensure the native layer has lastRegularTarget set so that
    // the auto-reconnect inside printKitchenTicket / printReceipt works on
    // the very first print attempt.  connectPrinter is serialised on the
    // native printerLock so it cannot race with the subsequent print call.
    // If the connection fails, the queue's retry + native auto-reconnect
    // handle recovery — this is best-effort only.
    await _ensureNativeTargetSet('kds_printer_config');

    // ── Queue the print ────────────────────────────────────────────────────
    // useQueue:true lets PrintQueueManager handle retry + exponential back-off.
    // The queue tries printKDS first (LFC) → NOT_CONNECTED → falls back to
    // printKitchenTicket (regular ESC/POS), exactly like the direct path.
    // Queue path is what the working iOS build uses for auto-printing.
    try {
      final items = (orderData['items'] as List<PrintJobItem>?) ?? [];
      await printerProvider.printKitchenOrder(
        storeName: orderData['storeName'] as String? ?? '',
        orderNumber: orderData['orderNumber'] as String? ?? '',
        tableName: orderData['tableName'] as String? ?? '',
        orderType: orderData['orderType'] as String? ?? '',
        items: items,
        priority: orderData['priority'] as String? ?? 'normal',
        date: orderData['date'] as String?,
        customerName: orderData['customerName'] as String?,
        orderNotes: orderData['orderNotes'] as String?,
        useQueue: true, // Queue handles retry/back-off — matches iOS build
      );
      debugPrint('✅ [AutoPrint] KDS print queued successfully');
      return true;
    } catch (e) {
      debugPrint('⚠️  [AutoPrint] KDS print failed (non-fatal): $e');
      return false;
    }
  }
}
