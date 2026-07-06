import 'package:flutter/material.dart';
import '../../../../services/print_queue_manager.dart';
import '../../../../services/printer_models.dart';
import '../../../../services/epson_printer_plugin.dart';

/// Print Queue Screen
///
/// Visual queue management matching web app patterns:
/// - Active queue tab (pending/printing jobs)
/// - History tab (completed/failed jobs)
/// - Real-time status dashboard
/// - Retry failed jobs
/// - Cancel pending jobs
class PrintQueueScreen extends StatefulWidget {
  const PrintQueueScreen({Key? key}) : super(key: key);

  @override
  State<PrintQueueScreen> createState() => _PrintQueueScreenState();
}

class _PrintQueueScreenState extends State<PrintQueueScreen>
    with SingleTickerProviderStateMixin {
  // Queue service
  final PrintQueueManager _queueManager = PrintQueueManager();
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  // Tab controller
  late TabController _tabController;

  // State
  QueueStatus? _currentQueueStatus;
  List<QueuedPrintJob> _jobHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to job completions
    _plugin.onPrintComplete.listen((result) {
      if (!result.success) {
        _loadQueueData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Print failed: ${result.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'View Queue',
                textColor: Colors.white,
                onPressed: () {
                  _tabController.animateTo(0);
                },
              ),
            ),
          );
        }
      } else {
        _loadQueueData();
      }
    });

    _loadQueueData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load queue data
  Future<void> _loadQueueData() async {
    try {
      _currentQueueStatus = _queueManager.getStatus();
      _jobHistory = _queueManager.getHistory(limit: 50);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load queue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Retry failed job
  Future<void> _retryJob(QueuedPrintJob job) async {
    try {
      // Re-queue the job
      if (job.type == PrintJobType.receipt) {
        await _queueManager.queueReceipt(
          PrintJob(
            storeName: job.data['storeName'],
            orderNumber: job.data['orderNumber'],
            date: job.data['date'],
            time: job.data['time'],
            items: (job.data['items'] as List)
                .map(
                  (i) => PrintJobItem(
                    name: i['name'],
                    quantity: i['quantity'],
                    price: i['price'],
                  ),
                )
                .toList(),
            netAmount: (job.data['netAmount'] ?? job.data['subtotal'] ?? 0.0)
                .toDouble(),
            tax: (job.data['tax'] ?? 0.0).toDouble(),
            total: (job.data['total'] ?? 0.0).toDouble(),
          ),
        );
      } else {
        await _queueManager.queueKDS(
          KDSPrintJob(
            storeName: job.data['storeName'],
            orderNumber: job.data['orderNumber'],
            tableNumber: job.data['tableNumber'],
            orderType: job.data['orderType'],
            time: job.data['time'],
            items: (job.data['items'] as List)
                .map(
                  (i) => PrintJobItem(
                    name: i['name'],
                    quantity: i['quantity'],
                    price: i['price'] ?? 0.0,
                  ),
                )
                .toList(),
            jobNumber: job.jobNumber ?? 0,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job re-queued for printing'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadQueueData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cancel pending job
  Future<void> _cancelJob(String jobId) async {
    try {
      _queueManager.cancelJob(jobId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _loadQueueData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Clear entire queue
  Future<void> _clearQueue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue?'),
        content: const Text(
          'This will cancel all pending print jobs. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Try to clear queue
        _queueManager.clearQueue();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Queue cleared'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        await _loadQueueData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear queue: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Build queue status dashboard
  Widget _buildQueueStatusCard(QueueStatus status) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusCard(
              'Pending',
              Icons.hourglass_empty,
              Colors.orange,
              count: status.pendingJobs,
            ),
            _buildStatusCard(
              'Printing',
              Icons.print,
              Colors.blue,
              count: status.printingJobs,
            ),
            _buildStatusCard(
              'Completed',
              Icons.check_circle,
              Colors.green,
              count: _jobHistory
                  .where((j) => j.status == PrintJobStatus.completed)
                  .length,
            ),
            _buildStatusCard(
              'Failed',
              Icons.error,
              Colors.red,
              count: status.failedJobs,
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual status card
  Widget _buildStatusCard(
    String label,
    IconData icon,
    Color color, {
    required int count,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// Build active queue tab
  Widget _buildActiveQueueTab() {
    if (_currentQueueStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQueueStatus!.queueLength == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Queue is empty!', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'All print jobs completed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Get active jobs from history (last X jobs that are pending/printing)
    final activeJobs = _jobHistory
        .where(
          (j) =>
              j.status == PrintJobStatus.pending ||
              j.status == PrintJobStatus.printing ||
              j.status == PrintJobStatus.failed,
        )
        .take(20)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeJobs.length,
      itemBuilder: (context, index) {
        final job = activeJobs[index];
        return _buildJobCard(job, isActiveQueue: true);
      },
    );
  }

  /// Build history tab
  Widget _buildHistoryTab() {
    final completedJobs = _jobHistory
        .where(
          (j) =>
              j.status == PrintJobStatus.completed ||
              j.status == PrintJobStatus.failed ||
              j.status == PrintJobStatus.cancelled ||
              j.status == PrintJobStatus.abandoned,
        )
        .take(50)
        .toList();

    if (completedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No history yet', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedJobs.length,
      itemBuilder: (context, index) {
        final job = completedJobs[index];
        return _buildJobCard(job, isActiveQueue: false);
      },
    );
  }

  /// Build job card
  Widget _buildJobCard(QueuedPrintJob job, {required bool isActiveQueue}) {
    final isFailed = job.status == PrintJobStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildStatusIcon(job.status),
        title: Text(_getJobTitle(job)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(job.addedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (job.retryCount > 0) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.refresh, size: 14, color: Colors.orange[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Retry ${job.retryCount}',
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
                ],
              ],
            ),
            if (isFailed && job.error != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${job.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        isThreeLine: isFailed,
        trailing: _buildJobActions(job, isActiveQueue),
      ),
    );
  }

  /// Build status icon
  Widget _buildStatusIcon(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.pending:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.hourglass_empty, color: Colors.white, size: 20),
        );
      case PrintJobStatus.printing:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.print, color: Colors.white, size: 20),
        );
      case PrintJobStatus.completed:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white, size: 20),
        );
      case PrintJobStatus.failed:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white, size: 20),
        );
      case PrintJobStatus.cancelled:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.cancel, color: Colors.white, size: 20),
        );
      case PrintJobStatus.abandoned:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.block, color: Colors.white, size: 20),
        );
    }
  }

  /// Build job actions
  Widget? _buildJobActions(QueuedPrintJob job, bool isActiveQueue) {
    if (job.status == PrintJobStatus.failed) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        color: Colors.orange,
        onPressed: () => _retryJob(job),
        tooltip: 'Retry',
      );
    }

    if (job.status == PrintJobStatus.pending) {
      return IconButton(
        icon: const Icon(Icons.cancel),
        color: Colors.red,
        onPressed: () => _cancelJob(job.id),
        tooltip: 'Cancel',
      );
    }

    return null;
  }

  /// Get job title
  String _getJobTitle(QueuedPrintJob job) {
    final isReceipt = job.type == PrintJobType.receipt;

    if (isReceipt) {
      final printJob = job.data;
      return 'Receipt #${printJob['orderNumber']} • ${(printJob['items'] as List).length} items';
    } else {
      final kdsJob = job.data;
      return 'KDS Order #${kdsJob['orderNumber']} • Table ${kdsJob['tableNumber']}';
    }
  }

  /// Format time ago
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueueData,
          ),
          if (_currentQueueStatus != null &&
              _currentQueueStatus!.queueLength > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearQueue,
              tooltip: 'Clear Queue',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Queue'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_currentQueueStatus != null)
            _buildQueueStatusCard(_currentQueueStatus!),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildActiveQueueTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }
}
