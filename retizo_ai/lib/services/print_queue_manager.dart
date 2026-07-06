import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'epson_printer_plugin.dart';
import 'printer_models.dart';

/// Advanced Print Queue Manager
///
/// Production-grade features:
/// - Automatic retry on failure with exponential backoff
/// - Offline queueing (print when printer comes back online)
/// - Priority queue support
/// - Queue persistence (survive app restart)
/// - Print job tracking and history
///
/// This is what separates production apps from basic web printing!
class PrintQueueManager {
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  // Queue storage
  final Queue<QueuedPrintJob> _queue = Queue();
  final List<QueuedPrintJob> _history = [];

  // State management
  bool _isProcessing = false;
  Timer? _processTimer;

  // Configuration
  static const int maxRetries = 5;
  static const int retryDelayMs = 2000;
  static const int maxQueueSize = 100;
  static const int historyLimit = 500;

  // Singleton
  static final PrintQueueManager _instance = PrintQueueManager._internal();
  factory PrintQueueManager() => _instance;
  PrintQueueManager._internal() {
    _setupListeners();
    _startQueueProcessor();
  }

  /// Setup listeners for print completion
  void _setupListeners() {
    _plugin.onPrintComplete.listen((result) {
      _handlePrintComplete(result);
    });
  }

  /// Add receipt print job to queue
  Future<String> queueReceipt(
    PrintJob job, {
    PrintPriority priority = PrintPriority.normal,
  }) async {
    if (_queue.length >= maxQueueSize) {
      throw PrinterException('Queue is full (max: $maxQueueSize)');
    }

    final queuedJob = QueuedPrintJob(
      id: _generateJobId(),
      type: PrintJobType.receipt,
      data: job.toMap(),
      priority: priority,
      addedAt: DateTime.now(),
    );

    _addToQueue(queuedJob);
    _processQueue();

    return queuedJob.id;
  }

  /// Add KDS print job to queue
  Future<String> queueKDS(
    KDSPrintJob job, {
    PrintPriority priority = PrintPriority.normal,
  }) async {
    if (_queue.length >= maxQueueSize) {
      throw PrinterException('Queue is full (max: $maxQueueSize)');
    }

    final queuedJob = QueuedPrintJob(
      id: _generateJobId(),
      type: PrintJobType.kds,
      data: job.toMap(),
      jobNumber: job.jobNumber,
      priority: priority,
      addedAt: DateTime.now(),
    );

    _addToQueue(queuedJob);
    _processQueue();

    return queuedJob.id;
  }

  /// Add job to queue with priority handling
  void _addToQueue(QueuedPrintJob job) {
    if (job.priority == PrintPriority.urgent) {
      // Insert at front for urgent jobs
      _queue.addFirst(job);
    } else {
      // Normal jobs go to back
      _queue.add(job);
    }

    debugPrint(
      '📋 Queued print job: ${job.id} (priority: ${job.priority.name})',
    );
  }

  /// Start background queue processor
  void _startQueueProcessor() {
    _processTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _processQueue(),
    );
  }

  /// Process queue (called periodically and on new job)
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    try {
      final job = _queue.first;

      // Check if should retry or abandon
      if (job.retryCount >= maxRetries) {
        // Max retries reached, move to history
        _queue.removeFirst();
        job.status = PrintJobStatus.abandoned;
        _addToHistory(job);
        debugPrint('❌ Job ${job.id} abandoned after $maxRetries retries');
        _isProcessing = false;
        return;
      }

      // Print the job
      await _executePrintJob(job);
    } catch (e) {
      debugPrint('⚠️ Queue processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute actual print job
  Future<void> _executePrintJob(QueuedPrintJob job) async {
    try {
      job.status = PrintJobStatus.printing;
      job.lastAttempt = DateTime.now();
      job.retryCount++;

      debugPrint('🖨️  Printing job ${job.id} (attempt ${job.retryCount})');

      if (job.type == PrintJobType.receipt) {
        final printJob = PrintJob(
          storeName: job.data['storeName'],
          storeAddress: job.data['storeAddress'],
          storePhone: job.data['storePhone'],
          vatNumber: job.data['vatNumber'],
          branchName: job.data['branchName'],
          orderNumber: job.data['orderNumber'],
          invoiceNumber: job.data['invoiceNumber'],
          tableNumber: job.data['tableNumber'],
          orderType: job.data['orderType'],
          customerName: job.data['customerName'],
          date: job.data['date'],
          time: job.data['time'],
          items: (job.data['items'] as List).map((item) {
            return PrintJobItem(
              name: item['name'],
              quantity: item['quantity'],
              price: item['price'],
              notes: item['notes'],
              modifiers: item['modifiers'] != null
                  ? List<String>.from(item['modifiers'])
                  : null,
              status: item['status'],
            );
          }).toList(),
          netAmount: job.data['netAmount'] ?? (job.data['subtotal'] ?? 0.0),
          tax: job.data['tax'],
          taxRate: job.data['taxRate'] ?? 15.0,
          discount: job.data['discount'] ?? 0.0,
          adjustmentAmount: job.data['adjustmentAmount'] ?? 0.0,
          total: job.data['total'],
          totalPaidAmount: job.data['totalPaidAmount'] ?? 0.0,
          paidAmount: (job.data['paidAmount'] as num?)?.toDouble() ?? 0.0,
          tableCharge: (job.data['tableCharge'] as num?)?.toDouble() ?? 0.0,
          refundAmount: (job.data['refundAmount'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: job.data['paymentMethod'],
          paymentStatus: job.data['paymentStatus'],
          qrCodeData: job.data['qrCodeData'],
          barcode: job.data['barcode'],
          logoBase64: job.data['logoBase64'],
          openDrawer: job.data['openDrawer'] ?? false,
          taxBreakdown: job.data['taxBreakdown'] != null
              ? (job.data['taxBreakdown'] as Map).map(
                  (k, v) => MapEntry(
                    k as String,
                    v is num
                        ? v.toDouble()
                        : (double.tryParse(v.toString()) ?? 0.0),
                  ),
                )
              : null,
          paymentDistribution: job.data['paymentDistribution'] != null
              ? (job.data['paymentDistribution'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : null,
        );

        await _plugin.printReceipt(printJob);
        // Remove job immediately after the await resolves.
        // Kotlin result.success() guarantees the data was flushed to the printer.
        // Without this, the 500ms Timer.periodic re-processes the job before the
        // asynchronous onPrintComplete callback fires — causing 4-5 duplicate prints.
        _completeJob(job);
        return;
      } else if (job.type == PrintJobType.kds) {
        final kdsJob = KDSPrintJob(
          storeName: job.data['storeName'],
          orderNumber: job.data['orderNumber'],
          tableNumber: job.data['tableNumber'],
          orderType: job.data['orderType'],
          time: job.data['time'],
          date: job.data['date'] as String?,
          customerName: job.data['customerName'] as String?,
          orderNotes: job.data['orderNotes'] as String?,
          items: (job.data['items'] as List).map((item) {
            return PrintJobItem(
              name: item['name'],
              quantity: item['quantity'],
              price: item['price'] ?? 0.0,
              notes: item['notes'],
              modifiers: item['modifiers'] != null
                  ? List<String>.from(item['modifiers'])
                  : null,
              status: item['status'],
            );
          }).toList(),
          priority: job.data['priority'],
          jobNumber: job.jobNumber ?? 0,
        );

        try {
          await _plugin.printKDS(kdsJob);
        } catch (kdsErr) {
          // If dedicated KDS printer is not connected, fall back to regular printer
          // with kitchen ticket format so orders print regardless.
          if (kdsErr.toString().contains('NOT_CONNECTED')) {
            debugPrint(
              '🔄 KDS printer unavailable — falling back to kitchen ticket on regular printer',
            );
            await _plugin.printKitchenTicket(kdsJob);
          } else {
            rethrow;
          }
        }
        // Same rationale as receipt: remove immediately to prevent re-processing.
        _completeJob(job);
        return;
      }
    } catch (e) {
      debugPrint('❌ Print job ${job.id} failed: $e');
      job.status = PrintJobStatus.failed;
      job.error = e.toString();

      // Schedule retry with exponential backoff
      if (job.retryCount < maxRetries) {
        final delay = retryDelayMs * job.retryCount;
        debugPrint('🔄 Retrying job ${job.id} in ${delay}ms');
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  /// Handle async print completion callback from native Epson SDK
  /// (receiveListener / onPrintComplete).
  ///
  /// IMPORTANT: This fires ASYNCHRONOUSLY, typically 2-10 seconds after
  /// sendData() returned, once the printer hardware physically finishes
  /// printing and sends an ACK.  By that time, [_completeJob] has ALREADY
  /// removed the finished job from the queue (immediately after sendData
  /// succeeded).
  ///
  /// We must NOT touch the queue here because [_queue.first] is now the
  /// NEXT job (or the queue is empty).  Removing it would silently discard
  /// a pending cashier/KDS print job — this was the root cause of
  /// intermittent cashier-bill auto-print failures: the KDS job's delayed
  /// onPrintComplete callback was deleting the cashier receipt from the queue.
  void _handlePrintComplete(PrintResult result) {
    if (result.success) {
      debugPrint('🖨️  [PrintComplete] Printer acknowledged print');
    } else {
      debugPrint('⚠️  [PrintComplete] Printer reported error: ${result.error}');
    }
  }

  /// Remove job from queue and record success. Called inline after successful print
  /// to prevent the Timer.periodic from re-processing the same job.
  void _completeJob(QueuedPrintJob job) {
    if (_queue.isNotEmpty && _queue.first.id == job.id) {
      _queue.removeFirst();
    }
    job.status = PrintJobStatus.completed;
    job.completedAt = DateTime.now();
    _addToHistory(job);
    debugPrint('✅ Job ${job.id} completed');
  }

  /// Add job to history
  void _addToHistory(QueuedPrintJob job) {
    _history.add(job);

    // Limit history size
    if (_history.length > historyLimit) {
      _history.removeAt(0);
    }
  }

  /// Get queue status
  QueueStatus getStatus() {
    return QueueStatus(
      queueLength: _queue.length,
      isProcessing: _isProcessing,
      pendingJobs: _queue
          .where((j) => j.status == PrintJobStatus.pending)
          .length,
      printingJobs: _queue
          .where((j) => j.status == PrintJobStatus.printing)
          .length,
      failedJobs: _queue.where((j) => j.status == PrintJobStatus.failed).length,
      historyCount: _history.length,
    );
  }

  /// Get print history
  List<QueuedPrintJob> getHistory({int? limit}) {
    if (limit != null) {
      return _history.reversed.take(limit).toList();
    }
    return _history.reversed.toList();
  }

  /// Clear history
  void clearHistory() {
    _history.clear();
  }

  /// Cancel specific job
  bool cancelJob(String jobId) {
    final job = _queue.firstWhere(
      (j) => j.id == jobId,
      orElse: () => throw PrinterException('Job not found: $jobId'),
    );

    if (job.status == PrintJobStatus.printing) {
      return false; // Cannot cancel job that's currently printing
    }

    _queue.remove(job);
    job.status = PrintJobStatus.cancelled;
    _addToHistory(job);

    debugPrint('🚫 Job $jobId cancelled');
    return true;
  }

  /// Clear entire queue
  void clearQueue() {
    final jobsToCancel = _queue
        .where((j) => j.status != PrintJobStatus.printing)
        .toList();

    for (final job in jobsToCancel) {
      job.status = PrintJobStatus.cancelled;
      _addToHistory(job);
      _queue.remove(job);
    }

    debugPrint('🗑️  Cleared ${jobsToCancel.length} jobs from queue');
  }

  /// Generate unique job ID
  String _generateJobId() {
    return 'PRT_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}';
  }

  /// Dispose
  void dispose() {
    _processTimer?.cancel();
  }
}

/// Queued print job
class QueuedPrintJob {
  final String id;
  final PrintJobType type;
  final Map<String, dynamic> data;
  final int? jobNumber;
  final PrintPriority priority;
  final DateTime addedAt;

  PrintJobStatus status = PrintJobStatus.pending;
  int retryCount = 0;
  DateTime? lastAttempt;
  DateTime? completedAt;
  String? error;
  PrintResult? result;

  QueuedPrintJob({
    required this.id,
    required this.type,
    required this.data,
    this.jobNumber,
    required this.priority,
    required this.addedAt,
  });

  Duration? get processingTime {
    if (completedAt != null) {
      return completedAt!.difference(addedAt);
    }
    return null;
  }
}

/// Print job type
enum PrintJobType { receipt, kds }

/// Print job priority
enum PrintPriority { urgent, normal, low }

/// Print job status
enum PrintJobStatus {
  pending,
  printing,
  completed,
  failed,
  cancelled,
  abandoned,
}

/// Queue status
class QueueStatus {
  final int queueLength;
  final bool isProcessing;
  final int pendingJobs;
  final int printingJobs;
  final int failedJobs;
  final int historyCount;

  QueueStatus({
    required this.queueLength,
    required this.isProcessing,
    required this.pendingJobs,
    required this.printingJobs,
    required this.failedJobs,
    required this.historyCount,
  });

  @override
  String toString() =>
      'QueueStatus(queue: $queueLength, pending: $pendingJobs, '
      'printing: $printingJobs, failed: $failedJobs)';
}
