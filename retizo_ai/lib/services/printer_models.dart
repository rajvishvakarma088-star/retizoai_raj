/// Epson Printer Models and Data Structures
///
/// This file contains all data models for printer operations

/// Discovered printer device
class PrinterDevice {
  final String deviceName;
  final String target; // Connection string (e.g., "TCP:192.168.1.100")
  final String? ipAddress;
  final String? macAddress;
  final String? bdAddress; // Bluetooth address
  final String deviceType; // "TCP", "Bluetooth", "USB"

  PrinterDevice({
    required this.deviceName,
    required this.target,
    this.ipAddress,
    this.macAddress,
    this.bdAddress,
    required this.deviceType,
  });

  factory PrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return PrinterDevice(
      deviceName: map['deviceName'] ?? 'Unknown',
      target: map['target'] ?? '',
      ipAddress: map['ipAddress'],
      macAddress: map['macAddress'],
      bdAddress: map['bdAddress'],
      deviceType: map['deviceType'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'target': target,
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'bdAddress': bdAddress,
      'deviceType': deviceType,
    };
  }

  @override
  String toString() => 'PrinterDevice($deviceName, $target, $deviceType)';
}

/// Printer status information
class PrinterStatus {
  final String printerType; // "regular" or "kds"
  final int connection;
  final int online;
  final int coverOpen;
  final int paper;
  final int paperFeed;
  final int errorStatus;
  final int? adapter;
  final int? batteryLevel;

  PrinterStatus({
    required this.printerType,
    required this.connection,
    required this.online,
    required this.coverOpen,
    required this.paper,
    required this.paperFeed,
    required this.errorStatus,
    this.adapter,
    this.batteryLevel,
  });

  factory PrinterStatus.fromMap(Map<dynamic, dynamic> map) {
    return PrinterStatus(
      printerType: map['printerType'] ?? 'regular',
      connection: map['connection'] ?? 0,
      online: map['online'] ?? 0,
      coverOpen: map['coverOpen'] ?? 0,
      paper: map['paper'] ?? 0,
      paperFeed: map['paperFeed'] ?? 0,
      errorStatus: map['errorStatus'] ?? 0,
      adapter: map['adapter'],
      batteryLevel: map['batteryLevel'],
    );
  }

  bool get isOnline => online == 0;
  bool get isCoverClosed => coverOpen == 0;
  bool get hasPaper => paper == 0;
  bool get hasError => errorStatus != 0;
  bool get isReady => isOnline && isCoverClosed && hasPaper && !hasError;

  @override
  String toString() =>
      'PrinterStatus(online: $isOnline, paper: $hasPaper, error: $hasError)';
}

/// Print job data for receipts
class PrintJob {
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? vatNumber;
  final String? branchName;
  final String orderNumber;
  final String? invoiceNumber;
  final String? tableNumber;
  final String? orderType;
  final String date;
  final String time;
  final String? customerName;
  final List<PrintJobItem> items;
  final double netAmount;
  final double tax;
  final double taxRate;
  final double discount;
  final double
  adjustmentAmount; // order-level adjustment (positive=addition, negative=deduction)
  final double total;
  final double
  totalPaidAmount; // already paid in partial payments (0 if full payment)
  final double paidAmount; // amount paid for this printed receipt
  final double tableCharge; // premium/minimum table charge applied to receipt
  final double refundAmount; // refund issued (informational only, does not reduce grand total)
  final String? paymentMethod;
  final String? paymentStatus;
  final String? qrCodeData;
  final String? barcode;
  final String? logoBase64; // base64-encoded org logo image for receipt header
  final bool openDrawer;
  final Map<String, double>? taxBreakdown;
  final List<Map<String, dynamic>>? paymentDistribution;

  PrintJob({
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    this.vatNumber,
    this.branchName,
    required this.orderNumber,
    this.invoiceNumber,
    this.tableNumber,
    this.orderType,
    required this.date,
    required this.time,
    this.customerName,
    required this.items,
    required this.netAmount,
    required this.tax,
    this.taxRate = 15.0,
    this.discount = 0.0,
    this.adjustmentAmount = 0.0,
    required this.total,
    this.totalPaidAmount = 0.0,
    this.paidAmount = 0.0,
    this.tableCharge = 0.0,
    this.refundAmount = 0.0,
    this.paymentMethod,
    this.paymentStatus,
    this.qrCodeData,
    this.barcode,
    this.logoBase64,
    this.openDrawer = false,
    this.taxBreakdown,
    this.paymentDistribution,
  });

  // Legacy compatibility - Calculate subtotal from netAmount if not provided
  double get subtotal => netAmount + tax - discount;

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'vatNumber': vatNumber,
      'branchName': branchName,
      'orderNumber': orderNumber,
      'invoiceNumber': invoiceNumber,
      'tableNumber': tableNumber,
      'orderType': orderType,
      'date': date,
      'time': time,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'netAmount': netAmount,
      'tax': tax,
      'taxRate': taxRate,
      'discount': discount,
      'adjustmentAmount': adjustmentAmount,
      'total': total,
      'totalPaidAmount': totalPaidAmount,
      'paidAmount': paidAmount,
      'tableCharge': tableCharge,
      'refundAmount': refundAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'qrCodeData': qrCodeData,
      'barcode': barcode,
      'logoBase64': logoBase64,
      'openDrawer': openDrawer,
      if (taxBreakdown != null) 'taxBreakdown': taxBreakdown!,
      if (paymentDistribution != null) 'paymentDistribution': paymentDistribution!,
    };
  }
}

/// Individual item in print job
class PrintJobItem {
  final String name;
  final int quantity;
  final double price;
  final String? notes;
  final List<String>? modifiers;
  final String? status;

  PrintJobItem({
    required this.name,
    required this.quantity,
    required this.price,
    String? notes,
    this.modifiers,
    this.status,
  }) : this.notes = (() {
          if (notes == null) return null;
          final cleanNote = notes.trim().toLowerCase();
          var cleanName = name.trim().toLowerCase();

          // Strip leading "+" (e.g. "+ burger")
          if (cleanName.startsWith('+')) {
            cleanName = cleanName.substring(1).trim();
          }
          // Strip leading index number (e.g. "1. burger")
          cleanName = cleanName.replaceFirst(RegExp(r'^\d+\.\s*'), '');

          if (cleanNote.isEmpty || cleanNote == 'n/a' || cleanNote == cleanName) {
            return null;
          }
          return notes;
        })();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'modifiers': modifiers,
      'status': status,
    };
  }
}

/// KDS print job data
class KDSPrintJob {
  final String storeName;
  final String orderNumber;
  final String tableNumber;
  final String orderType;
  final String time;
  final String? date; // dd/MM/yyyy format
  final String? customerName; // null means GUEST on Kotlin side
  final List<PrintJobItem> items;
  final String? priority; // "high", "normal", "low"
  final int jobNumber; // For tracking on KDS printer
  final String?
  orderNotes; // Whole-order special instructions (order_des from backend)

  KDSPrintJob({
    required this.storeName,
    required this.orderNumber,
    required this.tableNumber,
    required this.orderType,
    required this.time,
    this.date,
    this.customerName,
    required this.items,
    this.priority,
    required this.jobNumber,
    this.orderNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'orderNumber': orderNumber,
      'tableNumber': tableNumber,
      'orderType': orderType,
      'time': time,
      'date': date,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'priority': priority,
      'orderNotes': orderNotes,
    };
  }
}

/// Printer configuration
class PrinterConfig {
  final String target;
  final String printerType; // "regular" or "kds"
  final String series; // e.g., "TM_M30", "TM_T88VII", "TM_L100"
  final String lang; // e.g., "MODEL_ANK", "MODEL_JAPANESE"

  PrinterConfig({
    required this.target,
    this.printerType = 'regular',
    this.series = 'TM_M30III',
    this.lang = 'MODEL_ANK',
  });

  Map<String, dynamic> toMap() {
    return {
      'target': target,
      'printerType': printerType,
      'series': series,
      'lang': lang,
    };
  }
}

/// Print result
class PrintResult {
  final bool success;
  final String? message;
  final String? error;
  final int? errorCode;
  final String? printJobId;
  final int? jobNumber;
  final PrinterStatus? status;

  PrintResult({
    required this.success,
    this.message,
    this.error,
    this.errorCode,
    this.printJobId,
    this.jobNumber,
    this.status,
  });

  factory PrintResult.fromMap(Map<dynamic, dynamic> map) {
    return PrintResult(
      success: map['success'] ?? false,
      message: map['message'],
      error: map['error'],
      errorCode: map['errorCode'],
      printJobId: map['printJobId'],
      jobNumber: map['jobNumber'],
      status: map['status'] != null
          ? PrinterStatus.fromMap(map['status'])
          : null,
    );
  }

  @override
  String toString() =>
      'PrintResult(success: $success, message: $message, error: $error)';
}

/// Supported printer model info
class PrinterModel {
  final String name;
  final String series;
  final String type;

  PrinterModel({required this.name, required this.series, required this.type});

  factory PrinterModel.fromMap(Map<dynamic, dynamic> map) {
    return PrinterModel(
      name: map['name'] ?? '',
      series: map['series'] ?? '',
      type: map['type'] ?? '',
    );
  }
}
