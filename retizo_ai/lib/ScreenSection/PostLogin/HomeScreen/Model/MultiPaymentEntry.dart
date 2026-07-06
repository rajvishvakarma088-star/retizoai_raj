/// Multi-Payment Entry Model
/// Represents a single payment entry in multi-payment mode
/// Each entry has an amount, payment method, and optional remark
class MultiPaymentEntry {
  String id; // Unique identifier for this entry
  double amount;
  int? paymentMethodId; // Selected payment method ID
  String? paymentMethodName; // Selected payment method name
  String? paymentMethodType; // Selected payment method type
  String? remark; // Optional remark

  MultiPaymentEntry({
    required this.id,
    this.amount = 0.0,
    this.paymentMethodId,
    this.paymentMethodName,
    this.paymentMethodType,
    this.remark,
  });

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'payment_method_name': paymentMethodName,
      'payment_method_type': paymentMethodType,
      'remark': remark,
    };
  }

  /// Create from JSON
  factory MultiPaymentEntry.fromJson(Map<String, dynamic> json) {
    return MultiPaymentEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodId: json['payment_method_id'] as int?,
      paymentMethodName: json['payment_method_name'] as String?,
      paymentMethodType: json['payment_method_type'] as String?,
      remark: json['remark'] as String?,
    );
  }

  /// Create a copy with modified fields
  MultiPaymentEntry copyWith({
    String? id,
    double? amount,
    int? paymentMethodId,
    String? paymentMethodName,
    String? paymentMethodType,
    String? remark,
  }) {
    return MultiPaymentEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      remark: remark ?? this.remark,
    );
  }

  /// Check if entry is complete (has amount and payment method)
  bool get isComplete =>
      amount > 0 && paymentMethodId != null && paymentMethodName != null;
}
