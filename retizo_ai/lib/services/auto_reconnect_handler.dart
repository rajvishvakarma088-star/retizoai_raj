import 'dart:async';
import 'package:flutter/foundation.dart';
import 'epson_printer_plugin.dart';
import 'printer_models.dart';

/// Auto-Reconnect Handler with Exponential Backoff
///
/// Production reliability feature:
/// - Automatically reconnects when printer connection drops
/// - Exponential backoff prevents hammering the printer
/// - Configurable retry limits and delays
/// - Connection health monitoring
/// - Notifications for connection changes
///
/// This keeps your printers connected without manual intervention!
class AutoReconnectHandler {
  final EpsonPrinterPlugin _plugin = EpsonPrinterPlugin();

  // Tracked connections
  final Map<String, ManagedConnection> _connections = {};

  // Timers for reconnection attempts
  final Map<String, Timer> _reconnectTimers = {};

  // Status change stream
  final _statusController =
      StreamController<ConnectionStatusChange>.broadcast();
  Stream<ConnectionStatusChange> get onStatusChange => _statusController.stream;

  // Configuration
  static const int maxReconnectAttempts = 10;
  static const int baseDelayMs = 1000; // 1 second
  static const int maxDelayMs = 60000; // 60 seconds
  static const int healthCheckIntervalSec = 30;

  // Singleton
  static final AutoReconnectHandler _instance =
      AutoReconnectHandler._internal();
  factory AutoReconnectHandler() => _instance;
  AutoReconnectHandler._internal() {
    _startHealthMonitoring();
  }

  /// Manage a printer connection with auto-reconnect
  Future<void> manageConnection(
    String target,
    PrinterConfig config, {
    bool enableAutoReconnect = true,
  }) async {
    if (_connections.containsKey(target)) {
      debugPrint('🔗 Already managing connection: $target');
      return;
    }

    final connection = ManagedConnection(
      target: target,
      config: config,
      enableAutoReconnect: enableAutoReconnect,
    );

    _connections[target] = connection;

    // Initial connection
    await _connect(target);
  }

  /// Stop managing a connection
  Future<void> stopManaging(String target) async {
    final connection = _connections[target];
    if (connection == null) return;

    // Cancel any pending reconnect
    _reconnectTimers[target]?.cancel();
    _reconnectTimers.remove(target);

    // Disconnect
    try {
      await _plugin.disconnectPrinter(connection.config.printerType);
    } catch (e) {
      debugPrint('Error disconnecting $target: $e');
    }

    _connections.remove(target);
    debugPrint('🔌 Stopped managing: $target');
  }

  /// Connect to printer
  Future<void> _connect(String target) async {
    final connection = _connections[target];
    if (connection == null) return;

    try {
      connection.status = ConnectionStatus.connecting;
      connection.lastAttempt = DateTime.now();
      connection.attemptCount++;

      debugPrint(
        '🔄 Connecting to $target (attempt ${connection.attemptCount})...',
      );

      _notifyStatusChange(target, ConnectionStatus.connecting);

      final result = await _plugin.connectPrinter(connection.config);

      if (result['status'] == 'connected') {
        connection.status = ConnectionStatus.connected;
        connection.connectedAt = DateTime.now();
        connection.attemptCount = 0; // Reset on success
        connection.lastError = null;

        debugPrint('✅ Connected to $target');
        _notifyStatusChange(target, ConnectionStatus.connected);
      }
    } catch (e) {
      connection.status = ConnectionStatus.disconnected;
      connection.lastError = e.toString();

      debugPrint('❌ Connection failed: $target - $e');
      _notifyStatusChange(
        target,
        ConnectionStatus.disconnected,
        error: e.toString(),
      );

      // Schedule reconnect if enabled
      if (connection.enableAutoReconnect &&
          connection.attemptCount < maxReconnectAttempts) {
        _scheduleReconnect(target);
      } else if (connection.attemptCount >= maxReconnectAttempts) {
        connection.status = ConnectionStatus.failed;
        _notifyStatusChange(target, ConnectionStatus.failed);
        debugPrint('⛔ Max reconnect attempts reached for $target');
      }
    }
  }

  /// Schedule reconnect with exponential backoff
  void _scheduleReconnect(String target) {
    final connection = _connections[target];
    if (connection == null) return;

    // Cancel existing timer
    _reconnectTimers[target]?.cancel();

    // Calculate delay with exponential backoff
    final attempt = connection.attemptCount;
    var delayMs = baseDelayMs * (1 << (attempt - 1)); // 2^(n-1)
    if (delayMs > maxDelayMs) delayMs = maxDelayMs;

    debugPrint('⏰ Scheduling reconnect for $target in ${delayMs}ms');

    _reconnectTimers[target] = Timer(
      Duration(milliseconds: delayMs),
      () => _connect(target),
    );
  }

  /// Start periodic health monitoring
  void _startHealthMonitoring() {
    Timer.periodic(
      const Duration(seconds: healthCheckIntervalSec),
      (_) => _checkConnectionHealth(),
    );
  }

  /// Check health of all managed connections
  Future<void> _checkConnectionHealth() async {
    for (final target in _connections.keys) {
      final connection = _connections[target]!;

      if (connection.status != ConnectionStatus.connected) continue;

      try {
        final status = await _plugin.getPrinterStatus(
          connection.config.printerType,
        );

        connection.lastHealthCheck = DateTime.now();
        connection.lastStatus = status;

        // Check if printer is actually ready
        if (!status.isReady) {
          debugPrint('⚠️  Printer $target not ready: $status');

          if (!status.isOnline) {
            // Printer went offline - trigger reconnect
            connection.status = ConnectionStatus.disconnected;
            _notifyStatusChange(target, ConnectionStatus.disconnected);

            if (connection.enableAutoReconnect) {
              _scheduleReconnect(target);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Health check failed for $target: $e');

        // Connection lost - trigger reconnect
        connection.status = ConnectionStatus.disconnected;
        connection.lastError = e.toString();
        _notifyStatusChange(
          target,
          ConnectionStatus.disconnected,
          error: e.toString(),
        );

        if (connection.enableAutoReconnect) {
          _scheduleReconnect(target);
        }
      }
    }
  }

  /// Notify status change
  void _notifyStatusChange(
    String target,
    ConnectionStatus status, {
    String? error,
  }) {
    final connection = _connections[target];
    if (connection == null) return;

    _statusController.add(
      ConnectionStatusChange(
        target: target,
        printerName: connection.config.target,
        status: status,
        error: error,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Get connection status
  ConnectionStatus? getStatus(String target) {
    return _connections[target]?.status;
  }

  /// Get all managed connections
  List<ManagedConnection> getManagedConnections() {
    return _connections.values.toList();
  }

  /// Manual reconnect trigger
  Future<void> reconnect(String target) async {
    final connection = _connections[target];
    if (connection == null) {
      throw PrinterException('Connection not managed: $target');
    }

    // Cancel any pending automatic reconnect
    _reconnectTimers[target]?.cancel();

    // Reset attempt count for manual reconnect
    connection.attemptCount = 0;

    await _connect(target);
  }

  /// Dispose
  void dispose() {
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }
    _reconnectTimers.clear();
    _statusController.close();
  }
}

/// Managed connection
class ManagedConnection {
  final String target;
  final PrinterConfig config;
  final bool enableAutoReconnect;

  ConnectionStatus status = ConnectionStatus.disconnected;
  int attemptCount = 0;
  DateTime? lastAttempt;
  DateTime? connectedAt;
  DateTime? lastHealthCheck;
  PrinterStatus? lastStatus;
  String? lastError;

  ManagedConnection({
    required this.target,
    required this.config,
    required this.enableAutoReconnect,
  });

  Duration? get uptime {
    if (connectedAt == null || status != ConnectionStatus.connected) {
      return null;
    }
    return DateTime.now().difference(connectedAt!);
  }

  bool get isHealthy {
    return status == ConnectionStatus.connected && lastStatus?.isReady == true;
  }
}

/// Connection status
enum ConnectionStatus { disconnected, connecting, connected, failed }

/// Connection status change event
class ConnectionStatusChange {
  final String target;
  final String printerName;
  final ConnectionStatus status;
  final String? error;
  final DateTime timestamp;

  ConnectionStatusChange({
    required this.target,
    required this.printerName,
    required this.status,
    this.error,
    required this.timestamp,
  });

  @override
  String toString() => 'ConnectionStatusChange($printerName: ${status.name})';
}
