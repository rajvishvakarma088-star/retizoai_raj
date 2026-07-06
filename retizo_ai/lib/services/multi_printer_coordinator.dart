import 'dart:async';
import 'package:flutter/foundation.dart';
import 'epson_printer_plugin.dart';
import 'printer_models.dart';

/// Multi-Printer Coordinator
///
/// Advanced feature for restaurant operations:
/// - Send orders to multiple kitchen stations simultaneously
/// - Route items to specific printers based on category (appetizers, mains, desserts)
/// - Coordinate print timing across multiple printers
/// - Track which station received which items
///
/// Example: Pizza goes to pizza station, salads to cold station, pasta to hot station
class MultiPrinterCoordinator {
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  // Printer stations configuration
  final Map<String, KitchenStation> _stations = {};

  // Active print jobs tracking
  final Map<String, MultiPrintJob> _activeJobs = {};

  // Results stream
  final _completionController = StreamController<MultiPrintResult>.broadcast();
  Stream<MultiPrintResult> get onMultiPrintComplete =>
      _completionController.stream;

  // Singleton
  static final MultiPrinterCoordinator _instance =
      MultiPrinterCoordinator._internal();
  factory MultiPrinterCoordinator() => _instance;
  MultiPrinterCoordinator._internal() {
    _setupListeners();
  }

  /// Setup print completion listeners
  void _setupListeners() {
    _plugin.onPrintComplete.listen((result) {
      _handlePrintComplete(result);
    });
  }

  /// Register a kitchen station
  ///
  /// Example:
  /// ```dart
  /// coordinator.registerStation(KitchenStation(
  ///   id: 'pizza',
  ///   name: 'Pizza Station',
  ///   printerConfig: PrinterConfig(target: 'TCP:192.168.1.100', printerType: 'kds'),
  ///   itemCategories: ['pizza', 'flatbread', 'calzone'],
  /// ));
  /// ```
  void registerStation(KitchenStation station) {
    _stations[station.id] = station;
    debugPrint(
      '📍 Registered station: ${station.name} (${station.itemCategories.join(', ')})',
    );
  }

  /// Unregister station
  void unregisterStation(String stationId) {
    _stations.remove(stationId);
    debugPrint('📍 Unregistered station: $stationId');
  }

  /// Send order to multiple stations based on item categories
  ///
  /// This is the killer feature! Automatically routes items to correct printers.
  Future<String> sendToStations(KDSPrintJob order) async {
    if (_stations.isEmpty) {
      throw PrinterException('No stations registered');
    }

    final jobId = _generateJobId();
    final stationJobs = <String, List<PrintJobItem>>{};

    // Route items to stations based on categories
    for (final item in order.items) {
      final category = _extractCategory(item.name);
      final station = _findStationForCategory(category);

      if (station != null) {
        stationJobs[station.id] ??= [];
        stationJobs[station.id]!.add(item);
      } else {
        // No specific station - send to default/all stations
        for (final station in _stations.values) {
          if (station.isDefault) {
            stationJobs[station.id] ??= [];
            stationJobs[station.id]!.add(item);
          }
        }
      }
    }

    if (stationJobs.isEmpty) {
      throw PrinterException('No stations available for these items');
    }

    // Create multi-print job
    final multiJob = MultiPrintJob(
      id: jobId,
      originalOrder: order,
      stationCount: stationJobs.length,
      startedAt: DateTime.now(),
    );
    _activeJobs[jobId] = multiJob;

    // Send to each station
    debugPrint(
      '📤 Sending order ${order.orderNumber} to ${stationJobs.length} stations',
    );

    for (final entry in stationJobs.entries) {
      final stationId = entry.key;
      final items = entry.value;
      final station = _stations[stationId]!;

      try {
        // Create station-specific order
        final stationOrder = KDSPrintJob(
          storeName: order.storeName,
          orderNumber: order.orderNumber,
          tableNumber: order.tableNumber,
          orderType: order.orderType,
          time: order.time,
          items: items,
          priority: order.priority,
          jobNumber: order.jobNumber,
        );

        // Connect to station printer if not connected
        if (!_plugin.isConnected(station.printerConfig.target)) {
          await _plugin.connectPrinter(station.printerConfig);
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // Connection settling
        }

        // Print to station
        await _plugin.printKDS(stationOrder);

        multiJob.stationResults[stationId] = StationPrintResult(
          stationId: stationId,
          stationName: station.name,
          itemCount: items.length,
          status: PrintJobStatus.printing,
        );

        debugPrint('  ✓ Sent ${items.length} items to ${station.name}');
      } catch (e) {
        multiJob.stationResults[stationId] = StationPrintResult(
          stationId: stationId,
          stationName: station.name,
          itemCount: items.length,
          status: PrintJobStatus.failed,
          error: e.toString(),
        );

        debugPrint('  ✗ Failed to send to ${station.name}: $e');
      }
    }

    return jobId;
  }

  /// Send same order to ALL stations (broadcast)
  Future<String> broadcastToAll(KDSPrintJob order) async {
    if (_stations.isEmpty) {
      throw PrinterException('No stations registered');
    }

    final jobId = _generateJobId();
    final multiJob = MultiPrintJob(
      id: jobId,
      originalOrder: order,
      stationCount: _stations.length,
      startedAt: DateTime.now(),
    );
    _activeJobs[jobId] = multiJob;

    debugPrint(
      '📡 Broadcasting order ${order.orderNumber} to ${_stations.length} stations',
    );

    for (final station in _stations.values) {
      try {
        if (!_plugin.isConnected(station.printerConfig.target)) {
          await _plugin.connectPrinter(station.printerConfig);
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await _plugin.printKDS(order);

        multiJob.stationResults[station.id] = StationPrintResult(
          stationId: station.id,
          stationName: station.name,
          itemCount: order.items.length,
          status: PrintJobStatus.printing,
        );
      } catch (e) {
        multiJob.stationResults[station.id] = StationPrintResult(
          stationId: station.id,
          stationName: station.name,
          itemCount: order.items.length,
          status: PrintJobStatus.failed,
          error: e.toString(),
        );
      }
    }

    return jobId;
  }

  /// Handle print completion from native side
  void _handlePrintComplete(PrintResult result) {
    // Find which multi-job this belongs to
    for (final job in _activeJobs.values) {
      for (final stationResult in job.stationResults.values) {
        if (stationResult.status == PrintJobStatus.printing) {
          // Update status
          if (result.success) {
            stationResult.status = PrintJobStatus.completed;
            stationResult.completedAt = DateTime.now();
          } else {
            stationResult.status = PrintJobStatus.failed;
            stationResult.error = result.error;
          }

          // Check if all stations completed
          if (job.isComplete) {
            job.completedAt = DateTime.now();

            final multiResult = MultiPrintResult(
              jobId: job.id,
              success: job.isSuccess,
              stationCount: job.stationCount,
              successCount: job.successCount,
              failureCount: job.failureCount,
              results: job.stationResults.values.toList(),
              totalTime: job.completedAt!.difference(job.startedAt),
            );

            _completionController.add(multiResult);
            _activeJobs.remove(job.id);

            debugPrint(
              '✅ Multi-print job ${job.id} complete: '
              '${job.successCount}/${job.stationCount} stations succeeded',
            );
          }

          return;
        }
      }
    }
  }

  /// Find station for item category
  KitchenStation? _findStationForCategory(String category) {
    for (final station in _stations.values) {
      if (station.itemCategories.contains(category.toLowerCase())) {
        return station;
      }
    }
    return null;
  }

  /// Extract category from item name (simple keyword matching)
  /// In production, this would use your menu database
  String _extractCategory(String itemName) {
    final lower = itemName.toLowerCase();

    // Simple keyword matching - enhance with your actual menu data
    if (lower.contains('pizza') || lower.contains('flatbread')) return 'pizza';
    if (lower.contains('salad') || lower.contains('cold')) return 'cold';
    if (lower.contains('pasta') || lower.contains('risotto')) return 'pasta';
    if (lower.contains('grill') || lower.contains('steak')) return 'grill';
    if (lower.contains('dessert') || lower.contains('cake')) return 'dessert';
    if (lower.contains('burger') || lower.contains('sandwich')) return 'burger';

    return 'general';
  }

  /// Get all registered stations
  List<KitchenStation> getStations() {
    return _stations.values.toList();
  }

  /// Get active jobs
  List<MultiPrintJob> getActiveJobs() {
    return _activeJobs.values.toList();
  }

  /// Generate job ID
  String _generateJobId() {
    return 'MULTI_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _completionController.close();
  }
}

/// Kitchen station configuration
class KitchenStation {
  final String id;
  final String name;
  final PrinterConfig printerConfig;
  final List<String> itemCategories; // Categories this station handles
  final bool isDefault; // Fallback station for uncategorized items

  KitchenStation({
    required this.id,
    required this.name,
    required this.printerConfig,
    required this.itemCategories,
    this.isDefault = false,
  });
}

/// Multi-print job tracking
class MultiPrintJob {
  final String id;
  final KDSPrintJob originalOrder;
  final int stationCount;
  final DateTime startedAt;
  DateTime? completedAt;

  final Map<String, StationPrintResult> stationResults = {};

  MultiPrintJob({
    required this.id,
    required this.originalOrder,
    required this.stationCount,
    required this.startedAt,
  });

  bool get isComplete => stationResults.values.every(
    (r) =>
        r.status == PrintJobStatus.completed ||
        r.status == PrintJobStatus.failed,
  );

  bool get isSuccess =>
      stationResults.values.every((r) => r.status == PrintJobStatus.completed);

  int get successCount => stationResults.values
      .where((r) => r.status == PrintJobStatus.completed)
      .length;

  int get failureCount => stationResults.values
      .where((r) => r.status == PrintJobStatus.failed)
      .length;
}

/// Station print result
class StationPrintResult {
  final String stationId;
  final String stationName;
  final int itemCount;
  PrintJobStatus status;
  DateTime? completedAt;
  String? error;

  StationPrintResult({
    required this.stationId,
    required this.stationName,
    required this.itemCount,
    required this.status,
    this.completedAt,
    this.error,
  });
}

/// Multi-print result
class MultiPrintResult {
  final String jobId;
  final bool success;
  final int stationCount;
  final int successCount;
  final int failureCount;
  final List<StationPrintResult> results;
  final Duration totalTime;

  MultiPrintResult({
    required this.jobId,
    required this.success,
    required this.stationCount,
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.totalTime,
  });

  @override
  String toString() =>
      'MultiPrintResult($successCount/$stationCount succeeded in ${totalTime.inMilliseconds}ms)';
}

/// Status enum from print_queue_manager
enum PrintJobStatus {
  pending,
  printing,
  completed,
  failed,
  cancelled,
  abandoned,
}
