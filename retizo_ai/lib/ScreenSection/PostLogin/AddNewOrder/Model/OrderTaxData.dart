// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class OrderTaxData {
  int taxid;
  String name;
  String nameAr;
  String rate;
  String status;
  String appliedOn;
  String creationDatetime;
  String createdBy;
  String modificationDatetime;
  String modifiedBy;
  String orgId;
  int branchId;

  OrderTaxData({
    this.taxid = 0,
    this.name = "N/A",
    this.nameAr = "N/A",
    this.rate = "0",
    this.status = "N/A",
    this.appliedOn = "N/A",
    this.creationDatetime = "N/A",
    this.createdBy = "N/A",
    this.modificationDatetime = "N/A",
    this.modifiedBy = "N/A",
    this.orgId = "N/A",
    this.branchId = 0,
  });

  factory OrderTaxData.fromJson(Map<String, dynamic> json) {
    return OrderTaxData(
      taxid: json['taxid'] ?? 0,
      name: json['name'] ?? "N/A",
      nameAr: json['name_ar'] ?? "N/A",
      rate: json['rate'] ?? "0",
      status: json['status'] ?? "N/A",
      appliedOn: json['appliedon'] ?? "N/A",
      creationDatetime: json['creation_datetime'] ?? "N/A",
      createdBy: json['created_by'] ?? "N/A",
      modificationDatetime: json['modification_datetime'] ?? "N/A",
      modifiedBy: json['modified_by'] ?? "N/A",
      orgId: json['org_id'] ?? "N/A",
      branchId: json['branch_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxid': taxid,
      'name': name,
      'name_ar': nameAr,
      'rate': rate,
      'status': status,
      'appliedon': appliedOn,
      'creation_datetime': creationDatetime,
      'created_by': createdBy,
      'modification_datetime': modificationDatetime,
      'modified_by': modifiedBy,
      'org_id': orgId,
      'branch_id': branchId,
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
