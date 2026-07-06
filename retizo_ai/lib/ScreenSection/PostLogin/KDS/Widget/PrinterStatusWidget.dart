// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Widget/PrinterSettingsScreen.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Widget/PrintQueueScreen.dart';

/// Printer Status Widget for KDS Screen
///
/// Shows printer connection status and provides quick actions
/// - Quick status indicator (connected/disconnected)
/// - Print queue badge showing pending jobs
/// - Quick access to settings and queue management
class PrinterStatusWidget extends StatelessWidget {
  const PrinterStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterIntegrationProvider>(
      builder: (context, printerProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Queue Status Badge
            if (printerProvider.pendingPrintJobs > 0)
              _buildQueueBadge(context, printerProvider.pendingPrintJobs),

            const SizedBox(width: 8),

            // Printer Status Indicator
            _buildPrinterStatusButton(
              context,
              printerProvider.isPrinterConnected,
            ),

            const SizedBox(width: 8),

            // Settings Button
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrinterSettingsScreen(),
                  ),
                );
              },
              tooltip: 'Printer Settings',
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueBadge(BuildContext context, int count) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrintQueueScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterStatusButton(BuildContext context, bool isConnected) {
    return InkWell(
      onTap: () {
        _showPrinterStatusMenu(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected ? Colors.green.shade300 : Colors.red.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.print : Icons.print_disabled,
              size: 18,
              color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'Connected' : 'Offline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isConnected
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterStatusMenu(BuildContext context) {
    final printerProvider = context.read<PrinterIntegrationProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Test Print
            ListTile(
              leading: const Icon(Icons.print_outlined, color: Colors.blue),
              title: const Text('Test Print'),
              subtitle: const Text('Send a test print to verify connection'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await printerProvider.testPrint();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test print sent successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test print failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),

            // Check Status
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Text('Check Status'),
              subtitle: const Text('View detailed printer status'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final status = await printerProvider.checkPrinterStatus();
                  if (context.mounted) {
                    _showStatusDialog(context, status);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status check failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),

            // View Queue
            ListTile(
              leading: const Icon(Icons.queue, color: Colors.purple),
              title: const Text('View Print Queue'),
              subtitle: Text(
                '${printerProvider.pendingPrintJobs} jobs pending',
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrintQueueScreen(),
                  ),
                );
              },
            ),

            // Settings
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Printer Settings'),
              subtitle: const Text('Configure printers and stations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrinterSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, dynamic status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusRow('Online', status.isOnline),
            _statusRow('Paper OK', status.hasPaper),
            _statusRow('Cover Closed', !status.coverOpen),
            _statusRow('Ready', status.isReady),
            const SizedBox(height: 12),
            if (!status.isReady)
              Text(
                'Error: ${status.errorStatus ?? "Unknown"}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Printer Auto-Print Settings Widget
///
/// Toggle for auto-print and other printer settings
class PrinterSettingsToggle extends StatelessWidget {
  const PrinterSettingsToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterIntegrationProvider>(
      builder: (context, printerProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.print),
          title: const Text('Printer Settings'),
          children: [
            SwitchListTile(
              title: const Text('Auto-Print Orders'),
              subtitle: const Text('Automatically print when order received'),
              value: printerProvider.autoPrintEnabled,
              onChanged: (value) {
                printerProvider.autoPrintEnabled = value;
                printerProvider.saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Use Print Queue'),
              subtitle: const Text('Enable automatic retry on print failure'),
              value: printerProvider.useQueueForReliability,
              onChanged: (value) {
                printerProvider.useQueueForReliability = value;
                printerProvider.saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Multi-Station Mode'),
              subtitle: const Text('Route items to multiple kitchen printers'),
              value: printerProvider.multiStationEnabled,
              onChanged: (value) {
                printerProvider.multiStationEnabled = value;
                printerProvider.saveSettings();
              },
            ),
          ],
        );
      },
    );
  }
}

/// Floating Action Button for Quick Print Actions
class PrinterQuickActionButton extends StatelessWidget {
  const PrinterQuickActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterIntegrationProvider>(
      builder: (context, printerProvider, child) {
        return FloatingActionButton(
          onPressed: () {
            _showQuickActionMenu(context, printerProvider);
          },
          backgroundColor: printerProvider.isPrinterConnected
              ? Colors.blue
              : Colors.grey,
          child: Stack(
            children: [
              const Icon(Icons.print),
              if (printerProvider.pendingPrintJobs > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      printerProvider.pendingPrintJobs.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActionMenu(
    BuildContext context,
    PrinterIntegrationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Test Print'),
              onTap: () async {
                Navigator.pop(context);
                await provider.testPrint();
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue, color: Colors.orange),
              title: const Text('View Queue'),
              subtitle: Text('${provider.pendingPrintJobs} pending'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrintQueueScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrinterSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
