// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
import 'FilterOrderModel.dart'; // ✅ Import for ModifierItem class

//-✅---------------------------------------------------------------------✅-//
class KitchenOrderModel {
  int? orderId;
  String? custId;
  String? tableId;
  String? orderDate;
  String? type;
  int? pax;
  String? netAmt;
  int? taxid;
  String? taxAmt;
  String? chargeId;
  String? chargeAmt;
  String? payMId;
  String? orderStatus;
  String? discountPer;
  String? discountAmt;
  String? totalAmt;
  String? priority;
  String? orderPreparedtime;
  String? creationDatetime;
  String? createdBy;
  String? modificationDatetime;
  String? modifiedBy;
  String? orgId;
  int? branchId;
  String? customer;
  String? order_des;
  List<Details>? details;
  int? orderNo; // ✅ Display order number (kitchen endpoint)
  String? tableName; // ✅ Table display name (kitchen endpoint)
  String? customerName; // ✅ Customer name alias (kitchen endpoint)

  KitchenOrderModel({
    this.orderId,
    this.custId,
    this.tableId,
    this.orderDate,
    this.type,
    this.pax,
    this.netAmt,
    this.taxid,
    this.taxAmt,
    this.chargeId,
    this.chargeAmt,
    this.payMId,
    this.orderStatus,
    this.discountPer,
    this.discountAmt,
    this.totalAmt,
    this.priority,
    this.orderPreparedtime,
    this.creationDatetime,
    this.createdBy,
    this.modificationDatetime,
    this.modifiedBy,
    this.orgId,
    this.branchId,
    this.customer,
    this.order_des,
    this.details,
    this.orderNo,
    this.tableName,
    this.customerName,
  });

  KitchenOrderModel.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'] ?? 0;
    custId = (json['cust_id'] ?? "N/A").toString();
    tableId = (json['table_id'] ?? "N/A").toString();
    orderDate = (json['order_date'] ?? "N/A").toString();
    type = (json['type'] ?? "N/A").toString();
    pax = json['pax'] ?? 0;
    netAmt = (json['net_amt'] ?? "N/A").toString();
    taxid = json['taxid'] ?? 0;
    taxAmt = (json['tax_amt'] ?? "0").toString();
    chargeId = (json['charge_id'] ?? "N/A").toString();
    chargeAmt = (json['charge_amt'] ?? "0").toString();
    payMId = (json['pay_m_id'] ?? "N/A").toString();
    orderStatus = (json['order_status'] ?? "N/A").toString();
    discountPer = (json['discount_per'] ?? "0").toString();
    discountAmt = (json['discount_amt'] ?? "0").toString();
    totalAmt = (json['total_amt'] ?? "0").toString();
    priority = (json['priority'] ?? "N/A").toString();
    orderPreparedtime = (json['order_preparedtime'] ?? "N/A").toString();
    creationDatetime = (json['creation_datetime'] ?? "N/A").toString();
    createdBy = (json['created_by'] ?? "N/A").toString();
    modificationDatetime = (json['modification_datetime'] ?? "N/A").toString();
    modifiedBy = (json['modified_by'] ?? "N/A").toString();
    orgId = (json['org_id'] ?? "N/A").toString();
    branchId = json['branch_id'] ?? 0;
    customer = (json['Customer'] ?? "N/A").toString();
    order_des = (json['order_des'] ?? "N/A").toString();

    if (json['details'] != null) {
      details = <Details>[];
      json['details'].forEach((v) {
        details!.add(Details.fromJson(v));
      });
    }
  }

  /// Maps a single order object from the kitchen endpoint response (`data` array).
  /// The kitchen API returns `items` (not `details`) with flat item fields.
  factory KitchenOrderModel.fromKitchenJson(Map<String, dynamic> json) {
    final model = KitchenOrderModel(
      orderId: json['order_id'] ?? 0,
      orderNo: json['order_no'] != null
          ? int.tryParse(json['order_no'].toString())
          : null,
      tableId: (json['table_id'] ?? '').toString(),
      tableName: json['table_name']?.toString(),
      orderDate: json['order_date']?.toString(),
      type: (json['type'] ?? '').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      customerName: json['customer_name']?.toString(),
      customer: json['customer_name']?.toString(),
      orderStatus: (json['order_status'] ?? '').toString(),
      order_des: json['order_des']?.toString(),
    );
    if (json['items'] is List) {
      model.details = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Details.fromKitchenItem)
          .toList();
      // ✅ CRITICAL FIX: items from /kitchen/ready do NOT include order_id in each
      // item payload — only in the parent order object. Propagate it so that
      // OrderServedService / OrderPreparedService can correctly call
      // PUT /order-details/{id} with the right order context.
      for (final d in model.details!) {
        d.orderId ??= model.orderId;
      }
    }
    return model;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['order_id'] = orderId ?? 0;
    data['cust_id'] = custId ?? "N/A";
    data['table_id'] = tableId ?? "N/A";
    data['order_date'] = orderDate ?? "N/A";
    data['type'] = type ?? "N/A";
    data['pax'] = pax ?? 0;
    data['net_amt'] = netAmt ?? "N/A";
    data['taxid'] = taxid ?? 0;
    data['tax_amt'] = taxAmt ?? "0";
    data['charge_id'] = chargeId ?? "N/A";
    data['charge_amt'] = chargeAmt ?? "0";
    data['pay_m_id'] = payMId ?? "N/A";
    data['order_status'] = orderStatus ?? "N/A";
    data['discount_per'] = discountPer ?? "0";
    data['discount_amt'] = discountAmt ?? "0";
    data['total_amt'] = totalAmt ?? "0";
    data['priority'] = priority ?? "N/A";
    data['order_preparedtime'] = orderPreparedtime ?? "N/A";
    data['creation_datetime'] = creationDatetime ?? "N/A";
    data['created_by'] = createdBy ?? "N/A";
    data['modification_datetime'] = modificationDatetime ?? "N/A";
    data['modified_by'] = modifiedBy ?? "N/A";
    data['org_id'] = orgId ?? "N/A";
    data['branch_id'] = branchId ?? 0;
    data['Customer'] = customer ?? "N/A";
    data['order_des'] = order_des ?? "N/A";
    if (details != null) {
      data['details'] = details!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Details {
  int? orderDetId;
  int? orderId;
  int? mProdId;
  int? qty;
  String? note;
  String? rate;
  String? netAmt;
  String? status;
  String? startPrep;
  String? endPrep;
  Product? product;

  // ✅ NEW: Fields from kitchen endpoint
  String? nameArb; // Arabic product name
  String? type; // "product" or "modifier"
  int? link; // Parent item ID (for modifiers)
  List<ModifierItem>? modifiers; // Sub-items/addons

  Details({
    this.orderDetId,
    this.orderId,
    this.mProdId,
    this.qty,
    this.note,
    this.rate,
    this.netAmt,
    this.status,
    this.startPrep,
    this.endPrep,
    this.product,
    this.nameArb,
    this.type,
    this.link,
    this.modifiers,
  });

  Details.fromJson(Map<String, dynamic> json) {
    orderDetId = json['order_det_id'] ?? 0;
    orderId = json['order_id'] ?? 0;
    mProdId = json['m_prod_id'] ?? 0;
    qty = json['qty'] ?? 0;
    note = (json['note'] ?? "N/A").toString();
    rate = (json['rate'] ?? "0").toString();
    netAmt = (json['net_amt'] ?? "0").toString();
    status = (json['status'] ?? "N/A").toString();
    startPrep = (json['start_prep'] ?? "N/A").toString();
    endPrep = (json['end_prep'] ?? "N/A").toString();
    product = json['product'] != null
        ? Product.fromJson(json['product'])
        : null;
  }

  /// Maps a single item from the kitchen endpoint `items` array.
  /// Creates a synthetic [Product] so existing timer/display logic works unchanged.
  Details.fromKitchenItem(Map<String, dynamic> json) {
    final rawQty = json['quantity'] ?? json['qty'] ?? 0;
    final rawRate = (json['rate'] ?? '0').toString();
    final rawPrepTime = json['prep_time'] ?? 0;
    final rawStationId = json['station_id'] ?? 0;

    orderDetId = json['detail_id'] ?? json['order_det_id'] ?? 0;
    orderId = json['order_id'];
    mProdId = json['m_prod_id'] ?? 0;
    qty = (rawQty as num).toInt();
    note = (json['note'] ?? '').toString();
    rate = rawRate;
    netAmt = ((qty ?? 0).toDouble() * (double.tryParse(rawRate) ?? 0.0))
        .toStringAsFixed(2);
    status = (json['status'] ?? '').toString();
    startPrep = json['start_prep']?.toString();
    endPrep = json['end_prep']?.toString();

    // ✅ NEW: Parse additional kitchen endpoint fields
    nameArb = json['name_arb']?.toString();
    type = json['type']?.toString();
    link = json['link'] != null ? int.tryParse(json['link'].toString()) : null;

    // ✅ NEW: Parse modifiers array
    if (json['modifiers'] is List) {
      modifiers = (json['modifiers'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => ModifierItem.fromJson(item))
          .toList();
    }

    product = Product(
      mPName: json['name']?.toString() ?? '',
      price: rawRate,
      mProductIcon: null,
      dishPrepTime: rawPrepTime is int
          ? rawPrepTime
          : int.tryParse(rawPrepTime.toString()) ?? 0,
      stationId: rawStationId is int
          ? rawStationId
          : int.tryParse(rawStationId.toString()) ?? 0,
      nameArb: nameArb, // ✅ Pass Arabic name to Product
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['order_det_id'] = orderDetId ?? 0;
    data['order_id'] = orderId ?? 0;
    data['m_prod_id'] = mProdId ?? 0;
    data['qty'] = qty ?? 0;
    data['note'] = note ?? "N/A";
    data['rate'] = rate ?? "0";
    data['net_amt'] = netAmt ?? "0";
    data['status'] = status ?? "N/A";
    data['start_prep'] = startPrep ?? "N/A";
    data['end_prep'] = endPrep ?? "N/A";
    if (product != null) {
      data['product'] = product!.toJson();
    }
    return data;
  }
}

class Product {
  String? mPName;
  String? price;
  String? mProductIcon;
  int? dishPrepTime;
  int? stationId;
  String? nameArb; // ✅ NEW: Arabic name

  Product({
    this.mPName,
    this.price,
    this.mProductIcon,
    this.dishPrepTime,
    this.stationId,
    this.nameArb,
  });

  Product.fromJson(Map<String, dynamic> json) {
    mPName = (json['m_p_name'] ?? "N/A").toString();
    price = (json['price'] ?? "0").toString();
    mProductIcon = (json['m_product_icon'] ?? "N/A").toString();
    dishPrepTime = json['dish_prep_time'] ?? 0;
    stationId = json['station_id'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['m_p_name'] = mPName ?? "N/A";
    data['price'] = price ?? "0";
    data['m_product_icon'] = mProductIcon ?? "N/A";
    data['dish_prep_time'] = dishPrepTime ?? 0;
    data['station_id'] = stationId ?? 0;
    return data;
  }
}

//-✅---------------------------------------------------------------------✅-//
