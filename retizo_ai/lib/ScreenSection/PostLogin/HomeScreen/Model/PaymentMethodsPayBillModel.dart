// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
//-✅---------------------------------------------------------------------✅-//
class PaymentMethodsPayBillModel {
  final int payMId;
  final String name;
  final String nameAr;
  final String type;
  final String status;

  PaymentMethodsPayBillModel({
    this.payMId = 0,
    this.name = "",
    this.nameAr = "",
    this.type = "",
    this.status = "",
  });

  factory PaymentMethodsPayBillModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PaymentMethodsPayBillModel(); // return default model
    }

    return PaymentMethodsPayBillModel(
      payMId: json['pay_m_id'] is int
          ? json['pay_m_id']
          : int.tryParse("${json['pay_m_id']}") ?? 0,
      name: json['name']?.toString() ?? "",
      nameAr: json['name_ar']?.toString() ?? "",
      type: json['type']?.toString() ?? "",
      status: json['status']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pay_m_id': payMId,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'status': status,
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
