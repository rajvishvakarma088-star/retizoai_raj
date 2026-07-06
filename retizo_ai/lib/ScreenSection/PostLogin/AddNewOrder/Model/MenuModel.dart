// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class MenuModel {
  int? mProdId;
  String? mPName;
  String? mPArbName;
  String? mProductIcon;
  bool? stockProduct;
  String? pricingMethod;
  String? price;
  String? taxGroup;
  String? costingMethod;
  String? costPrice;
  String? sellingMethod;
  String? status;
  String? creationDatetime;
  String? createdBy;
  String? modificationDatetime;
  String? modifiedBy;
  int? mCatId;
  String? orgId;
  int? branchId;
  int? dishPrepTime; // new
  int? stationId; // new

  MenuModel({
    this.mProdId,
    this.mPName,
    this.mPArbName,
    this.mProductIcon,
    this.stockProduct,
    this.pricingMethod,
    this.price,
    this.taxGroup,
    this.costingMethod,
    this.costPrice,
    this.sellingMethod,
    this.status,
    this.creationDatetime,
    this.createdBy,
    this.modificationDatetime,
    this.modifiedBy,
    this.mCatId,
    this.orgId,
    this.branchId,
    this.dishPrepTime,
    this.stationId,
  });

  /// 🔹 Null-safe JSON parsing
  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      mProdId: json['m_prod_id'] as int?,
      mPName: json['m_p_name'] as String?,
      mPArbName: json['m_p_arb_name'] as String?,
      mProductIcon: json['m_product_icon'] as String?,
      stockProduct: json['stock_product'] is bool
          ? json['stock_product'] as bool
          : (json['stock_product'] != null
                ? json['stock_product'].toString().toLowerCase() == 'true'
                : null),
      pricingMethod: json['pricing_method'] as String?,
      price: json['price']?.toString(),
      taxGroup: json['tax_group'] as String?,
      costingMethod: json['costing_method'] as String?,
      costPrice: json['cost_price']?.toString(),
      sellingMethod: json['selling_method'] as String?,
      status: json['status'] as String?,
      creationDatetime: json['creation_datetime'] as String?,
      createdBy: json['created_by']?.toString(),
      modificationDatetime: json['modification_datetime'] as String?,
      modifiedBy: json['modified_by']?.toString(),
      mCatId: json['m_cat_id'] as int?,
      orgId: json['org_id'] as String?,
      branchId: json['branch_id'] as int?,
      dishPrepTime: json['dish_prep_time'] as int?,
      // new
      stationId: json['station_id'] as int?, // new
    );
  }

  /// 🔹 Null-safe JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'm_prod_id': mProdId,
      'm_p_name': mPName,
      'm_p_arb_name': mPArbName,
      'm_product_icon': mProductIcon,
      'stock_product': stockProduct,
      'pricing_method': pricingMethod,
      'price': price,
      'tax_group': taxGroup,
      'costing_method': costingMethod,
      'cost_price': costPrice,
      'selling_method': sellingMethod,
      'status': status,
      'creation_datetime': creationDatetime,
      'created_by': createdBy,
      'modification_datetime': modificationDatetime,
      'modified_by': modifiedBy,
      'm_cat_id': mCatId,
      'org_id': orgId,
      'branch_id': branchId,
      'dish_prep_time': dishPrepTime, // new
      'station_id': stationId, // new
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
