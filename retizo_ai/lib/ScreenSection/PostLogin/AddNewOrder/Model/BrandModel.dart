// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//

class BrandModel {
  final int brandId;
  final String brandName;
  final String orgId;
  final int branchId;

  BrandModel({
    this.brandId = 0,
    this.brandName = "N/A",
    this.orgId = "N/A",
    this.branchId = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      brandId: json['brand_id'] != null
          ? int.tryParse(json['brand_id'].toString()) ?? 0
          : 0,

      brandName: (json['brand_name']?.toString().trim().isNotEmpty ?? false)
          ? json['brand_name'].toString()
          : "N/A",

      orgId: (json['org_id']?.toString().trim().isNotEmpty ?? false)
          ? json['org_id'].toString()
          : "N/A",

      branchId: json['branch_id'] != null
          ? int.tryParse(json['branch_id'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'brand_id': brandId,
    'brand_name': brandName,
    'org_id': orgId,
    'branch_id': branchId,
  };
}

//-✅---------------------------------------------------------------------✅-//
