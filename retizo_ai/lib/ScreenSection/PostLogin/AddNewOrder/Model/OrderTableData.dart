// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//

class OrderTableData {
  final int tableID;
  final String tableName;
  final int seatingCapacity;
  final String location;
  final String status;
  final String orgId;
  final int branchId;

  // ✅ Pricing / premium fields from API
  final String?
  chargeable; // "YES" = premium/chargeable, "NO" or null = standard
  final String? minimumSpend;
  final String? tableCharge;
  final String? includingTax;

  // ✅ Occupancy status - shows if table has an active order
  final bool isOccupied;

  // ✅ Occupied table order details (from API when table is occupied)
  final String? occupiedOrderId; // Order ID/Number
  final String? occupiedOrderNumber; // Display order number
  final String? occupiedCustomer; // Customer name
  final String? occupiedOrderStatus; // Order status (preparing, ordered, etc.)

  // Optional dropdown fields (if needed in UI)
  String? selectedDropDownOne;
  String? selectedDropDownTwo;

  OrderTableData({
    int? tableID,
    String? tableName,
    int? seatingCapacity,
    String? location,
    String? status,
    String? orgId,
    int? branchId,
    this.chargeable,
    this.minimumSpend,
    this.tableCharge,
    this.includingTax,
    bool? isOccupied,
    this.occupiedOrderId,
    this.occupiedOrderNumber,
    this.occupiedCustomer,
    this.occupiedOrderStatus,
    this.selectedDropDownOne,
    this.selectedDropDownTwo,
  }) : tableID = tableID ?? 0,
       tableName = tableName?.isNotEmpty == true ? tableName! : 'N/A',
       seatingCapacity = seatingCapacity ?? 0,
       location = location?.isNotEmpty == true ? location! : 'N/A',
       status = status?.isNotEmpty == true ? status! : 'N/A',
       orgId = orgId?.isNotEmpty == true ? orgId! : 'N/A',
       branchId = branchId ?? 0,
       isOccupied = isOccupied ?? false;

  factory OrderTableData.fromJson(Map<String, dynamic> json) {
    // ✅ Check occupancy from multiple possible sources:
    // 1. 'is_occupied' from tableWithStatus endpoint (preferred)
    // 2. 'occupied' boolean field (injected by old manual approach)
    // 3. If neither present, check if status == "occupied"
    bool occupied = false;

    if (json['is_occupied'] != null) {
      // From tableWithStatus endpoint
      occupied =
          json['is_occupied'] == true ||
          json['is_occupied'].toString().toLowerCase() == 'true';
    } else if (json['occupied'] != null) {
      // Explicit occupied field (old manual approach)
      occupied =
          json['occupied'] == true ||
          json['occupied'].toString().toLowerCase() == 'true';
    } else if (json['status'] != null) {
      // Fallback: check status field, but ONLY accept "occupied"
      final statusLower = json['status'].toString().toLowerCase();
      occupied = statusLower == 'occupied';
    }

    // ✅ Extract order details if table is occupied
    String? orderIdStr;
    String? orderNumStr;
    String? customerStr;
    String? orderStatusStr;

    if (occupied &&
        json['orders'] != null &&
        json['orders'] is List &&
        (json['orders'] as List).isNotEmpty) {
      // NEW FORMAT: tableWithStatus endpoint returns 'orders' array
      final firstOrder = (json['orders'] as List).first as Map<String, dynamic>;
      orderIdStr = firstOrder['order_id']?.toString();
      orderNumStr =
          firstOrder['order_no']?.toString() ??
          firstOrder['order_number']?.toString();
      customerStr = firstOrder['customer']?['cust_name']?.toString() ?? 'Guest';
      orderStatusStr =
          firstOrder['order_status']?.toString() ??
          firstOrder['status']?.toString();
    } else if (occupied && json['active_order'] != null) {
      // OLD FORMAT: manually injected 'active_order' map
      final activeOrder = json['active_order'] as Map<String, dynamic>;
      orderIdStr = activeOrder['order_id']?.toString();
      orderNumStr =
          activeOrder['order_no']?.toString() ??
          activeOrder['order_number']?.toString();
      customerStr = activeOrder['customer_name']?.toString() ?? 'Guest';
      orderStatusStr =
          activeOrder['order_status']?.toString() ??
          activeOrder['status']?.toString();
    }

    return OrderTableData(
      tableID: json['table_ID'] is int
          ? json['table_ID']
          : int.tryParse(json['table_ID']?.toString() ?? '') ?? 0,
      tableName: json['table_name']?.toString() ?? 'N/A',
      seatingCapacity: json['seating_capacity'] is int
          ? json['seating_capacity']
          : int.tryParse(json['seating_capacity']?.toString() ?? '') ?? 0,
      location: json['location']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'N/A',
      orgId: json['org_id']?.toString() ?? 'N/A',
      branchId: json['branch_id'] is int
          ? json['branch_id']
          : int.tryParse(json['branch_id']?.toString() ?? '') ?? 0,
      chargeable: json['chargeable']?.toString(),
      minimumSpend: json['minimum_spend']?.toString(),
      tableCharge: json['table_charge']?.toString(),
      includingTax: json['including_tax']?.toString(),
      isOccupied: occupied,
      occupiedOrderId: orderIdStr,
      occupiedOrderNumber: orderNumStr,
      occupiedCustomer: customerStr,
      occupiedOrderStatus: orderStatusStr,
      selectedDropDownOne: null,
      selectedDropDownTwo: null,
    );
  }

  Map<String, dynamic> toJson() => {
    'table_ID': tableID,
    'table_name': tableName,
    'seating_capacity': seatingCapacity,
    'location': location,
    'status': status,
    'org_id': orgId,
    'branch_id': branchId,
    'chargeable': chargeable,
    'minimum_spend': minimumSpend,
    'table_charge': tableCharge,
    'including_tax': includingTax,
    'occupied': isOccupied,
    'occupied_order_id': occupiedOrderId,
    'occupied_order_number': occupiedOrderNumber,
    'occupied_customer': occupiedCustomer,
    'occupied_order_status': occupiedOrderStatus,
    'selectedDropDownOne': selectedDropDownOne,
    'selectedDropDownTwo': selectedDropDownTwo,
  };

  bool get isPremium => (chargeable ?? '').toUpperCase() == 'YES';

  double get minimumSpendAmount =>
      double.tryParse(minimumSpend?.toString() ?? '') ?? 0.0;

  double get tableChargeAmount =>
      double.tryParse(tableCharge?.toString() ?? '') ?? 0.0;
}

//-✅---------------------------------------------------------------------✅-//
