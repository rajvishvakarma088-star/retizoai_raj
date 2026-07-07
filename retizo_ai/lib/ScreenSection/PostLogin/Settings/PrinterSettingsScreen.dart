// ignore_for_file: file_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../GlobalComponents/CommonProvider/CommonProvider.dart';
import '../../../GlobalComponents/Constant/GlobalAppColor.dart';
import '../../../services/epson_printer_plugin.dart';
import '../../../services/printer_models.dart';
import '../KDS/Controller/PrinterIntegrationProvider.dart';
import 'PrintingDeviceProvider.dart';

/// Printer Settings Screen - Manual Testing & Configuration
///
/// For development/testing phase - all controls are manual
/// Features:
/// - LAN/WiFi printer discovery (main connection type)
/// - Manual IP connection
/// - USB/Bluetooth support (shown in UI)
/// - Saved printers list
/// - Test print functionality
/// - Connection status display
///
/// Note: Printer selection for specific purposes (Bill/KDS) is done
/// when printing from the order screen, not in general settings.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  // Discovery state
  bool _isDiscovering = false;
  List<PrinterDevice> _discoveredPrinters = [];
  String? _discoveryError;

  // Manual connection
  final _ipController = TextEditingController(text: '192.168.29.115');
  final _portController = TextEditingController(text: '9100');
  final _printerNameController = TextEditingController(text: 'My Printer');
  String? _connectionError;
  bool _isConnecting = false;

  // Saved printers
  List<SavedPrinter> _savedPrinters = [];
  SavedPrinter? _selectedPrinter;

  // Connection type
  String _selectedConnectionType = 'TCP'; // TCP (LAN), USB, Bluetooth

  // Test print
  bool _isTesting = false;

  // KDS Printer connection
  final _kdsIpController = TextEditingController();
  bool _isConnectingKds = false;
  String? _kdsConnectionError;
  String _connectedKdsIp = '';
  String _kdsSelectedSeries = 'TM_L100';

  String _normalizeConnectionType(String? raw) {
    final upper = (raw ?? 'TCP').toUpperCase();
    if (upper.startsWith('TCPS')) return 'TCPS';
    if (upper.startsWith('TCP')) return 'TCP';
    if (upper.startsWith('BT') || upper.startsWith('BLUETOOTH')) return 'BT';
    if (upper.startsWith('USB')) return 'USB';
    return 'TCP';
  }

  int _defaultPortForType(String type) => type == 'TCPS' ? 8043 : 9100;

  String _extractHost(String target) {
    var clean = target.split('|').first.split('[').first;
    clean = clean.replaceFirst(
      RegExp(r'^(tcps:|tcp:|bt:|usb:)', caseSensitive: false),
      '',
    );
    clean = clean.replaceFirst(RegExp(r'^:+'), '');
    return clean.split(':').first;
  }

  int _extractPortFromTarget(String target, String connectionType) {
    final clean = target.split('|').first.split('[').first;
    final match = RegExp(r':([0-9]+)$').firstMatch(clean);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ??
          _defaultPortForType(connectionType);
    }
    return _defaultPortForType(connectionType);
  }

  String _normalizeTarget(
    String rawTarget, {
    int? port,
    String? connectionType,
  }) {
    var target = rawTarget.trim();
    debugPrint(
      '  [_normalizeTarget] Input: rawTarget=$rawTarget, port=$port, connectionType=$connectionType',
    );

    // NEVER split on '[' - Epson SDK uses things like [local_printer] for TCPS certificates!
    if (target.contains('|')) {
      final before = target;
      target = target.split('|').first.trim();
      debugPrint('  [_normalizeTarget] removed pipe: $before to $target');
    }

    final type = _normalizeConnectionType(connectionType ?? target);
    debugPrint('  [_normalizeTarget] Connection type: $type');

    // Extract the raw IP or Mac from after the prefix
    var hostPart = target.replaceFirst(
      RegExp(r'^(tcps:|tcp:|bt:|usb:)', caseSensitive: false),
      '',
    );
    debugPrint('  [_normalizeTarget] After prefix removal: hostPart=$hostPart');

    hostPart = hostPart.replaceFirst(RegExp(r'^:+'), '');
    debugPrint(
      '  [_normalizeTarget] After leading colons removed: hostPart=$hostPart',
    );

    // For TCP/TCPS, remove any appended port (e.g. 192.168.1.5:9100 -> 192.168.1.5)
    if (type == 'TCP' || type == 'TCPS') {
      final parts = hostPart.split(':');
      if (parts.length == 2 && int.tryParse(parts[1]) != null) {
        debugPrint(
          '  [_normalizeTarget] Removing port from hostPart: $hostPart → ${parts[0]}',
        );
        hostPart = parts[0];
      }
    }

    final result = '$type:$hostPart';
    debugPrint('  [_normalizeTarget] Final result: $result');
    return result;
  }

  String _inferSeriesFromName(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.contains('m30iii')) return 'TM_M30III';
    if (lower.contains('m30ii')) return 'TM_M30II';
    if (lower.contains('m30')) return 'TM_M30';
    if (lower.contains('t88')) return 'TM_T88VII';
    if (lower.contains('t20')) return 'TM_T20';
    if (lower.contains('l90')) return 'TM_L90';
    return 'TM_M30III';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPrinters();
    _setupDiscoveryListener();
    _loadSavedKdsConfig();
    // Auto-fetch backend printing devices when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshDevices();
    });
  }

  /// Setup listener for discovered printers
  void _setupDiscoveryListener() {
    _plugin.onPrinterDiscovered.listen((device) {
      setState(() {
        // Avoid duplicates
        if (!_discoveredPrinters.any((p) => p.target == device.target)) {
          _discoveredPrinters.add(device);
        }
      });
    });
  }

  /// Load saved KDS config from SharedPreferences
  Future<void> _loadSavedKdsConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kdsConfigJson = prefs.getString('kds_printer_config');
      if (kdsConfigJson != null) {
        final config = jsonDecode(kdsConfigJson) as Map<String, dynamic>;
        final target = config['target'] as String? ?? '';
        final ip = target.replaceFirst(
          RegExp(r'^TCP:', caseSensitive: false),
          '',
        );
        final series = config['series'] as String? ?? 'TM_L100';
        if (mounted) {
          setState(() {
            if (ip.isNotEmpty) _kdsIpController.text = ip;
            _kdsSelectedSeries = series;
            _connectedKdsIp = ip;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading KDS config: $e');
    }
  }

  /// Load saved printers from SharedPreferences
  Future<void> _loadSavedPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final printersJson = prefs.getStringList('saved_printers') ?? [];
      setState(() {
        final loadedPrinters = printersJson
            .map((json) => SavedPrinter.fromJson(jsonDecode(json)))
            .toList();

        _savedPrinters = loadedPrinters.map((p) {
          final normalizedType = _normalizeConnectionType(p.type);
          final normalizedTarget = _normalizeTarget(
            p.target,
            port: p.port,
            connectionType: normalizedType,
          );
          final normalizedPort = _extractPortFromTarget(
            normalizedTarget,
            normalizedType,
          );
          final inferredSeries = p.series ?? _inferSeriesFromName(p.name);

          return p.copyWith(
            target: normalizedTarget,
            port: normalizedPort,
            type: normalizedType,
            series: inferredSeries,
          );
        }).toList();

        // Load selected printer
        final selectedTarget = prefs.getString('selected_printer');
        if (selectedTarget != null) {
          _selectedPrinter = _savedPrinters.firstWhere(
            (p) => p.target == selectedTarget,
            orElse: () => _savedPrinters.isNotEmpty
                ? _savedPrinters.first
                : SavedPrinter(
                    name: '',
                    target: '',
                    port: 0,
                    type: 'TCP',
                    series: _inferSeriesFromName(null),
                  ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading saved printers: $e');
    }
  }

  /// Save printers to SharedPreferences
  Future<void> _savePrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final printersJson = _savedPrinters
          .map((p) => jsonEncode(p.toJson()))
          .toList();
      await prefs.setStringList('saved_printers', printersJson);

      if (_selectedPrinter != null) {
        await prefs.setString('selected_printer', _selectedPrinter!.target);
      }
    } catch (e) {
      debugPrint('Error saving printers: $e');
    }
  }

  /// Start LAN/WiFi printer discovery
  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredPrinters.clear();
      _discoveryError = null;
    });

    try {
      // Discover printers based on selected connection type
      String portType = 'all';
      if (_selectedConnectionType == 'TCP')
        portType = 'tcp';
      else if (_selectedConnectionType == 'USB')
        portType = 'usb';
      else if (_selectedConnectionType == 'Bluetooth')
        portType = 'bluetooth';

      await _plugin.discoverPrinters(
        portType: portType,
        timeout: 10000, // 10 seconds
      );

      // Stop discovery after timeout
      await Future.delayed(const Duration(seconds: 10));
      await _plugin.stopDiscovery();

      setState(() {
        _isDiscovering = false;
        if (_discoveredPrinters.isEmpty) {
          _discoveryError = 'No printers found. Check network connection.';
        }
      });
    } catch (e) {
      setState(() {
        _isDiscovering = false;
        _discoveryError = 'Discovery failed: $e';
      });
    }
  }

  /// Stop ongoing discovery
  Future<void> _stopDiscovery() async {
    try {
      await _plugin.stopDiscovery();
      setState(() {
        _isDiscovering = false;
      });
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
    }
  }

  /// Connect to printer using manual IP
  Future<void> _connectManualIP() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty || port.isEmpty) {
      setState(() {
        _connectionError = 'Please enter IP address and port';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      final normalizedType = _normalizeConnectionType(_selectedConnectionType);
      final parsedPort =
          int.tryParse(port) ?? _defaultPortForType(normalizedType);
      final normalizedTarget = _normalizeTarget(
        '$normalizedType:$ip',
        port: parsedPort,
        connectionType: normalizedType,
      );
      final effectivePort = _extractPortFromTarget(
        normalizedTarget,
        normalizedType,
      );
      final inferredSeries = _inferSeriesFromName(_printerNameController.text);

      final config = PrinterConfig(
        target: normalizedTarget,
        printerType: 'regular',
        series: inferredSeries,
      );

      // Try to connect
      await _plugin.connectPrinter(config);

      // Test connection by getting status
      debugPrint('  [manual ip] getting printer status');
      await _plugin.getPrinterStatus('regular');
      debugPrint('  [manual ip] printer status retrieved successfully');

      // Save printer
      final savedPrinter = SavedPrinter(
        name: _printerNameController.text.trim().isEmpty
            ? 'Manual Connection'
            : _printerNameController.text.trim(),
        target: normalizedTarget,
        ipAddress: ip,
        port: effectivePort,
        type: normalizedType,
        series: inferredSeries,
      );
      debugPrint(
        '  [manual ip] created saved printer: name=${savedPrinter.name}, target=${savedPrinter.target}',
      );

      setState(() {
        if (!_savedPrinters.any((p) => p.target == savedPrinter.target)) {
          _savedPrinters.add(savedPrinter);
          debugPrint('  [manual ip] added to saved printers list');
        }
        _selectedPrinter = savedPrinter;
        _isConnecting = false;
      });

      await _savePrinters();
      debugPrint('  [manual ip] printers saved to shared preferences');

      // ✅ Update PrinterIntegrationProvider connection status
      if (mounted) {
        final printerProvider = Provider.of<PrinterIntegrationProvider>(
          context,
          listen: false,
        );
        debugPrint(
          '📍 [PrinterSettings] Provider instance: ${printerProvider.hashCode}',
        );
        debugPrint(
          '📍 [PrinterSettings] BEFORE update - isPrinterConnected: ${printerProvider.isPrinterConnected}',
        );

        printerProvider.updateConnectionStatus(
          isConnected: true,
          printerModel: inferredSeries,
          connectionQuality: 'Excellent',
        );

        debugPrint('✅ [PrinterSettings] Connection status updated');
        debugPrint(
          '📍 [PrinterSettings] AFTER update - isPrinterConnected: ${printerProvider.isPrinterConnected}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('  [manual ip] error: $e');
      debugPrint('  [manual ip] stack trace: ${StackTrace.current}');
      setState(() {
        _isConnecting = false;
        _connectionError = 'Connection failed: $e';
      });
    }
  }

  /// Connect to discovered or saved printer
  Future<void> _connectToPrinter(SavedPrinter printer) async {
    try {
      final normalizedType = _normalizeConnectionType(printer.type);
      final normalizedTarget = _normalizeTarget(
        printer.target,
        port: printer.port,
        connectionType: normalizedType,
      );
      final normalizedPort = _extractPortFromTarget(
        normalizedTarget,
        normalizedType,
      );
      final inferredSeries =
          printer.series ?? _inferSeriesFromName(printer.name);

      final config = PrinterConfig(
        target: normalizedTarget,
        printerType: 'regular',
        series: inferredSeries,
      );

      await _plugin.connectPrinter(config);

      setState(() {
        final updatedPrinter = printer.copyWith(
          target: normalizedTarget,
          port: normalizedPort,
          type: normalizedType,
          series: inferredSeries,
        );
        _selectedPrinter = updatedPrinter;
        _savedPrinters = _savedPrinters
            .map((p) => p.target == printer.target ? updatedPrinter : p)
            .toList();
        _connectionError = null;
      });

      await _savePrinters();

      // ✅ Update PrinterIntegrationProvider connection status
      if (mounted) {
        final printerProvider = Provider.of<PrinterIntegrationProvider>(
          context,
          listen: false,
        );
        debugPrint(
          '📍 [PrinterSettings] Provider instance: ${printerProvider.hashCode}',
        );
        debugPrint(
          '📍 [PrinterSettings] BEFORE update - isPrinterConnected: ${printerProvider.isPrinterConnected}',
        );

        printerProvider.updateConnectionStatus(
          isConnected: true,
          printerModel: inferredSeries,
          connectionQuality: 'Excellent',
        );

        debugPrint('✅ [PrinterSettings] Connection status updated');
        debugPrint(
          '📍 [PrinterSettings] AFTER update - isPrinterConnected: ${printerProvider.isPrinterConnected}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connected to ${printer.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionError = 'Failed to connect: $e';
      });
    }
  }

  /// Connect to KDS (kitchen) printer using manual IP
  Future<void> _connectKDSPrinter() async {
    final ip = _kdsIpController.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _kdsConnectionError = 'Please enter the KDS printer IP address';
      });
      return;
    }

    setState(() {
      _isConnectingKds = true;
      _kdsConnectionError = null;
    });

    try {
      final target = 'TCP:$ip';
      final config = PrinterConfig(
        target: target,
        printerType: 'kds',
        series: _kdsSelectedSeries,
        lang: 'MODEL_ANK',
      );

      await _plugin.connectPrinter(config);

      // Persist KDS config for auto-restore on next app launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kds_printer_config',
        jsonEncode({
          'target': target,
          'series': _kdsSelectedSeries,
          'lang': 'MODEL_ANK',
          'printerType': 'kds',
        }),
      );

      setState(() {
        _connectedKdsIp = ip;
        _isConnectingKds = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KDS printer connected: $ip'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnectingKds = false;
        _kdsConnectionError = 'KDS connection failed: $e';
      });
    }
  }

  /// Test print to verify connection
  Future<void> _testPrint() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please connect to a printer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final testJob = PrintJob(
        storeName: 'CulAI Restaurant - TEST',
        orderNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now().toString().substring(0, 10),
        time: DateTime.now().toString().substring(11, 16),
        items: [
          PrintJobItem(
            name: 'Test Item - Connection OK',
            quantity: 1,
            price: 0.0,
          ),
        ],
        netAmount: 0.0,
        tax: 0.0,
        total: 0.0,
      );

      await _plugin.printReceipt(testJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test print sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Delete saved printer
  Future<void> _deletePrinter(SavedPrinter printer) async {
    setState(() {
      _savedPrinters.removeWhere((p) => p.target == printer.target);
      if (_selectedPrinter?.target == printer.target) {
        _selectedPrinter = _savedPrinters.isNotEmpty
            ? _savedPrinters.first
            : null;
      }
    });
    await _savePrinters();
  }

  @override
  Widget build(BuildContext context) {
    final printerProvider = context.watch<PrinterIntegrationProvider>();
    final deviceProvider = context.watch<PrintingDeviceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: GlobalAppColor.DarkTextColorCode, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Printer Settings",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: GlobalAppColor.DarkTextColorCode,
          ),
        ),
        actions: [
          // Auto-print toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Auto-Print',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlobalAppColor.DarkTextColorCode,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: printerProvider.autoPrintEnabled,
                  onChanged: (value) {
                    printerProvider.autoPrintEnabled = value;
                    setState(() {});
                  },
                  activeColor: GlobalAppColor.ButtonColor,
                  activeTrackColor: GlobalAppColor.ButtonColor.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Section
            _buildInfoSection(),
            const SizedBox(height: 14),

            // Backend Printing Devices
            _buildBackendDevices(deviceProvider),
            const SizedBox(height: 14),

            // Connection Type Selector
            _buildConnectionTypeSelector(),
            const SizedBox(height: 14),

            // Quick Connect - Manual IP
            _buildManualConnection(),
            const SizedBox(height: 14),

            // KDS Kitchen Printer
            _buildKDSConnection(),
            const SizedBox(height: 14),

            // Discover Printers Button
            _buildDiscoverySection(),
            const SizedBox(height: 14),

            // Discovered Printers
            if (_discoveredPrinters.isNotEmpty) ...[
              _buildDiscoveredPrinters(),
              const SizedBox(height: 14),
            ],

            // Saved Printers
            _buildSavedPrinters(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helper card wrapper ──
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  // ── Backend Printing Devices ──
  Widget _buildBackendDevices(PrintingDeviceProvider provider) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_other_outlined, color: GlobalAppColor.ButtonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backend Printing Devices',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: GlobalAppColor.DarkTextColorCode,
                  ),
                ),
              ),
              IconButton(
                iconSize: 20,
                tooltip: 'Refresh from server',
                icon: provider.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GlobalAppColor.ButtonColor,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, color: GlobalAppColor.ButtonColor),
                onPressed: provider.isLoading ? null : _refreshDevices,
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),
          Text(
            'Auto-detects from /api/printingDevice. KDS[0] is used for auto-printing.',
            style: TextStyle(fontSize: 12, color: GlobalAppColor.HomeLightTextColor),
          ),
          const SizedBox(height: 12),

          if (provider.error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!provider.isLoading && provider.devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No devices loaded yet. Tap refresh to fetch.',
                  style: TextStyle(fontSize: 13, color: GlobalAppColor.HomeLightTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          ...provider.devices.map((device) {
            final isKds = device.isKds;
            final isPrimaryKds = isKds && provider.primaryKdsDevice?.deviceId == device.deviceId;
            final badgeColor = isKds ? Colors.orange : Colors.blue;
            final badgeLabel = isKds ? 'KDS' : 'Cashier';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: isPrimaryKds
                      ? GlobalAppColor.ButtonColor.withOpacity(0.06)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPrimaryKds
                        ? GlobalAppColor.ButtonColor.withOpacity(0.3)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.shade200),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Device info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: GlobalAppColor.DarkTextColorCode,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPrimaryKds) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: const Text(
                                    'Auto-print',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device.ipAddress}  ·  Port ${device.portNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: GlobalAppColor.HomeLightTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status wifi icon
                    if (isPrimaryKds)
                      Icon(
                        provider.kdsConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 18,
                        color: provider.kdsConnected ? const Color(0xFF16A34A) : Colors.grey.shade400,
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

  void _refreshDevices() {
    if (!mounted) return;
    final token = Provider.of<UserInfoProvider>(context, listen: false).AccessToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before refreshing devices'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.read<PrintingDeviceProvider>().fetchAndConnect(token);
  }

  // ── Info Section ──
  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: GlobalAppColor.ButtonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Printer Configuration',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkBlueColor,
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFBFDBFE), thickness: 1),
          Text(
            '• Connect your Epson printers via LAN/WiFi (recommended), USB, or Bluetooth\n'
            '• When printing orders, select whether to print as a Bill or KDS ticket\n'
            '• Test each printer after configuration to ensure proper connection',
            style: TextStyle(
              fontSize: 12.5,
              color: GlobalAppColor.HomeLightTextColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ── Connection Type Selector ──
  Widget _buildConnectionTypeSelector() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GlobalAppColor.DarkTextColorCode,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),
          Wrap(
            spacing: 8,
            children: ['TCP', 'USB', 'Bluetooth'].map((type) {
              final isSelected = _selectedConnectionType == type;
              final isPrimary = type == 'TCP';

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == 'TCP'
                          ? Icons.wifi_rounded
                          : type == 'USB'
                              ? Icons.usb_rounded
                              : Icons.bluetooth_rounded,
                      size: 15,
                      color: isSelected ? Colors.white : GlobalAppColor.DarkTextColorCode,
                    ),
                    const SizedBox(width: 6),
                    Text(type),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedConnectionType = type;
                    });
                  }
                },
                selectedColor: GlobalAppColor.ButtonColor,
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                pressElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? GlobalAppColor.ButtonColor : const Color(0xFFE2E8F0),
                  ),
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : GlobalAppColor.DarkTextColorCode,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedConnectionType == 'TCP'
                ? 'LAN/WiFi connection (recommended for restaurant use)'
                : _selectedConnectionType == 'USB'
                    ? 'USB connection (requires printer connected via cable)'
                    : 'Bluetooth connection (short range, for mobile printing)',
            style: TextStyle(fontSize: 12, color: GlobalAppColor.HomeLightTextColor),
          ),
        ],
      ),
    );
  }

  // ── Manual Connection ──
  Widget _buildManualConnection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_input_antenna_rounded, color: Colors.pink.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Connect - Manual IP',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),

          // Printer Name
          _buildInputFieldLabel('Printer Name *'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _printerNameController,
            hint: 'e.g., EPSON KDS, EPSON CASHIER',
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // IP Address
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputFieldLabel('IP Address *'),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _ipController,
                      hint: '192.168.29.115',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Port Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputFieldLabel('Port Number *'),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _portController,
                      hint: '9100',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Connect and Test Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isConnecting ? null : _connectManualIP,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(_isConnecting ? 'Connecting...' : 'Use This Printer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalAppColor.ButtonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testPrint,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // Connection Error
          if (_connectionError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectionError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── KDS Connection ──
  Widget _buildKDSConnection() {
    final isConnected = _connectedKdsIp.isNotEmpty;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen_outlined, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'KDS Kitchen Printer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
              const SizedBox(width: 8),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),
          Text(
            'Connect a separate Epson LFC printer (e.g. TM-L100) for kitchen order tickets.',
            style: TextStyle(fontSize: 12, color: GlobalAppColor.HomeLightTextColor),
          ),
          const SizedBox(height: 14),

          // KDS IP
          _buildInputFieldLabel('KDS Printer IP Address *'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _kdsIpController,
            hint: '192.168.29.116',
            keyboardType: TextInputType.number,
            suffix: isConnected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18) : null,
          ),
          const SizedBox(height: 12),

          // Series Selector
          _buildInputFieldLabel('Printer Series'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: ['TM_L100', 'TM_L90LFC'].map((s) {
              final isSelected = _kdsSelectedSeries == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _kdsSelectedSeries = s);
                  }
                },
                selectedColor: Colors.orange.shade700,
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                pressElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.orange.shade700 : const Color(0xFFE2E8F0),
                  ),
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : GlobalAppColor.DarkTextColorCode,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Connect button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isConnectingKds ? null : _connectKDSPrinter,
              icon: _isConnectingKds
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isConnected ? Icons.refresh_rounded : Icons.link_rounded, size: 18),
              label: Text(
                _isConnectingKds
                    ? 'Connecting KDS...'
                    : isConnected
                        ? 'Reconnect KDS ($_connectedKdsIp)'
                        : 'Connect KDS Printer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Error display
          if (_kdsConnectionError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _kdsConnectionError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Discovery Section ──
  Widget _buildDiscoverySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discover Network Printers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
              if (_isDiscovering)
                TextButton.icon(
                  onPressed: _stopDiscovery,
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Stop'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),

          if (_isDiscovering) ...[
            LinearProgressIndicator(
              color: GlobalAppColor.ButtonColor,
              backgroundColor: GlobalAppColor.ButtonColor.withOpacity(0.15),
            ),
            const SizedBox(height: 10),
            Text(
              'Scanning for local printers...',
              style: TextStyle(fontSize: 12, color: GlobalAppColor.HomeLightTextColor),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _startDiscovery,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Scan for Printers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

          if (_discoveryError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _discoveryError!,
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Discovered Printers ──
  Widget _buildDiscoveredPrinters() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discovered Printers (${_discoveredPrinters.length})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GlobalAppColor.DarkTextColorCode,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _discoveredPrinters.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final printer = _discoveredPrinters[index];

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.print_rounded, color: GlobalAppColor.ButtonColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.deviceName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: GlobalAppColor.DarkTextColorCode,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${printer.target}  ·  ${printer.deviceType}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: GlobalAppColor.HomeLightTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final connectionType = _normalizeConnectionType(printer.target);
                        final normalizedTarget = _normalizeTarget(
                          printer.target,
                          connectionType: connectionType,
                        );
                        final normalizedPort = _extractPortFromTarget(
                          normalizedTarget,
                          connectionType,
                        );
                        final inferredSeries = _inferSeriesFromName(printer.deviceName);

                        final savedPrinter = SavedPrinter(
                          name: printer.deviceName,
                          target: normalizedTarget,
                          ipAddress: printer.ipAddress ?? _extractHost(normalizedTarget),
                          port: normalizedPort,
                          type: connectionType,
                          series: inferredSeries,
                        );

                        setState(() {
                          if (!_savedPrinters.any((p) => p.target == printer.target)) {
                            _savedPrinters.add(savedPrinter);
                          }
                        });

                        await _savePrinters();
                        await _connectToPrinter(savedPrinter);
                      },
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Add', style: TextStyle(fontSize: 11.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Saved Printers ──
  Widget _buildSavedPrinters() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Printers (${_savedPrinters.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
              if (_savedPrinters.isNotEmpty)
                TextButton.icon(
                  onPressed: _loadSavedPrinters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: GlobalAppColor.ButtonColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0), thickness: 1),

          if (_savedPrinters.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.print_disabled_rounded,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No saved printers',
                      style: TextStyle(color: GlobalAppColor.HomeLightTextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add a printer using manual IP or discovery',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedPrinters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final printer = _savedPrinters[index];
                final isSelected = _selectedPrinter?.target == printer.target;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDCFCE7).withOpacity(0.3)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.print_rounded,
                        color: isSelected ? const Color(0xFF15803D) : Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            printer.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: GlobalAppColor.DarkTextColorCode,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          'IP: ${printer.ipAddress}  ·  Port: ${printer.port}',
                          style: TextStyle(
                            fontSize: 12,
                            color: GlobalAppColor.HomeLightTextColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSelected)
                          IconButton(
                            icon: const Icon(Icons.link_rounded, size: 20),
                            onPressed: () => _connectToPrinter(printer),
                            tooltip: 'Connect',
                            color: const Color(0xFF16A34A),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: () => _deletePrinter(printer),
                          tooltip: 'Delete',
                          color: Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Clean Helper Input widgets ──

  Widget _buildInputFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: GlobalAppColor.DarkTextColorCode,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.5, color: GlobalAppColor.DarkTextColorCode),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: GlobalAppColor.ButtonColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _printerNameController.dispose();
    _kdsIpController.dispose();
    super.dispose();
  }
}

/// Saved Printer Model
class SavedPrinter {
  final String name;
  final String target;
  final String? ipAddress;
  final int port;
  final String type;
  final String? series;

  SavedPrinter({
    required this.name,
    required this.target,
    this.ipAddress,
    required this.port,
    required this.type,
    this.series,
  });

  factory SavedPrinter.fromJson(Map<String, dynamic> json) {
    return SavedPrinter(
      name: json['name'] ?? 'Unknown',
      target: json['target'] ?? '',
      ipAddress: json['ipAddress'],
      port: json['port'] ?? 9100,
      type: json['type'] ?? 'TCP',
      series: json['series'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': target,
      'ipAddress': ipAddress,
      'port': port,
      'type': type,
      'series': series,
    };
  }

  // Create a copy with updated fields
  SavedPrinter copyWith({
    String? name,
    String? target,
    String? ipAddress,
    int? port,
    String? type,
    String? series,
  }) {
    return SavedPrinter(
      name: name ?? this.name,
      target: target ?? this.target,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      type: type ?? this.type,
      series: series ?? this.series,
    );
  }
}
