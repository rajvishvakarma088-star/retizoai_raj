import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../services/epson_printer_plugin.dart';
import '../../../../services/printer_models.dart';
import '../../../../services/print_queue_manager.dart';
import '../../../../services/multi_printer_coordinator.dart';
import '../../../../services/auto_reconnect_handler.dart';

/// Printer Integration Provider for KDS
///
/// Bridges the printer services with the KDS workflow.
/// This is what makes auto-printing and queue management easy to use.
class PrinterIntegrationProvider with ChangeNotifier {
  // Printer services
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();
  final PrintQueueManager _queueManager = PrintQueueManager();
  final MultiPrinterCoordinator _coordinator = MultiPrinterCoordinator();
  final AutoReconnectHandler _reconnectHandler = AutoReconnectHandler();

  // Settings (default manual mode for testing)
  bool autoPrintEnabled = true; // Default: auto-print enabled
  bool useQueueForReliability = true;
  bool multiStationEnabled = false;
  bool _disposed = false;

  // Status
  bool isPrinterConnected = false;
  String? lastError;
  int pendingPrintJobs = 0;

  // Enhanced status indicators (professional RMS/KDS app features)
  DateTime? lastPrintTime;
  int totalPrintJobs = 0;
  int successfulPrints = 0;
  int failedPrints = 0;
  String connectionQuality =
      'Unknown'; // 'Excellent', 'Good', 'Fair', 'Poor', 'Disconnected'
  String printerModel = 'Not Connected';
  bool isPrinting = false;

  PrinterIntegrationProvider() {
    _setupListeners();
    // Single entry-point: restores all saved connections SEQUENTIALLY to avoid
    // concurrent connect/disconnect races on the single native regularPrinter
    // slot.  Previously these three were called in parallel which caused random
    // connection failures on startup.
    _initializeConnectionsSequentially();
  }

  /// Restores saved printer connections one-at-a-time so each native
  /// connectRegularPrinter() completes before the next one starts.
  Future<void> _initializeConnectionsSequentially() async {
    await _restoreConnectionState();
    await _restoreKDSOnStartup();
    await _restoreCashierOnStartup();
  }

  /// Setup event listeners
  void _setupListeners() {
    // Listen to print completion
    _plugin.onPrintComplete.listen((result) {
      isPrinting = false;
      totalPrintJobs++;

      if (result.success) {
        lastPrintTime = DateTime.now();
        successfulPrints++;
        lastError = null;
        connectionQuality = 'Excellent';
      } else {
        lastError = result.error;
        failedPrints++;
        connectionQuality = 'Poor';
      }
      notifyListeners();
    });

    // Periodically update queue status
    _updateQueueStatusPeriodically();
  }

  /// Restore connection state from SharedPreferences
  Future<void> _restoreConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if printer was previously connected
      final wasConnected = prefs.getBool('printer_was_connected') ?? false;
      if (!wasConnected) {
        debugPrint('📡 No previous printer connection found');
        return;
      }

      // Load saved printer configuration
      final selectedPrinterTarget = prefs.getString('selected_printer');
      if (selectedPrinterTarget == null) {
        debugPrint('📡 No selected printer found in preferences');
        return;
      }

      // Load the printer details from saved printers list
      final printersJson = prefs.getStringList('saved_printers') ?? [];
      if (printersJson.isEmpty) {
        debugPrint('📡 No saved printers found');
        return;
      }

      // Find the selected printer configuration
      Map<String, dynamic>? selectedConfig;
      for (final json in printersJson) {
        try {
          final printerData = jsonDecode(json) as Map<String, dynamic>;
          if (printerData['target'] == selectedPrinterTarget) {
            selectedConfig = printerData;
            break;
          }
        } catch (e) {
          debugPrint('Error parsing printer JSON: $e');
        }
      }

      if (selectedConfig == null) {
        debugPrint('📡 Selected printer configuration not found');
        return;
      }

      // Attempt to reconnect
      debugPrint(
        '📡 Attempting to restore printer connection to ${selectedConfig['name']}...',
      );

      final config = PrinterConfig(
        target: selectedConfig['target'] ?? selectedPrinterTarget,
        printerType: 'regular',
        series: selectedConfig['series'] ?? 'TM_T88VII',
        lang: 'MODEL_ANK',
      );

      try {
        await _plugin.connectPrinter(config);

        // Update connection status
        isPrinterConnected = true;
        printerModel = config.series;
        connectionQuality = 'Excellent';
        lastError = null;

        // Save the restored connection state
        await _saveConnectionState(true);

        notifyListeners();
        debugPrint('✅ Printer connection restored successfully');
      } catch (e) {
        debugPrint('⚠️  Failed to restore printer connection: $e');
        // Don't update isPrinterConnected, let it remain false
        // NEVER save false — we always want to retry on next startup.
        // Saving false here was a root cause of "restart doesn't fix it"
        // because _restoreConnectionState checked wasConnected and skipped.
      }

      // KDS restore is handled separately by _restoreKDSOnStartup() in
      // _initializeConnectionsSequentially — don't duplicate it here.
    } catch (e) {
      debugPrint('❌ Error restoring connection state: $e');
    }
  }

  /// Called independently on startup to restore KDS regardless of regular printer state
  Future<void> _restoreKDSOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _restoreKDSConnectionState(prefs);
    } catch (e) {
      debugPrint('⚠️  KDS startup restore error: $e');
    }
  }

  /// Called independently on startup to restore cashier printer from saved config.
  /// Uses 'cashier_printer_config' key written by PrintingDeviceProvider._autoConnectCashier().
  Future<void> _restoreCashierOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashierConfigJson = prefs.getString('cashier_printer_config');
      if (cashierConfigJson == null) return;

      final cashierData = jsonDecode(cashierConfigJson) as Map<String, dynamic>;
      final cashierConfig = PrinterConfig(
        target: cashierData['target'] as String? ?? '',
        printerType: cashierData['printerType'] as String? ?? 'regular',
        series: cashierData['series'] as String? ?? 'TM_M30III',
        lang: cashierData['lang'] as String? ?? 'MODEL_ANK',
      );

      if (cashierConfig.target.isEmpty) return;

      debugPrint(
        '📡 Restoring cashier connection to ${cashierConfig.target}...',
      );
      await _plugin.connectPrinter(cashierConfig);
      isPrinterConnected = true;
      printerModel = cashierConfig.series;
      connectionQuality = 'Excellent';
      lastError = null;
      await _saveConnectionState(true);
      notifyListeners();
      debugPrint('✅ Cashier connection restored to ${cashierConfig.target}');
    } catch (e) {
      debugPrint('⚠️  Failed to restore cashier connection: $e');
      // Non-critical — user can reconnect via Settings
    }
  }

  /// Restore KDS connection from saved config
  Future<void> _restoreKDSConnectionState(SharedPreferences prefs) async {
    try {
      final kdsConfigJson = prefs.getString('kds_printer_config');
      if (kdsConfigJson == null) return;

      final kdsData = jsonDecode(kdsConfigJson) as Map<String, dynamic>;
      final kdsConfig = PrinterConfig(
        target: kdsData['target'] ?? '',
        // Read printerType from the saved config (defaults to 'regular' so the
        // standard ESC/POS Printer class on port 9100 is used, matching the
        // behaviour of Quick Connect - Manual IP).
        printerType: kdsData['printerType'] as String? ?? 'regular',
        series: kdsData['series'] as String? ?? 'TM_M30III',
        lang: kdsData['lang'] as String? ?? 'MODEL_ANK',
      );

      if (kdsConfig.target.isEmpty) return;

      debugPrint('📡 Restoring KDS connection to ${kdsConfig.target}...');
      await _plugin.connectPrinter(kdsConfig);
      debugPrint('✅ KDS connection restored to ${kdsConfig.target}');
    } catch (e) {
      debugPrint('⚠️  Failed to restore KDS connection: $e');
      // Not critical — user can reconnect from KDS settings
    }
  }

  /// Save connection state to SharedPreferences
  Future<void> _saveConnectionState(bool isConnected) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('printer_was_connected', isConnected);
      debugPrint('💾 Saved connection state: $isConnected');
    } catch (e) {
      debugPrint('Error saving connection state: $e');
    }
  }

  /// Periodically check queue status
  void _updateQueueStatusPeriodically() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (_disposed) return false; // Stop loop when provider is disposed
      try {
        final status = _queueManager.getStatus();
        if (pendingPrintJobs != status.queueLength) {
          pendingPrintJobs = status.queueLength;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Queue status update error: $e');
      }
      return !_disposed; // Stop loop when provider is disposed
    });
  }

  /// Initialize printers (call after login or on app start)
  Future<void> initializePrinters() async {
    try {
      // Connect to default printer
      final config = PrinterConfig(
        target: 'TCP:192.168.1.100',
        printerType: 'regular',
        series: 'TM_T88VII',
        lang: 'MODEL_ANK',
      );

      await _plugin.connectPrinter(config);

      // Enable auto-reconnect
      await _reconnectHandler.manageConnection(config.target, config);

      isPrinterConnected = true;
      printerModel = config.series;
      connectionQuality = 'Excellent';
      lastError = null;
      notifyListeners();

      debugPrint('✅ Printer initialized successfully');
    } catch (e) {
      lastError = 'Failed to initialize printer: $e';
      isPrinterConnected = false;
      printerModel = 'Not Connected';
      connectionQuality = 'Disconnected';
      notifyListeners();
      debugPrint('❌ Printer initialization failed: $e');
    }
  }

  /// Print kitchen order
  Future<void> printKitchenOrder({
    required String storeName,
    required String orderNumber,
    required String tableName,
    required String orderType,
    required List<PrintJobItem> items,
    String? priority,
    int? jobNumber,
    String? date,
    String? customerName,
    String? orderNotes,
    // When false, bypasses queue so the caller receives immediate error feedback.
    // Pass false for user-triggered manual prints; leave true for auto/background prints.
    bool useQueue = true,
  }) async {
    try {
      isPrinting = true;
      notifyListeners();

      final kdsJob = KDSPrintJob(
        storeName: storeName,
        orderNumber: orderNumber,
        tableNumber: tableName,
        orderType: orderType,
        time: DateTime.now().toString().substring(11, 16),
        date: date,
        customerName: customerName,
        items: items,
        priority: priority,
        jobNumber: jobNumber ?? DateTime.now().millisecondsSinceEpoch % 10000,
        orderNotes: orderNotes,
      );

      if (multiStationEnabled) {
        // Use multi-station coordinator
        await _coordinator.sendToStations(kdsJob);
      } else if (useQueueForReliability && useQueue) {
        // Use queue for reliability (auto/background prints)
        await _queueManager.queueKDS(kdsJob);
      } else {
        // Direct print — immediate error propagation for user-triggered prints.
        // If dedicated KDS printer is not connected, fall back to regular printer.
        try {
          await _plugin.printKDS(kdsJob);
        } catch (kdsErr) {
          if (kdsErr.toString().contains('NOT_CONNECTED')) {
            debugPrint(
              '🔄 KDS printer unavailable — falling back to kitchen ticket on regular printer',
            );
            await _plugin.printKitchenTicket(kdsJob);
          } else {
            rethrow;
          }
        }
      }

      debugPrint('🖨️  KDS print job queued for order $orderNumber');
    } catch (e) {
      failedPrints++;
      lastError = 'Failed to print KDS order: $e';
      debugPrint('❌ KDS print failed: $e');
      rethrow;
    } finally {
      isPrinting = false;
      notifyListeners();
    }
  }

  /// Print receipt
  Future<void> printReceipt({
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? vatNumber,
    String? branchName,
    required String orderNumber,
    String? invoiceNumber,
    required List<PrintJobItem> items,
    required double netAmount,
    required double tax,
    double? taxRate,
    required double total,
    String? tableNumber,
    String? orderType,
    String? customerName,
    String? paymentMethod,
    String? paymentStatus,
    String? qrCodeData,
    String? logoBase64,
    double? discount,
    double? adjustmentAmount,
    double? totalPaidAmount,
    double? paidAmount,
    double? tableCharge,
    double? refundAmount,
    String? date,
    String? time,
    Map<String, double>? taxBreakdown,
    List<Map<String, dynamic>>? paymentDistribution,
    bool openDrawer = true,
    bool useQueue = true,
  }) async {
    try {
      isPrinting = true;
      notifyListeners();

      // Use provided date/time or fallback to current date/time
      final now = DateTime.now();
      final printDate =
          date ??
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final printTime =
          time ??
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final printJob = PrintJob(
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
        vatNumber: vatNumber,
        branchName: branchName,
        orderNumber: orderNumber,
        invoiceNumber: invoiceNumber,
        tableNumber: tableNumber,
        orderType: orderType,
        date: printDate,
        time: printTime,
        customerName: customerName,
        items: items,
        netAmount: netAmount,
        tax: tax,
        taxRate: taxRate ?? 15.0,
        discount: discount ?? 0.0,
        adjustmentAmount: adjustmentAmount ?? 0.0,
        total: total,
        totalPaidAmount: totalPaidAmount ?? 0.0,
        paidAmount: paidAmount ?? 0.0,
        tableCharge: tableCharge ?? 0.0,
        refundAmount: refundAmount ?? 0.0,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        qrCodeData: qrCodeData,
        logoBase64: logoBase64,
        taxBreakdown: taxBreakdown,
        paymentDistribution: paymentDistribution,
        openDrawer: openDrawer,
      );

      if (useQueueForReliability && useQueue) {
        await _queueManager.queueReceipt(printJob);
      } else {
        await _plugin.printReceipt(printJob);
      }

      debugPrint('🧾 Receipt queued for order $orderNumber');
    } catch (e) {
      failedPrints++;
      lastError = 'Failed to print receipt: $e';
      debugPrint('❌ Receipt print failed: $e');
      rethrow;
    } finally {
      isPrinting = false;
      notifyListeners();
    }
  }

  /// Check printer status
  Future<PrinterStatus> checkPrinterStatus() async {
    try {
      final status = await _plugin.getPrinterStatus('regular');
      isPrinterConnected = status.isOnline;
      notifyListeners();
      return status;
    } catch (e) {
      lastError = 'Failed to check status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update connection status (called from Settings after successful connection)
  void updateConnectionStatus({
    required bool isConnected,
    String? printerModel,
    String? connectionQuality,
  }) {
    isPrinterConnected = isConnected;
    if (printerModel != null) this.printerModel = printerModel;
    if (connectionQuality != null) this.connectionQuality = connectionQuality;
    if (!isConnected) {
      this.printerModel = 'Not Connected';
      this.connectionQuality = 'Disconnected';
    }

    // Persist the connection state
    _saveConnectionState(isConnected);

    notifyListeners();
    debugPrint('📡 Connection status updated: $isConnected');
  }

  /// Test print
  Future<void> testPrint() async {
    try {
      await _plugin.printReceipt(
        PrintJob(
          storeName: 'Test Restaurant',
          orderNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now().toString().substring(0, 10),
          time: DateTime.now().toString().substring(11, 16),
          items: [PrintJobItem(name: 'Test Item', quantity: 1, price: 10.0)],
          netAmount: 10.0,
          tax: 1.5,
          taxRate: 15.0,
          total: 11.5,
        ),
      );

      debugPrint('🧪 Test print sent');
    } catch (e) {
      lastError = 'Test print failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get queue status
  QueueStatus getQueueStatus() {
    return _queueManager.getStatus();
  }

  /// Get printer connection health status
  String getConnectionHealth() {
    if (!isPrinterConnected) return 'Disconnected';

    if (failedPrints == 0 && successfulPrints > 0) return 'Excellent';

    final successRate = totalPrintJobs > 0
        ? (successfulPrints / totalPrintJobs) * 100
        : 0;

    if (successRate >= 95) return 'Excellent';
    if (successRate >= 80) return 'Good';
    if (successRate >= 60) return 'Fair';
    return 'Poor';
  }

  /// Get last print time formatted
  String getLastPrintTimeFormatted() {
    if (lastPrintTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastPrintTime!);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get printer statistics for display
  Map<String, dynamic> getPrinterStats() {
    return {
      'connected': isPrinterConnected,
      'model': printerModel,
      'connectionQuality': getConnectionHealth(),
      'isPrinting': isPrinting,
      'totalJobs': totalPrintJobs,
      'successfulPrints': successfulPrints,
      'failedPrints': failedPrints,
      'pendingJobs': pendingPrintJobs,
      'lastPrint': getLastPrintTimeFormatted(),
      'successRate': totalPrintJobs > 0
          ? '${((successfulPrints / totalPrintJobs) * 100).toStringAsFixed(1)}%'
          : 'N/A',
    };
  }

  /// Save settings (TODO: implement SharedPreferences)
  Future<void> saveSettings() async {
    // TODO: Save to SharedPreferences
    debugPrint(
      'Settings saved: autoPrint=$autoPrintEnabled, queue=$useQueueForReliability, multiStation=$multiStationEnabled',
    );
    notifyListeners();
  }

  /// Load settings (TODO: implement SharedPreferences)
  Future<void> loadSettings() async {
    // TODO: Load from SharedPreferences
    notifyListeners();
  }

  // ── Force reconnect (called from UI Reconnect button) ────────────────
  /// Reads the saved printer configuration from SharedPreferences and
  /// reconnects.  Returns true on success.  This is the user-facing
  /// safety-net when auto-connect has failed.
  Future<bool> reconnectPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try cashier config first (most common), then KDS, then legacy key
      String? configJson = prefs.getString('cashier_printer_config');
      configJson ??= prefs.getString('kds_printer_config');

      PrinterConfig config;
      if (configJson != null) {
        final data = jsonDecode(configJson) as Map<String, dynamic>;
        config = PrinterConfig(
          target: data['target'] as String? ?? '',
          printerType: data['printerType'] as String? ?? 'regular',
          series: data['series'] as String? ?? 'TM_M30III',
          lang: data['lang'] as String? ?? 'MODEL_ANK',
        );
      } else {
        // Fallback: legacy selected_printer key
        final target = prefs.getString('selected_printer');
        if (target == null || target.isEmpty) {
          lastError = 'No printer configured — go to Settings first';
          notifyListeners();
          return false;
        }
        config = PrinterConfig(
          target: target,
          printerType: 'regular',
          series: 'TM_M30III',
          lang: 'MODEL_ANK',
        );
      }

      if (config.target.isEmpty) {
        lastError = 'No printer target configured';
        notifyListeners();
        return false;
      }

      debugPrint('🔄 [Reconnect] Connecting to ${config.target}...');
      await _plugin.connectPrinter(config);

      isPrinterConnected = true;
      printerModel = config.series;
      connectionQuality = 'Excellent';
      lastError = null;
      await _saveConnectionState(true);
      notifyListeners();
      debugPrint('✅ [Reconnect] Connected to ${config.target}');
      return true;
    } catch (e) {
      lastError = 'Reconnect failed: $e';
      isPrinterConnected = false;
      connectionQuality = 'Disconnected';
      notifyListeners();
      debugPrint('❌ [Reconnect] Failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
