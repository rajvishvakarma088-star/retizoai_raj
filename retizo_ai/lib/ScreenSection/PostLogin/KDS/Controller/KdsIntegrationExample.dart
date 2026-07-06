// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
//
// INTEGRATION EXAMPLE: KDS Auto-Print
//
// This file shows how to integrate printer auto-print with your existing KDS flow.
// Copy the relevant sections into your KdsController.dart
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Model/KitchenOrderModel.dart';
import 'package:culai/services/printer_models.dart';

/// Example: How to add auto-print to KdsProvider
///
/// Add these methods to your existing KdsProvider class
class KdsProviderIntegrationExample {
  // Track which orders have been printed (prevents duplicate prints)
  final Set<int> _printedOrderIds = <int>{};

  /// Call this after successfully fetching kitchen orders
  ///
  /// Example in GetKitchenOrderListService:
  /// ```dart
  /// // After parsing orders:
  /// KitchenOrderListing = dataList.map(...).toList();
  ///
  /// // Add auto-print:
  /// await _autoPrintNewOrders(context);
  /// ```
  Future<void> autoPrintNewOrders(
    BuildContext context,
    List<KitchenOrderModel> orders,
  ) async {
    if (!context.mounted) return;

    final printerProvider = context.read<PrinterIntegrationProvider>();

    // Only process if auto-print is enabled
    if (!printerProvider.autoPrintEnabled) {
      return;
    }

    for (final order in orders) {
      // Skip if already printed
      if (_printedOrderIds.contains(order.orderId)) {
        continue;
      }

      // Skip if order is cancelled or completed
      final status = order.orderStatus?.toLowerCase() ?? '';
      if (status == 'cancelled' ||
          status == 'completed' ||
          status == 'served') {
        continue;
      }

      // Print the order
      final success = await _printKitchenOrder(context, order);

      if (success) {
        _printedOrderIds.add(order.orderId ?? 0);
        debugPrint('✅ Auto-printed order #${order.orderNo ?? order.orderId}');
      } else {
        debugPrint(
          '❌ Failed to auto-print order #${order.orderNo ?? order.orderId}',
        );
      }
    }
  }

  /// Print a kitchen order ticket
  Future<bool> _printKitchenOrder(
    BuildContext context,
    KitchenOrderModel order,
  ) async {
    final printerProvider = context.read<PrinterIntegrationProvider>();

    // Extract items from order details as PrintJobItem objects
    final items = <PrintJobItem>[];
    for (final detail in order.details ?? []) {
      final itemName = detail.product?.mPName ?? '';
      if (itemName.isEmpty) continue;

      // Convert modifiers to string list
      final modifiersList = detail.modifiers
          ?.map((m) => m.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      // Add main item
      items.add(
        PrintJobItem(
          name: itemName,
          quantity: detail.qty ?? 1,
          price: double.tryParse(detail.rate ?? '0') ?? 0.0,
          notes: detail.note != 'N/A' ? detail.note : null,
          modifiers: modifiersList,
        ),
      );
    }

    if (items.isEmpty) {
      return false; // Nothing to print
    }

    try {
      // Print via printer provider
      await printerProvider.printKitchenOrder(
        storeName: 'Your Restaurant Name',
        orderNumber: '${order.orderNo ?? order.orderId}',
        tableName: order.tableName ?? 'Table Unknown',
        orderType: order.type ?? 'Dine In',
        items: items,
        priority: order.priority ?? 'normal',
      );
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// Example: Print when marking order as "Ready to Serve"
  ///
  /// Add this to your "Mark Ready" button handler
  Future<void> onMarkOrderReady(
    BuildContext context,
    KitchenOrderModel order,
  ) async {
    // First, update order status in backend
    // ... your existing API call ...

    // Then print ready notification
    final printerProvider = context.read<PrinterIntegrationProvider>();

    await printerProvider.printKitchenOrder(
      storeName: 'Your Restaurant',
      orderNumber: '${order.orderNo ?? order.orderId}',
      tableName: order.tableName ?? '',
      orderType: order.type ?? 'Dine In',
      items: [
        PrintJobItem(
          name: '✓ READY TO SERVE - Order #${order.orderNo ?? order.orderId}',
          quantity: 1,
          price: 0.0,
        ),
      ],
      priority: 'urgent',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked ready and printed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Example: Print receipt when order is paid
  Future<void> onOrderPaid(
    BuildContext context,
    KitchenOrderModel order,
  ) async {
    final printerProvider = context.read<PrinterIntegrationProvider>();

    // Convert order items to print format
    final printItems = <PrintJobItem>[];
    for (final detail in order.details ?? []) {
      printItems.add(
        PrintJobItem(
          name: detail.productName ?? '',
          quantity: detail.quantity ?? 1,
          price: detail.price ?? 0.0,
          modifiers: detail.modifiers,
        ),
      );
    }

    // Calculate totals
    final subtotal = printItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    const taxRate = 0.08; // 8% tax
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    // Print receipt
    await printerProvider.printReceipt(
      storeName: 'My Restaurant', // TODO: Get from settings
      orderNumber: '${order.orderNo ?? order.orderId}',
      items: printItems,
      netAmount: subtotal,
      tax: tax,
      total: total,
      tableNumber: order.tableName,
      paymentMethod: 'Cash', // TODO: Get from your payment flow
      openDrawer: true, // Open cash drawer for cash payments
    );
  }
}

/// Example: How to add PrinterStatusWidget to KDS AppBar
/// 
/// In your Kds.dart build method:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('Kitchen Display System'),
///       actions: const [
///         PrinterStatusWidget(), // <-- Add this
///         SizedBox(width: 8),
///       ],
///     ),
///     body: // ... your existing KDS body
///   );
/// }
/// ```

/// Example: How to add manual print button to order card
/// 
/// Add this button to your KDS order card widget:
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.print),
///   onPressed: () async {
///     final printerProvider = context.read<PrinterIntegrationProvider>();
///     
///     final success = await printerProvider.printKitchenOrder(
///       orderNumber: order.orderNumber ?? '',
///       tableName: order.tableName ?? '',
///       items: order.details?.map((d) => d.productName ?? '').toList() ?? [],
///       urgent: true,
///     );
///     
///     if (context.mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Text(success ? 'Reprinted order' : 'Print failed'),
///           backgroundColor: success ? Colors.green : Colors.red,
///         ),
///       );
///     }
///   },
///   tooltip: 'Reprint Order',
/// )
/// ```

/// Example: How to initialize printers on app start
/// 
/// In your main.dart or home screen initState:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   
///   // Initialize printers after widget built
///   WidgetsBinding.instance.addPostFrameCallback((_) async {
///     if (context.mounted) {
///       final printerProvider = context.read<PrinterIntegrationProvider>();
///       await printerProvider.initializePrinters();
///     }
///   });
/// }
/// ```

/// Example: How to add printer settings to drawer/menu
/// 
/// In your app drawer or settings menu:
/// ```dart
/// ListTile(
///   leading: const Icon(Icons.print),
///   title: const Text('Printer Settings'),
///   onTap: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => const PrinterSettingsScreen(),
///       ),
///     );
///   },
/// ),
/// ListTile(
///   leading: const Icon(Icons.queue),
///   title: const Text('Print Queue'),
///   trailing: Consumer<PrinterIntegrationProvider>(
///     builder: (context, provider, _) {
///       if (provider.pendingPrintJobs == 0) {
///         return const SizedBox.shrink();
///       }
///       return CircleAvatar(
///         radius: 12,
///         backgroundColor: Colors.red,
///         child: Text(
///           provider.pendingPrintJobs.toString(),
///           style: const TextStyle(fontSize: 10, color: Colors.white),
///         ),
///       );
///     },
///   ),
///   onTap: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => const PrintQueueScreen(),
///       ),
///     );
///   },
/// ),
/// ```

/// Example: WebSocket integration for real-time printing
/// 
/// If you receive orders via WebSocket/Socket.IO:
/// ```dart
/// void setupWebSocket() {
///   socket.on('new_order', (data) {
///     // Parse order from socket data
///     final order = KitchenOrderModel.fromJson(data);
///     
///     // Add to order list
///     KitchenOrderListing.add(order);
///     notifyListeners();
///     
///     // Auto-print immediately
///     _printKitchenOrder(context, order);
///   });
/// }
/// ```

/// Example: Scheduled re-print for unfinished orders
/// 
/// Print reminder tickets for orders taking too long:
/// ```dart
/// Timer.periodic(const Duration(minutes: 15), (_) {
///   final now = DateTime.now();
///   
///   for (final order in KitchenOrderListing) {
///     final orderTime = order.createdAt ?? now;
///     final elapsed = now.difference(orderTime);
///     
///     // Orders older than 15 minutes
///     if (elapsed.inMinutes >= 15) {
///       _printKitchenOrder(context, order);
///     }
///   }
/// });
/// ```

/// Example: Error handling and user feedback
/// 
/// Show print errors to users:
/// ```dart
/// final printerProvider = context.read<PrinterIntegrationProvider>();
/// 
/// // Listen to errors
/// printerProvider.addListener(() {
///   if (printerProvider.lastError != null) {
///     showDialog(
///       context: context,
///       builder: (context) => AlertDialog(
///         title: const Text('Print Error'),
///         content: Text(printerProvider.lastError!),
///         actions: [
///           TextButton(
///             onPressed: () {
///               printerProvider.clearError();
///               Navigator.pop(context);
///             },
///             child: const Text('OK'),
///           ),
///           TextButton(
///             onPressed: () {
///               Navigator.pop(context);
///               Navigator.push(
///                 context,
///                 MaterialPageRoute(
///                   builder: (context) => const PrintQueueScreen(),
///                 ),
///               );
///             },
///             child: const Text('View Queue'),
///           ),
///         ],
///       ),
///     );
///   }
/// });
/// ```
