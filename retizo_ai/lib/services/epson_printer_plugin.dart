import 'dart:async';
import 'package:flutter/services.dart';
import 'printer_models.dart';

/// Main Epson Printer Plugin
///
/// Professional-grade interface to Epson ePOS SDK
/// Provides complete printer management with advanced features
class EpsonPrinterPlugin {
  static const MethodChannel _channel = MethodChannel(
    'com.culai.epson_printer',
  );

  // Singleton pattern
  static final EpsonPrinterPlugin _instance = EpsonPrinterPlugin._internal();
  factory EpsonPrinterPlugin() => _instance;
  EpsonPrinterPlugin._internal() {
    _setupMethodCallHandler();
  }

  // Stream controllers for events
  final _discoveryController = StreamController<PrinterDevice>.broadcast();
  final _printCompleteController = StreamController<PrintResult>.broadcast();
  final _permissionResultController =
      StreamController<Map<String, bool>>.broadcast();

  // Public streams
  Stream<PrinterDevice> get onPrinterDiscovered => _discoveryController.stream;
  Stream<PrintResult> get onPrintComplete => _printCompleteController.stream;
  Stream<Map<String, bool>> get onPermissionResult =>
      _permissionResultController.stream;

  // Current connection tracking
  final Map<String, PrinterConfig> _connectedPrinters = {};

  /// Setup method call handler for callbacks from native side
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPrinterDiscovered':
          final device = PrinterDevice.fromMap(call.arguments);
          _discoveryController.add(device);
          break;

        case 'onDiscoveryComplete':
          // Discovery finished - can notify UI if needed
          break;

        case 'onPrintComplete':
          final result = PrintResult.fromMap(call.arguments);
          _printCompleteController.add(result);
          break;

        case 'onPermissionResult':
          final results = Map<String, bool>.from(call.arguments);
          _permissionResultController.add(results);
          break;
      }
    });
  }

  /// Request runtime permissions (Android 12+)
  Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } catch (e) {
      throw PrinterException('Failed to request permissions: $e');
    }
  }

  /// Discover printers
  ///
  /// [portType] - "all", "tcp", "bluetooth", or "usb"
  /// [timeout] - Discovery timeout in milliseconds (default: 10000)
  ///
  /// Returns list of discovered printers via [onPrinterDiscovered] stream
  Future<void> discoverPrinters({
    String portType = 'all',
    int timeout = 10000,
  }) async {
    try {
      await _channel.invokeMethod('discoverPrinters', {
        'portType': portType,
        'timeout': timeout,
      });
    } catch (e) {
      throw PrinterException('Discovery failed: $e');
    }
  }

  /// Stop ongoing discovery
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } catch (e) {
      throw PrinterException('Stop discovery failed: $e');
    }
  }

  /// Connect to printer
  ///
  /// [config] - Printer configuration with target, type, series, language
  ///
  /// Returns connection status
  Future<Map<String, dynamic>> connectPrinter(PrinterConfig config) async {
    try {
      final result = await _channel.invokeMethod(
        'connectPrinter',
        config.toMap(),
      );

      // Track connected printer
      _connectedPrinters[config.target] = config;

      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw PrinterException('Connection failed: $e');
    }
  }

  /// Disconnect from printer
  Future<Map<String, dynamic>> disconnectPrinter(String printerType) async {
    try {
      final result = await _channel.invokeMethod('disconnectPrinter', {
        'printerType': printerType,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw PrinterException('Disconnect failed: $e');
    }
  }

  /// Print receipt/bill
  ///
  /// [job] - Print job data with all receipt information
  ///
  /// Result is delivered via [onPrintComplete] stream
  Future<void> printReceipt(PrintJob job) async {
    try {
      await _channel.invokeMethod('printReceipt', {'data': job.toMap()});
    } catch (e) {
      throw PrinterException('Print receipt failed: $e');
    }
  }

  /// Print KDS kitchen order
  ///
  /// [job] - KDS print job with order information
  ///
  /// Result is delivered via [onPrintComplete] stream
  Future<void> printKDS(KDSPrintJob job) async {
    try {
      await _channel.invokeMethod('printKDS', {
        'data': job.toMap(),
        'jobNumber': job.jobNumber,
      });
    } catch (e) {
      throw PrinterException('Print KDS failed: $e');
    }
  }

  /// Print kitchen ticket on regular thermal printer (ESC/POS, KDS-style format).
  ///
  /// Fallback for when no dedicated LFC/KDS printer is configured.
  /// Uses the connected regular printer with the same visual layout as [printKDS].
  Future<void> printKitchenTicket(KDSPrintJob job) async {
    try {
      await _channel.invokeMethod('printKitchenTicket', {'data': job.toMap()});
    } catch (e) {
      throw PrinterException('Print kitchen ticket failed: $e');
    }
  }

  /// Test print
  ///
  /// Sends a simple test page to verify printer connection
  Future<void> testPrint(String printerType) async {
    try {
      await _channel.invokeMethod('testPrint', {'printerType': printerType});
    } catch (e) {
      throw PrinterException('Test print failed: $e');
    }
  }

  /// Get printer status
  ///
  /// Returns current status of connected printer
  Future<PrinterStatus> getPrinterStatus(String printerType) async {
    try {
      final result = await _channel.invokeMethod('getPrinterStatus', {
        'printerType': printerType,
      });
      return PrinterStatus.fromMap(result);
    } catch (e) {
      throw PrinterException('Get status failed: $e');
    }
  }

  /// Get list of supported printers
  Future<List<PrinterModel>> getSupportedPrinters() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getSupportedPrinters',
      );
      return result.map((item) => PrinterModel.fromMap(item)).toList();
    } catch (e) {
      throw PrinterException('Get supported printers failed: $e');
    }
  }

  /// Get SDK version information
  Future<Map<String, dynamic>> getVersion() async {
    try {
      final result = await _channel.invokeMethod('getVersion');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw PrinterException('Get version failed: $e');
    }
  }

  /// Check if printer is connected
  bool isConnected(String target) {
    return _connectedPrinters.containsKey(target);
  }

  /// Get connected printers
  List<PrinterConfig> getConnectedPrinters() {
    return _connectedPrinters.values.toList();
  }

  /// Dispose plugin resources
  void dispose() {
    _discoveryController.close();
    _printCompleteController.close();
    _permissionResultController.close();
  }
}

/// Custom exception for printer errors
class PrinterException implements Exception {
  final String message;
  PrinterException(this.message);

  @override
  String toString() => 'PrinterException: $message';
}
