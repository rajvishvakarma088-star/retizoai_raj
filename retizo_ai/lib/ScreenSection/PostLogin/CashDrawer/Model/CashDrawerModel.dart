// ignore_for_file: file_names, non_constant_identifier_names
//-✅---------------------------------------------------------------------✅-//
class CashDrawerResponse {
  final bool success;
  final String? action;
  final String? message;
  final CashDrawerData? drawer;
  final List<Map<String, dynamic>> methodSummary;

  CashDrawerResponse({
    this.success = false,
    this.action,
    this.message,
    this.drawer,
    this.methodSummary = const [],
  });

  factory CashDrawerResponse.fromJson(Map<String, dynamic> json) {
    CashDrawerData? drawerData;

    if (json['drawer'] is Map<String, dynamic>) {
      drawerData = CashDrawerData.fromJson(
        json['drawer'] as Map<String, dynamic>,
      );
    } else if (json['data'] is Map<String, dynamic>) {
      drawerData = CashDrawerData.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    } else if (json['data'] is List) {
      final list = json['data'] as List;
      if (list.isNotEmpty && list.first is Map<String, dynamic>) {
        drawerData = CashDrawerData.fromJson(
          list.first as Map<String, dynamic>,
        );
      }
    } else if (json['cd_id'] != null) {
      drawerData = CashDrawerData.fromJson(json);
    }

    final List<Map<String, dynamic>> summary = [];
    if (json['methodSummary'] is List) {
      for (final item in json['methodSummary'] as List) {
        if (item is Map<String, dynamic>) summary.add(item);
      }
    }

    return CashDrawerResponse(
      success: json['success'] as bool? ?? false,
      action: json['action']?.toString(),
      message: json['message']?.toString(),
      drawer: drawerData,
      methodSummary: summary,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    if (action != null) 'action': action,
    if (message != null) 'message': message,
    if (drawer != null) 'drawer': drawer!.toJson(),
  };
}

//-✅---------------------------------------------------------------------✅-//
class CashDrawerData {
  final int? cdId;
  final String? orgId;
  final int? branchId;
  final String? pDate;
  final String? openingAmt;
  final String? cashCollected;
  final String? pettyAmtIn;
  final String? pettyAmtOut;
  final String? expectedClosingAmt;
  final String? countedClosingAmt;
  final String? closedAt;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final double? netDifference;
  final String? fromDate;
  final String? toDate;

  CashDrawerData({
    this.cdId,
    this.orgId,
    this.branchId,
    this.pDate,
    this.openingAmt,
    this.cashCollected,
    this.pettyAmtIn,
    this.pettyAmtOut,
    this.expectedClosingAmt,
    this.countedClosingAmt,
    this.closedAt,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.netDifference,
    this.fromDate,
    this.toDate,
  });

  factory CashDrawerData.fromJson(Map<String, dynamic> json) {
    return CashDrawerData(
      cdId: json['cd_id'] is int
          ? json['cd_id']
          : int.tryParse(json['cd_id']?.toString() ?? ''),
      orgId: json['org_id']?.toString(),
      branchId: json['branch_id'] is int
          ? json['branch_id']
          : int.tryParse(json['branch_id']?.toString() ?? ''),
      pDate: json['p_date']?.toString(),
      openingAmt: json['opening_amt']?.toString() ?? '0',
      cashCollected: json['cash_collected']?.toString() ?? '0',
      pettyAmtIn: json['petty_amt_in']?.toString() ?? '0',
      pettyAmtOut: json['petty_amt_out']?.toString() ?? '0',
      expectedClosingAmt: json['expected_closing_amt']?.toString(),
      countedClosingAmt: json['counted_closing_amt']?.toString() ?? '0',
      closedAt: json['closed_at']?.toString(),
      status: json['status']?.toString() ?? 'CLOSED',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      netDifference: json['net_difference'] is num
          ? (json['net_difference'] as num).toDouble()
          : double.tryParse(json['net_difference']?.toString() ?? ''),
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (cdId != null) 'cd_id': cdId,
    if (orgId != null) 'org_id': orgId,
    if (branchId != null) 'branch_id': branchId,
    if (pDate != null) 'p_date': pDate,
    'opening_amt': openingAmt,
    'cash_collected': cashCollected,
    'petty_amt_in': pettyAmtIn,
    'petty_amt_out': pettyAmtOut,
    'expected_closing_amt': expectedClosingAmt,
    'counted_closing_amt': countedClosingAmt,
    'closed_at': closedAt,
    'status': status,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  bool get isOpen => status?.toUpperCase() == 'OPEN';
  bool get isClosed => status?.toUpperCase() == 'CLOSED';
}

//-✅---------------------------------------------------------------------✅-//
