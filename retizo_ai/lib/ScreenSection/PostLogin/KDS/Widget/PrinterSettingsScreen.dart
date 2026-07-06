import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../services/epson_printer_plugin.dart';
import '../../../../services/printer_models.dart';
import '../../../../services/multi_printer_coordinator.dart';
import '../../../../services/auto_reconnect_handler.dart';

/// Printer Settings Screen
///
/// Full-featured printer configuration interface:
/// - Discover printers on network
/// - Connect/disconnect printers
/// - Test print functionality
/// - Configure kitchen stations for multi-printer setup
/// - Monitor printer status
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  // Services
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();
  final MultiPrinterCoordinator _coordinator = MultiPrinterCoordinator();
  final AutoReconnectHandler _reconnectHandler = AutoReconnectHandler();

  // State
  final List<PrinterDevice> _discoveredPrinters = [];
  PrinterConfig? _receiptPrinterConfig;
  final Map<String, Map<String, dynamic>> _kitchenStations = {};

  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _loadSavedConfig();
  }

  /// Setup discovery listener
  void _setupListeners() {
    _plugin.onPrinterDiscovered.listen((printer) {
      if (!_discoveredPrinters.any((p) => p.target == printer.target)) {
        setState(() {
          _discoveredPrinters.add(printer);
        });
      }
    });
  }

  /// Load saved printer configuration
  void _loadSavedConfig() {
    // TODO: Load from SharedPreferences
    setState(() {
      _receiptPrinterConfig = PrinterConfig(
        target: 'TCP:192.168.1.100',
        printerType: 'regular',
        series: 'TM_T88VII',
        lang: 'MODEL_ANK',
      );
    });
  }

  /// Discover printers on network
  Future<void> _discoverPrinters() async {
    setState(() {
      _isDiscovering = true;
      _discoveredPrinters.clear();
    });

    try {
      await _plugin.discoverPrinters();

      // Discovery runs for ~10 seconds, results come via stream
      await Future.delayed(const Duration(seconds: 11));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${_discoveredPrinters.length} printers'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discovery failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    }
  }

  /// Connect to printer
  Future<void> _connectPrinter(PrinterConfig config) async {
    try {
      await _plugin.connectPrinter(config);

      // Enable auto-reconnect
      await _reconnectHandler.manageConnection(config.target, config);

      // Persist KDS config so it can be restored on next app startup
      if (config.printerType == 'kds') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'kds_printer_config',
          jsonEncode({
            'target': config.target,
            'series': config.series,
            'lang': config.lang,
            'printerType': config.printerType,
          }),
        );
      }

      setState(() {
        _receiptPrinterConfig = config;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Test print
  Future<void> _testPrint() async {
    if (_receiptPrinterConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No printer connected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _plugin.printReceipt(
        PrintJob(
          storeName: 'Test Restaurant',
          orderNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now().toString().substring(0, 10),
          time: DateTime.now().toString().substring(11, 16),
          items: [
            PrintJobItem(name: 'Test Item 1', quantity: 2, price: 10.99),
            PrintJobItem(name: 'Test Item 2', quantity: 1, price: 5.50),
          ],
          netAmount: 27.48,
          tax: 2.20,
          total: 29.68,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test print sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check printer status
  Future<void> _checkPrinterStatus() async {
    try {
      final status = await _plugin.getPrinterStatus(
        _receiptPrinterConfig?.printerType ?? 'regular',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Printer Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusRow('Paper', status.hasPaper),
                _statusRow('Cover Closed', status.isCoverClosed),
                _statusRow('Online', status.isOnline),
                if (status.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error Status Code: ${status.errorStatus}',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status check failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Status row widget
  Widget _statusRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  /// Add kitchen station dialog
  Future<void> _addKitchenStation() async {
    final formKey = GlobalKey<FormState>();
    String stationName = '';
    String ipAddress = '';
    String categoriesText = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Kitchen Station'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Station Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => stationName = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.101',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => ipAddress = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Item Categories',
                  hintText: 'pizza, pasta, salad',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => categoriesText = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);

                await _registerKitchenStation(
                  stationName,
                  ipAddress,
                  categoriesText,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Register kitchen station
  Future<void> _registerKitchenStation(
    String stationName,
    String ipAddress,
    String categoriesText,
  ) async {
    try {
      final categories = categoriesText
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      final stationId = stationName.toLowerCase().replaceAll(' ', '_');

      // Register with coordinator
      _coordinator.registerStation(
        KitchenStation(
          id: stationId,
          name: stationName,
          printerConfig: PrinterConfig(
            target: 'TCP:$ipAddress',
            printerType: 'kds',
            series: 'TM_L100',
            lang: 'MODEL_ANK',
          ),
          itemCategories: categories,
        ),
      );

      setState(() {
        _kitchenStations[stationId] = {
          'name': stationName,
          'ip': ipAddress,
          'categories': categories,
          'config': PrinterConfig(
            target: 'TCP:$ipAddress',
            printerType: 'kds',
            series: 'TM_L100',
            lang: 'MODEL_ANK',
          ),
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Station "$stationName" added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add station: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove kitchen station
  void _removeKitchenStation(String stationId) {
    _coordinator.unregisterStation(stationId);
    setState(() {
      _kitchenStations.remove(stationId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Station removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Discover Printers Button
          ElevatedButton.icon(
            onPressed: _isDiscovering ? null : _discoverPrinters,
            icon: _isDiscovering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(
              _isDiscovering ? 'Discovering...' : 'Discover Printers',
            ),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),

          const SizedBox(height: 20),

          // Discovered Printers List
          if (_discoveredPrinters.isNotEmpty) ...[
            const Text(
              'Discovered Printers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._discoveredPrinters.map(
              (printer) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(printer.deviceName),
                  subtitle: Text('${printer.deviceType} • ${printer.target}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => _connectPrinter(
                      PrinterConfig(
                        target: printer.target,
                        series: 'TM_M30',
                        lang: 'MODEL_ANK',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
          ],

          // Receipt Printer Section
          const Text(
            'Receipt Printer:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_receiptPrinterConfig != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Receipt Printer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Target: ${_receiptPrinterConfig!.target}'),
                    Text('Series: ${_receiptPrinterConfig!.series}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Test Print'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _checkPrinterStatus,
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.error_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('No receipt printer connected'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Kitchen Stations Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kitchen Stations:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addKitchenStation,
                icon: const Icon(Icons.add_circle),
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_kitchenStations.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No kitchen stations configured. Add stations to enable multi-printer routing.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._kitchenStations.entries.map((entry) {
              final stationId = entry.key;
              final station = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text(station['name']),
                  subtitle: Text(
                    'IP: ${station['ip']}\n'
                    'Categories: ${(station['categories'] as List).join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print, size: 20),
                        onPressed: () async {
                          // Test print to this station
                          try {
                            await _plugin.connectPrinter(station['config']);
                            await _plugin.printKDS(
                              KDSPrintJob(
                                storeName: 'Test',
                                orderNumber:
                                    'TEST-${DateTime.now().millisecondsSinceEpoch}',
                                tableNumber: '1',
                                orderType: 'Dine In',
                                time: DateTime.now().toString().substring(
                                  11,
                                  16,
                                ),
                                items: [
                                  PrintJobItem(
                                    name: 'Test Item',
                                    quantity: 1,
                                    price: 10.0,
                                  ),
                                ],
                                jobNumber: 1,
                              ),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test print sent to station'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
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
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _removeKitchenStation(stationId),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
