// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class OrderChargesData {
  bool success;
  List<OrderChargesDataItem> data;

  OrderChargesData({this.success = false, List<OrderChargesDataItem>? data})
    : data = data ?? [];

  factory OrderChargesData.fromJson(Map<String, dynamic> json) {
    return OrderChargesData(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? List<OrderChargesDataItem>.from(
              (json['data'] as List).map(
                (e) => OrderChargesDataItem.fromJson(e),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.map((e) => e.toJson()).toList()};
  }
}

//-------------------- DataItem --------------------//
class OrderChargesDataItem {
  int chargeId;
  String name;
  String nameAr;
  String type;
  int openvalue;
  String value;
  String orderType;
  int taxGId;
  String branches;
  int applySubtotal;
  String status;
  String createdBy;
  String modifiedBy;
  String orgId;
  int branchId;
  String creationDatetime;
  String modificationDatetime;

  OrderChargesDataItem({
    this.chargeId = 0,
    this.name = 'N/A',
    this.nameAr = 'N/A',
    this.type = 'N/A',
    this.openvalue = 0,
    this.value = '0',
    this.orderType = 'N/A',
    this.taxGId = 0,
    this.branches = 'N/A',
    this.applySubtotal = 0,
    this.status = 'N/A',
    this.createdBy = 'N/A',
    this.modifiedBy = 'N/A',
    this.orgId = 'N/A',
    this.branchId = 0,
    this.creationDatetime = '',
    this.modificationDatetime = '',
  });

  factory OrderChargesDataItem.fromJson(Map<String, dynamic> json) {
    return OrderChargesDataItem(
      chargeId: json['charge_id'] ?? 0,
      name: json['name'] ?? 'N/A',
      nameAr: json['name_ar'] ?? 'N/A',
      type: json['type'] ?? 'N/A',
      openvalue: json['openvalue'] ?? 0,
      value: json['value']?.toString() ?? '0',
      orderType: json['order_type'] ?? 'N/A',
      taxGId: json['tax_g_id'] ?? 0,
      branches: json['branches'] ?? 'N/A',
      applySubtotal: json['apply_subtotal'] ?? 0,
      status: json['status'] ?? 'N/A',
      createdBy: json['created_by'] ?? 'N/A',
      modifiedBy: json['modified_by'] ?? 'N/A',
      orgId: json['org_id'] ?? 'N/A',
      branchId: json['branch_id'] ?? 0,
      creationDatetime: json['creation_datetime'] ?? '',
      modificationDatetime: json['modification_datetime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charge_id': chargeId,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'openvalue': openvalue,
      'value': value,
      'order_type': orderType,
      'tax_g_id': taxGId,
      'branches': branches,
      'apply_subtotal': applySubtotal,
      'status': status,
      'created_by': createdBy,
      'modified_by': modifiedBy,
      'org_id': orgId,
      'branch_id': branchId,
      'creation_datetime': creationDatetime,
      'modification_datetime': modificationDatetime,
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
