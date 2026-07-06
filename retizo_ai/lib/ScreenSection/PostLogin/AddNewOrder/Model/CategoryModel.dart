// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';

//-✅---------------------------------------------------------------------✅-//

class CategoryModel {
  final int? mCatId;
  final String mCatName;
  final String mCatArbName;
  final String mCatIcon;
  final String status;
  final String brandid;
  final String creationDatetime;
  final String createdBy;
  final String modificationDatetime;
  final String modifiedBy;
  final String orgId;
  final int? branchId;

  CategoryModel({
    this.mCatId,
    required this.mCatName,
    required this.mCatArbName,
    required this.mCatIcon,
    required this.status,
    required this.brandid,
    required this.creationDatetime,
    required this.createdBy,
    required this.modificationDatetime,
    required this.modifiedBy,
    required this.orgId,
    this.branchId,
  });

  /// ✅ Helper method for clean string validation
  static String _validateString(dynamic value, {bool isImage = false}) {
    if (value == null) return isImage ? GlobalServiceURL.noImage : "N/A";

    final str = value.toString().trim();
    if (str.isEmpty) return isImage ? GlobalServiceURL.noImage : "N/A";

    return str;
  }

  /// ✅ Factory constructor for JSON parsing
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      mCatId: json['m_cat_id'] is int
          ? json['m_cat_id']
          : int.tryParse(json['m_cat_id']?.toString() ?? ''),
      mCatName: _validateString(json['m_cat_name']),
      mCatArbName: _validateString(json['m_cat_arb_name']),
      mCatIcon: _validateString(json['m_cat_icon'], isImage: true),
      status: _validateString(json['status']),
      brandid: _validateString(json['brand_id']),
      creationDatetime: _validateString(json['creation_datetime']),
      createdBy: _validateString(json['created_by']),
      modificationDatetime: _validateString(json['modification_datetime']),
      modifiedBy: _validateString(json['modified_by']),
      orgId: _validateString(json['org_id']),
      branchId: json['branch_id'] is int
          ? json['branch_id']
          : int.tryParse(json['branch_id']?.toString() ?? ''),
    );
  }

  /// ✅ Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'm_cat_id': mCatId,
      'm_cat_name': mCatName,
      'm_cat_arb_name': mCatArbName,
      'm_cat_icon': mCatIcon,
      'status': status,
      'brand_id': brandid,
      'creation_datetime': creationDatetime,
      'created_by': createdBy,
      'modification_datetime': modificationDatetime,
      'modified_by': modifiedBy,
      'org_id': orgId,
      'branch_id': branchId,
    };
  }

  /// ✅ Optional - safe display name helper
  String get displayName => mCatName != "N/A" ? mCatName : "N/A";
}

//-✅---------------------------------------------------------------------✅-//
