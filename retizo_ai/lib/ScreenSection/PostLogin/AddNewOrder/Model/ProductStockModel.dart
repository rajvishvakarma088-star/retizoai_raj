// ignore_for_file: file_names, non_constant_identifier_names

//-✅---------------------------------------------------------------------✅-//
// Response model for POST /order-master/products-stock
// Response shape:
// {
//   "success": true,
//   "data": {
//     "3": { "stock_in": 10, "stock_out": 5, "available": 5, "product_name": "Product 3" }
//   },
//   "count": 1
// }
//-✅---------------------------------------------------------------------✅-//

class ProductStockData {
  final int stockIn;
  final int stockOut;
  final int available;
  final String productName;

  ProductStockData({
    required this.stockIn,
    required this.stockOut,
    required this.available,
    required this.productName,
  });

  factory ProductStockData.fromJson(Map<String, dynamic> json) {
    return ProductStockData(
      stockIn: (json['stock_in'] as num?)?.toInt() ?? 0,
      stockOut: (json['stock_out'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? '',
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
// Response model for POST /order-master/check-stock
// Response shape:
// {
//   "success": true,
//   "can_place_order": false,
//   "stock_issues": [
//     { "product_id": 3, "product_name": "...", "requested": 2, "available": 1 }
//   ],
//   "issues_count": 1,
//   "message": "..."
// }
//-✅---------------------------------------------------------------------✅-//

class CheckStockIssue {
  final int productId;
  final String productName;
  final int requested;
  final int available;

  CheckStockIssue({
    required this.productId,
    required this.productName,
    required this.requested,
    required this.available,
  });

  factory CheckStockIssue.fromJson(Map<String, dynamic> json) {
    return CheckStockIssue(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      requested: (json['requested'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
    );
  }
}

class CheckStockResponse {
  final bool success;
  final bool canPlaceOrder;
  final List<CheckStockIssue> stockIssues;
  final int issuesCount;
  final String message;

  CheckStockResponse({
    required this.success,
    required this.canPlaceOrder,
    required this.stockIssues,
    required this.issuesCount,
    required this.message,
  });

  factory CheckStockResponse.fromJson(Map<String, dynamic> json) {
    final issuesList = (json['stock_issues'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => CheckStockIssue.fromJson(e))
        .toList();

    return CheckStockResponse(
      success: json['success'] as bool? ?? false,
      canPlaceOrder: json['can_place_order'] as bool? ?? true,
      stockIssues: issuesList,
      issuesCount: (json['issues_count'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
// Response model for POST /order-master/products-info
// Response shape:
// {
//   "success": true,
//   "data": {
//     "3": {
//       "m_p_name": "Product 3",
//       "price": 0,
//       "send_to_kds": "YES",
//       "dish_prep_time": 5,
//       "station_id": null
//     }
//   },
//   "count": 1
// }
//-✅---------------------------------------------------------------------✅-//

class ProductInfoData {
  final String mPName;
  final double price;
  final bool sendToKds;
  final int? dishPrepTime;
  final int? stationId;

  ProductInfoData({
    required this.mPName,
    required this.price,
    required this.sendToKds,
    this.dishPrepTime,
    this.stationId,
  });

  factory ProductInfoData.fromJson(Map<String, dynamic> json) {
    return ProductInfoData(
      mPName: json['m_p_name']?.toString() ?? '',
      // ✅ FIXED: price may arrive as String "10.00" or num — handle both
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      sendToKds:
          (json['send_to_kds']?.toString() ?? 'NO').toUpperCase() == 'YES',
      // ✅ FIXED: dish_prep_time may be null — safe parse
      dishPrepTime: json['dish_prep_time'] == null
          ? null
          : int.tryParse(json['dish_prep_time'].toString()),
      stationId: json['station_id'] == null
          ? null
          : int.tryParse(json['station_id'].toString()),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
