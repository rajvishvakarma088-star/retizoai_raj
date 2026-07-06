// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
//-✅---------------------------------------------------------------------✅-//
class NotificationsListModel {
  bool success;
  List<NotificationsData> data;
  int count;
  int newItems;
  String timestamp;
  String message;

  NotificationsListModel({
    this.success = false,
    this.data = const [],
    this.count = 0,
    this.newItems = 0,
    this.timestamp = "",
    this.message = "",
  });

  factory NotificationsListModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationsListModel();
    }

    return NotificationsListModel(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((v) => NotificationsData.fromJson(v))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      newItems: json['new_items'] ?? 0,
      timestamp: json['timestamp'] ?? "",
      message: json['message'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.map((v) => v.toJson()).toList(),
    'count': count,
    'new_items': newItems,
    'timestamp': timestamp,
    'message': message,
  };
}

class NotificationsData {
  int orderId;
  int tableId;
  String customerName;
  String orderDate;
  int itemId;
  String itemName;
  int quantity;
  int stationId;
  String preparedAt;
  String orderStatus;
  String paymentStatus;
  String priority;
  String totalAmt;
  bool isPaid;

  NotificationsData({
    this.orderId = 0,
    this.tableId = 0,
    this.customerName = "",
    this.orderDate = "",
    this.itemId = 0,
    this.itemName = "",
    this.quantity = 0,
    this.stationId = 0,
    this.preparedAt = "",
    this.orderStatus = "",
    this.paymentStatus = "",
    this.priority = "",
    this.totalAmt = "0",
    this.isPaid = false,
  });

  factory NotificationsData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationsData();
    }

    return NotificationsData(
      orderId: json['order_id'] ?? 0,
      tableId: json['table_id'] ?? 0,
      customerName: json['customer_name'] ?? "",
      orderDate: json['order_date'] ?? "",
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? "",
      quantity: json['quantity'] ?? 0,
      stationId: json['station_id'] ?? 0,
      preparedAt: json['prepared_at'] ?? "",
      orderStatus: json['order_status'] ?? "",
      paymentStatus: json['payment_status'] ?? "",
      priority: json['priority'] ?? "",
      totalAmt: json['total_amt']?.toString() ?? "0",
      isPaid: json['is_paid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'table_id': tableId,
    'customer_name': customerName,
    'order_date': orderDate,
    'item_id': itemId,
    'item_name': itemName,
    'quantity': quantity,
    'station_id': stationId,
    'prepared_at': preparedAt,
    'order_status': orderStatus,
    'payment_status': paymentStatus,
    'priority': priority,
    'total_amt': totalAmt,
    'is_paid': isPaid,
  };
}

//-✅---------------------------------------------------------------------✅-//
