// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/GlobalComponents/CommonFunction/AmountFormatter.dart';

//-✅---------------------------------------------------------------------✅-//
class OrderListModel {
  final bool success;
  final String msg;
  final List<OrderData> data;

  OrderListModel({
    this.success = false,
    this.msg = 'N/A',
    List<OrderData>? data,
  }) : data = data ?? [];

  factory OrderListModel.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? false;
    final String msg = json['msg']?.toString() ?? 'N/A';
    final List<dynamic>? dataList = json['data'] as List<dynamic>?;

    final List<OrderData> data = dataList != null
        ? dataList
              .where((item) => item != null && item is Map<String, dynamic>)
              .map((item) => OrderData.fromJson(item))
              .toList()
        : [];

    return OrderListModel(success: success, msg: msg, data: data);
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'msg': msg,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

//================ OrderData =================//
class OrderData {
  final int orderId;
  final int orderNo;
  final int invoiceNo;
  final String custId;
  final int tableId;
  final String tableName;
  final String orderDate;
  final String type;
  final int pax;
  final String netAmt;
  final String taxId;
  final String taxAmt;
  final String chargeId;
  final String chargeAmt;
  final String payMId;
  final String paymentMethodName;
  final String orderStatus;
  final String discountPer;
  final String discountAmt;
  final String totalAmt;
  final String remainingAmount;
  final String advPayment;
  final String priority;
  final String orderPreparedTime;
  final String creationDatetime;
  final int createdBy;
  final String modificationDatetime;
  final String modifiedBy;
  final String orgId;
  final int branchId;
  final String customer;

  // Payment extra fields
  final String cashout;
  final String cardout;
  final String orderDes;

  // Order details
  final List<OrderDetail> details;
  String? selectedDropDownOne;
  String? selectedDropDownTwo;
  final String paymentStatus;

  /// ✅ True when this order has already been refunded (from refund_info.has_refund)
  final bool hasRefund;

  /// Table surcharge applied to this order (from API table_charge)
  final double tableCharge;

  /// Price adjustment amount (positive = addition, negative = deduction) from API adjust_amt
  final String adjustAmt;

  /// Human-readable reason provided when adjustment was applied (from API adjust_reason)
  final String adjustReason;

  /// Refund amount already applied on this order (from API refund_amt)
  final String refundAmt;

  /// Due/remaining amount shown on the order (from API due_amount)
  final String dueAmount;

  /// Raw tax_breakdown object from API (has net_amount, total_tax, taxes.VAT, etc.)
  final Map<String, dynamic>? taxBreakdownMap;

  /// Group ID for this order — 0 means not grouped, non-zero means it is already in a group
  final int groupId;

  /// True when this order is a GROUP PARENT (from API is_group flag)
  final bool isGroup;

  /// Parsed `payments` array from API — each entry is a recorded payment transaction.
  /// Populated for multi-payment / partial-paid orders; may be empty for simple single-method orders.
  final List<OrderPaymentEntry> payments;

  /// ✅ COMPUTED TOTALS FROM ITEMS - ALWAYS ACCURATE
  /// These getters calculate live from order_details, not from stale order_master data

  /// Computed: sum of all ACTIVE item subtotals (qty × price).
  /// ✅ Skips cancelled items and modifier rows to match web app calculateOrderTotals logic.
  double get itemsTotal => details
      .where(
        (d) =>
            d.status.toLowerCase() != 'cancelled' &&
            d.itemType.toLowerCase() != 'modifier',
      )
      .fold(0.0, (sum, d) => sum + (double.tryParse(d.subtotal) ?? 0.0));

  /// ✅ Total Amount — uses backend total_amt (DB authoritative), matching web.
  /// Backend total_amt already includes product + modifier prices correctly.
  /// Summing detail rows would double-count modifiers because backend returns
  /// both inflated product rows and separate modifier rows.
  double get calculatedSubtotal => double.tryParse(totalAmt) ?? 0.0;

  /// Computed: Main tax amount (VAT/GST) - INFORMATIONAL ONLY
  /// In tax-inclusive pricing, this is already included in item prices
  /// This should NOT be added to total - it's for reporting purposes only
  double get calculatedTaxAmt {
    final storedTax = double.tryParse(taxAmt) ?? 0.0;
    return storedTax;
  }

  /// ✅ Calculated refund amount — mirrors web dashboard logic:
  /// Refund = max(0, TotalPaid - ExpectedTotal)
  /// where ExpectedTotal = total_amt + table_charge + adjust_amt
  double get calculatedRefund => (totalPaidAmount - fullPayableTotal).clamp(0.0, double.infinity);

  /// Computed: Accurate total amount — delegates to grandTotal (DB authoritative)
  double get calculatedTotalAmt => grandTotal;

  /// String versions for UI compatibility
  String get calculatedSubtotalStr => calculatedSubtotal.toStringAsFixed(2);
  String get calculatedTaxAmtStr => calculatedTaxAmt.toStringAsFixed(2);
  String get calculatedTotalAmtStr => formatAmount(calculatedTotalAmt);
  String get formattedGrandTotal => formatAmount(grandTotal);
  double get normalizedGrandTotal => normalizeFormattedAmount(grandTotal);

  /// ✅ Grand total — matches web: total_amt - refund + table_charge + adjust.
  double get grandTotal => fullPayableTotal;

  /// ✅ Derives the payment method label for display on the order card.
  /// Priority: payments[] names → SPLIT (cash+card) → CASH → CARD → paymentMethodName
  String get paymentTypeLabel {
    if (payments.isNotEmpty) {
      if (payments.length == 1) {
        // Single payment entry — show that method name (also covers partial payment)
        final name = payments.first.methodName.toUpperCase().trim();
        if (name.isNotEmpty) return name;
      } else if (payments.length == 2) {
        // Exactly 2 payments = SPLIT → use parent paymentMethod.name from backend
        if (paymentMethodName != 'N/A' && paymentMethodName.isNotEmpty) {
          return paymentMethodName.toUpperCase();
        }
        return 'SPLIT PAYMENT';
      } else {
        // More than 2 payments = MULTI
        return 'MULTI';
      }
    }
    final cash = double.tryParse(cashout) ?? 0.0;
    final card = double.tryParse(cardout) ?? 0.0;
    if (cash > 0 && card > 0) return 'SPLIT';
    if (cash > 0) return 'CASH';
    if (card > 0) return 'CARD';
    if (paymentMethodName != 'N/A' && paymentMethodName.isNotEmpty) {
      return paymentMethodName.toUpperCase();
    }
    return '';
  }

  /// ✅ Full payable amount — matches web: total_amt - refund + table_charge + adjust.
  /// DB total_amt already has discount subtracted (backend sends
  /// total_amt = subtotal + charges - discount), so no need to subtract again.
  double get fullPayableTotal {
    final adj = double.tryParse(adjustAmt) ?? 0.0;
    final total = double.tryParse(totalAmt) ?? 0.0;
    return total + tableCharge + adj;
  }

  /// Reverse-extracts pre-tax net from PRODUCT detail rows only.
  /// Skips modifier rows because product net_amt already includes modifier prices.
  /// Used as FALLBACK only when backend taxBreakdownMap is unavailable.
  /// Formula (tax-inclusive pricing): net = subtotal / ((1 + extraTaxRate) × 1.15)
  double get _netFromDetails {
    double totalNet = 0.0;
    for (final d in details.where(
      (det) =>
          det.status.toLowerCase() != 'cancelled' &&
          det.itemType.toLowerCase() != 'modifier',
    )) {
      final totalPrice = double.tryParse(d.subtotal) ?? 0.0;
      final extraRate = (double.tryParse(d.taxGroup) ?? 0.0) / 100.0;
      final divisor = (1.0 + extraRate) * 1.15;
      totalNet += totalPrice / divisor;
    }
    return double.parse(totalNet.toStringAsFixed(2));
  }

  /// Total tax derived from detail rows = calculatedSubtotal − _netFromDetails
  double get _taxFromDetails =>
      double.parse((calculatedSubtotal - _netFromDetails).toStringAsFixed(2));

  /// Individual tax amounts — prefer backend taxBreakdownMap (like web does),
  /// fall back to client-side re-calculation when backend values unavailable.
  /// Used by the UI for the per-tax-type lines (└ VAT:, └ Tobacco:, etc.)
  Map<String, dynamic>? get displayTaxesMap {
    // ── Priority 1: backend tax_breakdown (source of truth) ────────
    if (taxBreakdownMap != null && taxBreakdownMap!['taxes'] is Map) {
      return Map<String, dynamic>.from(taxBreakdownMap!['taxes'] as Map);
    }
    // ── Priority 2: client-side recalculation from PRODUCT rows only ──
    // Skip modifier rows because product net_amt includes modifier prices.
    if (details.isNotEmpty) {
      double totalVat = 0.0;
      double totalExtraTax = 0.0;
      for (final d in details.where(
        (det) =>
            det.status.toLowerCase() != 'cancelled' &&
            det.itemType.toLowerCase() != 'modifier',
      )) {
        final totalPrice = double.tryParse(d.subtotal) ?? 0.0;
        final extraRate = (double.tryParse(d.taxGroup) ?? 0.0) / 100.0;
        final divisor = (1.0 + extraRate) * 1.15;
        final netPrice = totalPrice / divisor;
        totalVat += netPrice * 0.15;
        totalExtraTax += netPrice * extraRate;
      }
      final Map<String, dynamic> taxes = {
        'VAT': double.parse(totalVat.toStringAsFixed(2)),
      };
      if (totalExtraTax > 0.01) {
        taxes['Extra Tax'] = double.parse(totalExtraTax.toStringAsFixed(2));
      }
      return taxes;
    }
    return null;
  }

  /// ✅ Net amount (before tax) — prefer backend taxBreakdownMap (like web),
  /// fall back to client-side calculation from detail rows, then stored net_amt.
  double get displayNetAmount {
    if (taxBreakdownMap != null) {
      final n = taxBreakdownMap!['net_amount'];
      if (n != null) {
        final v = double.tryParse(n.toString());
        if (v != null && v > 0) return v;
      }
    }
    if (details.isNotEmpty) return _netFromDetails;
    return double.tryParse(netAmt) ?? 0.0;
  }

  /// ✅ Total tax amount — prefer backend taxBreakdownMap (like web),
  /// fall back to client-side calculation from detail rows, then stored tax_amt.
  double get displayTotalTax {
    if (taxBreakdownMap != null) {
      final t = taxBreakdownMap!['total_tax'];
      if (t != null) {
        final v = double.tryParse(t.toString());
        if (v != null && v > 0) return v;
      }
    }
    if (details.isNotEmpty) return _taxFromDetails;
    return double.tryParse(taxAmt) ?? 0.0;
  }

  /// ✅ Cancelled amount = sum of cancelled-item values.
  /// Matches web app calculateCancelledAmount logic exactly:
  ///   • JS `Number(rate) || Number(price)` — 0 is falsy, falls through to price
  ///   • status='cancelled' with original_qty not stored → use quantity as cancelled qty
  double calculateCancelledAmount() {
    // If the entire order is marked as cancelled, use the grand total as the baseline
    // if no details are present or if they don't sum up to anything.
    if (orderStatus.toLowerCase() == 'cancelled' && details.isEmpty) {
      return fullPayableTotal;
    }

    double cancelled = 0.0;
    for (final item in details) {
      // ✅ Mirror JS: Number(rate)||Number(price) — rate='0' must fall back to price
      final rateVal = double.tryParse(item.rate) ?? 0.0;
      final priceVal = double.tryParse(item.price) ?? 0.0;
      final unitPrice = rateVal > 0 ? rateVal : priceVal;
      if (unitPrice <= 0) continue;

      // ✅ Case 1: original_qty correctly returned — diff gives cancelled qty
      int cancelledQty = item.originalQty - item.quantity;
      
      // ✅ Case 2: cancelled_qty explicitly returned by backend (matches web app)
      if (item.cancelledQty > cancelledQty) {
        cancelledQty = item.cancelledQty;
      }

      if (cancelledQty > 0) {
        cancelled += unitPrice * cancelledQty;
      } else if (item.status.toLowerCase() == 'cancelled') {
        // ✅ Case 3: Fully cancelled item (quantity might be 0)
        // If no originalQty/cancelledQty, fallback to 'qty' or 'quantity' field
        final fallbackQty = item.originalQty > 0
            ? item.originalQty
            : (item.qty > 0 ? item.qty : item.quantity);
        cancelled += unitPrice * (fallbackQty > 0 ? fallbackQty : 1);
      }
    }

    // If order is fully cancelled but items only sum to 0 (e.g. backend wiped prices),
    // fallback to fullPayableTotal.
    if (orderStatus.toLowerCase() == 'cancelled' && cancelled == 0) {
      return fullPayableTotal;
    }

    return cancelled;
  }

  /// ✅ TOTAL PAID AMOUNT - Calculated from payments array (PRODUCTION FIX)
  /// Backend Adv_payment field is NOT updated after partial payments!
  /// This getter sums all payment entries to get accurate total paid.
  /// Used for partial payment dialog and remaining balance calculation.
  double get totalPaidAmount {
    if (payments.isEmpty) {
      // Fallback to Adv_payment only when no payments array
      print(
        '🔍 Order #${orderNo}: No payments array, using Adv_payment: $advPayment',
      );
      return double.tryParse(advPayment) ?? 0.0;
    }
    // Sum all payment entries (this is the accurate source of truth)
    final total = payments.fold(0.0, (sum, payment) => sum + payment.amount);
    print(
      '🔍 Order #${orderNo}: Calculating from payments[] - ${payments.length} payment(s) = SAR $total',
    );
    return total;
  }

  /// ✅ REMAINING BALANCE - Calculated from totalPaidAmount
  /// Grand total minus all recorded payments
  double get remainingBalance {
    // Effective balance = Total Expected - (Total Paid - Refund)
    // If they overpaid (Refund > 0), the effective paid is reduced by the refund amount.
    final effectivePaid = totalPaidAmount - calculatedRefund;
    final remaining = (fullPayableTotal - effectivePaid).clamp(0.0, double.infinity);
    
    print(
      '🔍 Order #${orderNo}: Remaining = $fullPayableTotal - ($totalPaidAmount - $calculatedRefund) = SAR $remaining',
    );
    return remaining;
  }

  OrderData({
    int? orderId,
    int? orderNo,
    int? invoiceNo,
    String? custId,
    int? tableId,
    String? tableName,
    String? orderDate,
    String? type,
    int? pax,
    String? netAmt,
    String? taxId,
    String? taxAmt,
    String? chargeId,
    String? chargeAmt,
    String? payMId,
    String? paymentMethodName,
    String? orderStatus,
    String? discountPer,
    String? discountAmt,
    String? totalAmt,
    String? remainingAmount,
    String? advPayment,
    String? priority,
    String? orderPreparedTime,
    String? creationDatetime,
    int? createdBy,
    String? modificationDatetime,
    String? modifiedBy,
    String? orgId,
    int? branchId,
    String? customer,
    this.selectedDropDownOne,
    this.selectedDropDownTwo,
    String? cashout,
    String? cardout,
    String? orderDes,
    String? paymentStatus,
    bool? hasRefund,
    double? tableCharge,
    String? adjustAmt,
    String? adjustReason,
    String? refundAmt,
    String? dueAmount,
    this.taxBreakdownMap,
    int? groupId,
    bool? isGroup,
    List<OrderDetail>? details,
    List<OrderPaymentEntry>? payments,
  }) : orderId = orderId ?? 0,
       groupId = groupId ?? 0,
       isGroup = isGroup ?? false,
       hasRefund = hasRefund ?? false,
       tableCharge = tableCharge ?? 0.0,
       adjustAmt = adjustAmt?.isNotEmpty == true ? adjustAmt! : '0',
       adjustReason = adjustReason ?? '',
       refundAmt = refundAmt?.isNotEmpty == true ? refundAmt! : '0',
       dueAmount = dueAmount?.isNotEmpty == true ? dueAmount! : '0',
       orderNo = orderNo ?? 0,
       invoiceNo = invoiceNo ?? 0,
       custId = custId?.isNotEmpty == true ? custId! : 'N/A',
       paymentStatus = (paymentStatus != null && paymentStatus.isNotEmpty)
           ? paymentStatus
           : 'N/A',
       tableId = tableId ?? 0,
       tableName = tableName?.isNotEmpty == true ? tableName! : 'N/A',
       orderDate = orderDate?.isNotEmpty == true ? orderDate! : 'N/A',
       type = type?.isNotEmpty == true ? type! : 'N/A',
       pax = pax ?? 0,
       netAmt = netAmt?.isNotEmpty == true ? netAmt! : '0',
       taxId = taxId?.isNotEmpty == true ? taxId! : 'N/A',
       taxAmt = taxAmt?.isNotEmpty == true ? taxAmt! : '0',
       chargeId = chargeId?.isNotEmpty == true ? chargeId! : 'N/A',
       chargeAmt = chargeAmt?.isNotEmpty == true ? chargeAmt! : '0',
       payMId = payMId?.isNotEmpty == true ? payMId! : 'N/A',
       paymentMethodName = paymentMethodName?.isNotEmpty == true
           ? paymentMethodName!
           : 'N/A',
       orderStatus = orderStatus?.isNotEmpty == true ? orderStatus! : 'N/A',
       discountPer = discountPer?.isNotEmpty == true ? discountPer! : '0',
       discountAmt = discountAmt?.isNotEmpty == true ? discountAmt! : '0',
       totalAmt = totalAmt?.isNotEmpty == true ? totalAmt! : '0',
       remainingAmount = remainingAmount?.isNotEmpty == true
           ? remainingAmount!
           : '0',
       advPayment = advPayment?.isNotEmpty == true ? advPayment! : '0',
       priority = priority?.isNotEmpty == true ? priority! : 'N/A',
       orderPreparedTime = orderPreparedTime?.isNotEmpty == true
           ? orderPreparedTime!
           : 'N/A',
       creationDatetime = creationDatetime?.isNotEmpty == true
           ? creationDatetime!
           : 'N/A',
       createdBy = createdBy ?? 0,
       modificationDatetime = modificationDatetime?.isNotEmpty == true
           ? modificationDatetime!
           : 'N/A',
       modifiedBy = modifiedBy?.isNotEmpty == true ? modifiedBy! : 'N/A',
       orgId = orgId?.isNotEmpty == true ? orgId! : 'N/A',
       branchId = branchId ?? 0,
       customer = customer?.isNotEmpty == true ? customer! : 'N/A',
       cashout = cashout?.isNotEmpty == true ? cashout! : '0',
       cardout = cardout?.isNotEmpty == true ? cardout! : '0',
       orderDes = orderDes?.isNotEmpty == true ? orderDes! : 'N/A',
       details = details ?? [],
       payments = payments ?? [];

  factory OrderData.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? detailList = json['details'] as List<dynamic>?;

    final List<OrderDetail> details = detailList != null
        ? detailList
              .where((item) => item != null && item is Map<String, dynamic>)
              .map((item) => OrderDetail.fromJson(item))
              .toList()
        : [];

    String p(dynamic value) {
      if (value == null) return 'N/A';
      if (value is String) return value;
      return value.toString();
    }

    String num(dynamic value) {
      if (value == null) return '0';
      return value.toString();
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    // Parse table name: prefer top-level table_name, fallback to nested table object
    String resolveTableName() {
      if (json['table_name'] != null &&
          json['table_name'].toString().isNotEmpty) {
        return json['table_name'].toString();
      }
      final table = json['table'];
      if (table is Map<String, dynamic> && table['table_name'] != null) {
        return table['table_name'].toString();
      }
      return 'N/A';
    }

    // Parse payment method name: prefer nested paymentMethod.name, fallback to flat payment_method_name
    String resolvePaymentMethodName() {
      final pm = json['paymentMethod'];
      if (pm is Map<String, dynamic>) {
        final name = pm['name']?.toString() ?? '';
        if (name.isNotEmpty) return name;
      }
      final flat = json['payment_method_name']?.toString() ?? '';
      if (flat.isNotEmpty) return flat;
      return 'N/A';
    }

    // Parse customer name: handle both string and object formats
    // Backend may return Customer as:
    //   1) String: "Hassan al sabban"
    //   2) Object: {cust_id: 10, name: "Hassan al sabban", mobile: ..., email: ..., address: ...}
    String resolveCustomerName() {
      final customer = json['Customer'];
      if (customer == null) return 'N/A';

      // If it's already a string, use it directly
      if (customer is String) {
        return customer.isNotEmpty ? customer : 'N/A';
      }

      // If it's an object, extract the 'name' field
      if (customer is Map<String, dynamic>) {
        final name = customer['name']?.toString() ?? '';
        if (name.isNotEmpty) return name;
        // Fallback to other possible name fields
        final custName = customer['customer_name']?.toString() ?? '';
        if (custName.isNotEmpty) return custName;
        // Fallback to cust_id if no name available
        final custId = customer['cust_id']?.toString() ?? '';
        if (custId.isNotEmpty) return 'Customer #$custId';
      }

      return 'N/A';
    }

    return OrderData(
      orderId: parseInt(json['order_id']),
      orderNo: parseInt(json['order_no']),
      invoiceNo: parseInt(json['invoice_no']),
      custId: p(json['cust_id']),
      tableId: json['table_id'] is int
          ? json['table_id']
          : int.tryParse(json['table_id']?.toString() ?? '') ?? 0,
      tableName: resolveTableName(),
      orderDate: p(json['order_date']),
      type: p(json['type']),
      pax: parseInt(json['pax']),
      netAmt: num(json['net_amt']),
      taxId: p(json['taxid']),
      taxAmt: num(json['tax_amt']),
      chargeId: p(json['charge_id']),
      chargeAmt: num(json['charge_amt']),
      payMId: p(json['pay_m_id']),
      paymentMethodName: resolvePaymentMethodName(),
      orderStatus: p(json['order_status']),
      discountPer: num(json['discount_per']),
      discountAmt: num(json['discount_amt']),
      totalAmt: num(json['total_amt']),
      remainingAmount: num(json['remaining_amount']),
      advPayment: num(json['Adv_payment']),
      priority: p(json['priority']),
      paymentStatus: p(json['payment_status']),
      hasRefund: () {
        final refundInfo = json['refund_info'];
        if (refundInfo is Map<String, dynamic>) {
          return refundInfo['has_refund'] as bool? ?? false;
        }
        return false;
      }(),
      cashout: num(json['cashout']),
      cardout: num(json['cardout']),
      orderDes: p(json['order_des']),
      orderPreparedTime: p(json['order_preparedtime']),
      creationDatetime: p(json['creation_datetime']),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.tryParse(p(json['created_by'])) ?? 0,
      modificationDatetime: p(json['modification_datetime']),
      modifiedBy: p(json['modified_by']),
      orgId: p(json['org_id']),
      branchId: parseInt(json['branch_id']),
      customer: resolveCustomerName(),
      details: details,
      tableCharge: () {
        final tc = json['table_charge'];
        if (tc == null) return 0.0;
        return double.tryParse(tc.toString()) ?? 0.0;
      }(),
      adjustAmt: num(json['adjust_amt']),
      adjustReason: json['adjust_reason']?.toString() ?? '',
      refundAmt: num(json['refund_amt']),
      dueAmount: num(json['due_amount']),
      taxBreakdownMap: json['tax_breakdown'] is Map<String, dynamic>
          ? json['tax_breakdown'] as Map<String, dynamic>
          : null,
      groupId: parseInt(json['group_id']),
      isGroup: (json['is_group'] as bool?) ?? false,
      payments: () {
        final list = json['payments'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(OrderPaymentEntry.fromJson)
              .toList();
        }
        return <OrderPaymentEntry>[];
      }(),
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'order_no': orderNo,
    'invoice_no': invoiceNo,
    'cust_id': custId,
    'table_id': tableId,
    'table_name': tableName,
    'order_date': orderDate,
    'type': type,
    'pax': pax,
    'net_amt': netAmt,
    'taxid': taxId,
    'tax_amt': taxAmt,
    'charge_id': chargeId,
    'charge_amt': chargeAmt,
    'pay_m_id': payMId,
    'paymentMethod': {'name': paymentMethodName},
    'order_status': orderStatus,
    'discount_per': discountPer,
    'discount_amt': discountAmt,
    'total_amt': totalAmt,
    'remaining_amount': remainingAmount,
    'Adv_payment': advPayment,
    'priority': priority,
    'payment_status': paymentStatus,
    'refund_info': {'has_refund': hasRefund},
    'table_charge': tableCharge,
    'adjust_amt': adjustAmt,
    'adjust_reason': adjustReason,
    'refund_amt': refundAmt,
    'due_amount': dueAmount,
    'tax_breakdown': taxBreakdownMap,
    'group_id': groupId,
    'is_group': isGroup,
    'cashout': cashout,
    'cardout': cardout,
    'order_des': orderDes,
    'order_preparedtime': orderPreparedTime,
    'creation_datetime': creationDatetime,
    'created_by': createdBy,
    'modification_datetime': modificationDatetime,
    'modified_by': modifiedBy,
    'org_id': orgId,
    'branch_id': branchId,
    'Customer': customer,
    'details': details.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
  };
}

//================ OrderDetail =================//
class OrderDetail {
  final int orderDetId;
  final int orderId;
  final int mProdId;
  final int quantity;
  final String price;
  final String subtotal;
  final String note;
  final String status;
  final Product product;

  /// Tax group for this item: "0" = VAT only, "1+" = Tobacco + VAT
  final String taxGroup;

  /// Item type: "item" (default) or "modifier" (addon linked to a parent item)
  final String itemType;

  /// Original quantity before any cancellations (original_qty from API)
  final int originalQty;

  /// Quantity that was specifically cancelled (cancelled_qty from API)
  final int cancelledQty;

  /// Reason given when this item (or partial qty) was cancelled
  final String cancelReason;

  /// Modifier link: references the parent item's order_det_id (as string)
  /// OR the parent's cart_uuid (when the server preserves the client-generated UUID)
  final String? link;

  /// Cart UUID: shared between a parent product row and all its modifier rows.
  /// Used for modifier matching when `link` contains the UUID rather than order_det_id.
  final String? cartUuid;

  /// Item name directly from API response
  final String name;

  // Legacy fields for backward compatibility
  final int qty;
  final String rate;
  final String netAmt;

  OrderDetail({
    int? orderDetId,
    int? orderId,
    int? mProdId,
    int? quantity,
    String? price,
    String? subtotal,
    String? note,
    String? status,
    Product? product,
    String? taxGroup,
    String? itemType,
    int? originalQty,
    int? cancelledQty,
    String? cancelReason,
    this.link,
    this.cartUuid,
    String? name,
    int? qty,
    String? rate,
    String? netAmt,
  }) : orderDetId = orderDetId ?? 0,
       orderId = orderId ?? 0,
       mProdId = mProdId ?? 0,
       quantity = quantity ?? qty ?? 0,
       price = price ?? rate ?? '0',
       subtotal = subtotal ?? netAmt ?? '0',
       note = note?.isNotEmpty == true ? note! : 'N/A',
       status = status?.isNotEmpty == true ? status! : 'N/A',
       product = product ?? Product(),
       taxGroup = taxGroup?.isNotEmpty == true ? taxGroup! : '0',
       itemType = itemType?.isNotEmpty == true ? itemType! : 'item',
       originalQty = originalQty ?? quantity ?? 0,
       cancelledQty = cancelledQty ?? 0,
       cancelReason = cancelReason ?? '',
       name = name?.isNotEmpty == true ? name! : 'N/A',
       qty = qty ?? 0,
       rate = rate ?? '0',
       netAmt = netAmt ?? '0';

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String parseString(dynamic value) {
      if (value == null) return '0';
      return value.toString();
    }

    return OrderDetail(
      orderDetId: parseInt(json['order_det_id']),
      orderId: parseInt(json['order_id']),
      mProdId: parseInt(json['m_prod_id']),
      quantity: json['quantity'] != null
          ? parseInt(json['quantity'])
          : (json['qty'] != null ? parseInt(json['qty']) : 0),
      price: json['price'] != null
          ? parseString(json['price'])
          : (json['rate'] != null ? parseString(json['rate']) : '0'),
      subtotal: json['subtotal'] != null
          ? parseString(json['subtotal'])
          : (json['net_amt'] != null ? parseString(json['net_amt']) : '0'),
      note: json['note']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'N/A',
      taxGroup: json['tax_group']?.toString() ?? '0',
      itemType: json['type']?.toString() ?? 'item',
      originalQty: json['original_qty'] != null
          ? parseInt(json['original_qty'])
          : (json['quantity'] != null ? parseInt(json['quantity']) : 0),
      cancelledQty: parseInt(json['cancelled_qty']),
      cancelReason: json['cancel_reason']?.toString() ?? '',
      link: json['link']?.toString(),
      cartUuid: json['cart_uuid']?.toString(),
      name:
          json['name']?.toString() ??
          (json['product']?['m_p_name']?.toString() ?? 'N/A'),
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : Product(),
      qty: json['qty'] != null ? parseInt(json['qty']) : 0,
      rate: json['rate']?.toString() ?? '0',
      netAmt: json['net_amt']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
    'order_det_id': orderDetId,
    'order_id': orderId,
    'm_prod_id': mProdId,
    'quantity': quantity,
    'price': price,
    'subtotal': subtotal,
    'note': note,
    'status': status,
    'tax_group': taxGroup,
    'type': itemType,
    'original_qty': originalQty,
    'cancelled_qty': cancelledQty,
    'cancel_reason': cancelReason,
    'link': link,
    'cart_uuid': cartUuid,
    'name': name,
    'product': product.toJson(),
    // legacy fields
    'qty': qty,
    'rate': rate,
    'net_amt': netAmt,
  };
}

//================ Product =================//
class Product {
  final String mPName;
  final String price;
  final String mProductIcon;

  Product({String? mPName, String? price, String? mProductIcon})
    : mPName = mPName?.isNotEmpty == true ? mPName! : 'N/A',
      price = price?.isNotEmpty == true ? price! : '0',
      mProductIcon = mProductIcon?.isNotEmpty == true ? mProductIcon! : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      mPName: json['m_p_name']?.toString() ?? 'N/A',
      price: json['price']?.toString() ?? '0',
      mProductIcon: json['m_product_icon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'm_p_name': mPName,
    'price': price,
    'm_product_icon': mProductIcon,
  };
}

//================ OrderPaymentEntry =================//
/// A single recorded payment transaction on an order.
/// Mirrors the web app's `order.payments[]` data structure.
class OrderPaymentEntry {
  final int orderPayId;
  final double amount;

  /// Display name of the payment method (e.g. "Cash", "Visa Card", "STC Pay").
  final String methodName;

  OrderPaymentEntry({
    this.orderPayId = 0,
    this.amount = 0.0,
    this.methodName = '',
  });

  factory OrderPaymentEntry.fromJson(Map<String, dynamic> json) {
    String name = '';
    final pm = json['paymentMethod'];
    if (pm is Map<String, dynamic>) {
      name = pm['name']?.toString() ?? pm['method_name']?.toString() ?? '';
    }
    if (name.isEmpty) {
      name =
          json['method_name']?.toString() ??
          json['payment_method_name']?.toString() ??
          json['name']?.toString() ??
          '';
    }
    return OrderPaymentEntry(
      orderPayId: json['order_pay_id'] is int
          ? json['order_pay_id'] as int
          : int.tryParse(json['order_pay_id']?.toString() ?? '') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      methodName: name,
    );
  }

  Map<String, dynamic> toJson() => {
    'order_pay_id': orderPayId,
    'amount': amount,
    'paymentMethod': {'name': methodName},
  };
}

//-✅---------------------------------------------------------------------✅-//
