// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
//-✅---------------------------------------------------------------------✅-//
class FilterOrderModel {
  bool success;
  List<FilterOrderData> data;
  int count;
  String date;
  String stationId;

  FilterOrderModel({
    required this.success,
    required this.data,
    required this.count,
    required this.date,
    required this.stationId,
  });

  factory FilterOrderModel.fromJson(Map<String, dynamic> json) {
    return FilterOrderModel(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((v) => FilterOrderData.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      date: json['date'] ?? '',
      stationId: json['station_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((v) => v.toJson()).toList(),
      'count': count,
      'date': date,
      'station_id': stationId,
    };
  }
}

class FilterOrderData {
  int orderId;
  String tableId; // ✅ String (API returns "8", not 8)
  String orderDate;
  String type;
  String priority;
  String customerName;
  String orderStatus;
  String? orderNo; // ✅ Added: order number / display ref
  String? tableName; // ✅ Added: table name for display
  String? orderDes; // ✅ Added: order description / notes
  List<Items> items;

  FilterOrderData({
    required this.orderId,
    required this.tableId,
    required this.orderDate,
    required this.type,
    required this.priority,
    required this.customerName,
    required this.orderStatus,
    this.orderNo,
    this.tableName,
    this.orderDes,
    required this.items,
  });

  factory FilterOrderData.fromJson(Map<String, dynamic> json) {
    return FilterOrderData(
      orderId: json['order_id'] ?? 0,
      tableId: (json['table_id'] ?? '').toString(), // ✅ safe String conversion
      orderDate: json['order_date'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? '',
      customerName: json['customer_name'] ?? '',
      orderStatus: json['order_status'] ?? '',
      orderNo: json['order_no']?.toString(),
      tableName: json['table_name']?.toString(),
      orderDes: json['order_des']?.toString(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((v) => Items.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'table_id': tableId,
      'order_date': orderDate,
      'type': type,
      'priority': priority,
      'customer_name': customerName,
      'order_status': orderStatus,
      if (orderNo != null) 'order_no': orderNo,
      if (tableName != null) 'table_name': tableName,
      if (orderDes != null) 'order_des': orderDes,
      'items': items.map((v) => v.toJson()).toList(),
    };
  }
}

class Items {
  int detailId;
  String name;
  String? nameArb; // ✅ Arabic product name (bilingual)
  int quantity;
  String status;
  int stationId;
  int prepTime;
  String? startPrep; // ✅ Nullable — null when prep not yet started
  String? endPrep; // ✅ Nullable — null when prep not yet finished
  String? prepTimeValue; // ✅ Nullable — null when not yet recorded
  String note;
  String rate;
  int mProdId;
  String? type; // ✅ "product" or "modifier"
  int? link; // ✅ parent item ID (for modifier items)
  List<ModifierItem>? modifiers; // ✅ addon / sub-items

  Items({
    required this.detailId,
    required this.name,
    this.nameArb,
    required this.quantity,
    required this.status,
    required this.stationId,
    required this.prepTime,
    this.startPrep,
    this.endPrep,
    this.prepTimeValue,
    required this.note,
    required this.rate,
    required this.mProdId,
    this.type,
    this.link,
    this.modifiers,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      detailId: json['detail_id'] ?? 0,
      name: json['name'] ?? '',
      nameArb: json['name_arb']?.toString(),
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? '',
      stationId: json['station_id'] ?? 0,
      prepTime: json['prep_time'] ?? 0,
      startPrep: json['start_prep']?.toString(),
      endPrep: json['end_prep']?.toString(),
      prepTimeValue: json['prep_time_value']?.toString(),
      note: json['note'] ?? '',
      rate: json['rate'] ?? '',
      mProdId: json['m_prod_id'] ?? 0,
      type: json['type']?.toString(),
      link: json['link'] is int ? json['link'] : null,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((v) => ModifierItem.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'name': name,
      if (nameArb != null) 'name_arb': nameArb,
      'quantity': quantity,
      'status': status,
      'station_id': stationId,
      'prep_time': prepTime,
      'start_prep': startPrep,
      'end_prep': endPrep,
      'prep_time_value': prepTimeValue,
      'note': note,
      'rate': rate,
      'm_prod_id': mProdId,
      if (type != null) 'type': type,
      if (link != null) 'link': link,
      if (modifiers != null)
        'modifiers': modifiers!.map((v) => v.toJson()).toList(),
    };
  }
}

//-✅--ModifierItem-----------------------------------------------------✅-//
/// Represents an addon / modifier item that belongs to a parent [Items].
/// The relationship is identified by [link] (parent detail_id) and [type] == "modifier".
class ModifierItem {
  int detailId;
  String name;
  String? nameArb;
  int quantity;
  String status;
  int stationId;
  int prepTime;
  String? startPrep;
  String? endPrep;
  String? prepTimeValue;
  String note;
  String rate;
  int mProdId;
  String? type;
  int? link; // parent item's detail_id

  ModifierItem({
    required this.detailId,
    required this.name,
    this.nameArb,
    required this.quantity,
    required this.status,
    required this.stationId,
    required this.prepTime,
    this.startPrep,
    this.endPrep,
    this.prepTimeValue,
    required this.note,
    required this.rate,
    required this.mProdId,
    this.type,
    this.link,
  });

  factory ModifierItem.fromJson(Map<String, dynamic> json) {
    return ModifierItem(
      detailId: json['detail_id'] ?? 0,
      name: json['name'] ?? '',
      nameArb: json['name_arb']?.toString(),
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? '',
      stationId: json['station_id'] ?? 0,
      prepTime: json['prep_time'] ?? 0,
      startPrep: json['start_prep']?.toString(),
      endPrep: json['end_prep']?.toString(),
      prepTimeValue: json['prep_time_value']?.toString(),
      note: json['note'] ?? '',
      rate: json['rate'] ?? '',
      mProdId: json['m_prod_id'] ?? 0,
      type: json['type']?.toString(),
      link: json['link'] is int ? json['link'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'name': name,
      if (nameArb != null) 'name_arb': nameArb,
      'quantity': quantity,
      'status': status,
      'station_id': stationId,
      'prep_time': prepTime,
      'start_prep': startPrep,
      'end_prep': endPrep,
      'prep_time_value': prepTimeValue,
      'note': note,
      'rate': rate,
      'm_prod_id': mProdId,
      if (type != null) 'type': type,
      if (link != null) 'link': link,
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
