// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
//-✅---------------------------------------------------------------------✅-//
class OrderSummaryTableTypeList {
  final int orderTypeId;
  final String orderTypeName;
  final String orgId;
  final int branchId;

  OrderSummaryTableTypeList({
    required this.orderTypeId,
    required this.orderTypeName,
    required this.orgId,
    required this.branchId,
  });

  factory OrderSummaryTableTypeList.fromJson(Map<String, dynamic> json) {
    return OrderSummaryTableTypeList(
      orderTypeId: json['order_type_id'] ?? 0,
      orderTypeName: json['order_type_name'] ?? '',
      orgId: json['org_id'] ?? '',
      branchId: json['branch_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "order_type_id": orderTypeId,
    "order_type_name": orderTypeName,
    "org_id": orgId,
    "branch_id": branchId,
  };
}

//-✅---------------------------------------------------------------------✅-//
