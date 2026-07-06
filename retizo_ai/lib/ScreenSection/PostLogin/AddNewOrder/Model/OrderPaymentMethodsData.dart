// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class OrderPaymentMethodsData {
  int payMId;
  String name;
  String nameAr;
  String type;
  String status;

  OrderPaymentMethodsData({
    this.payMId = 0,
    this.name = "N/A",
    this.nameAr = "N/A",
    this.type = "N/A",
    this.status = "N/A",
  });

  factory OrderPaymentMethodsData.fromJson(Map<String, dynamic> json) {
    return OrderPaymentMethodsData(
      payMId: json['pay_m_id'] is int
          ? json['pay_m_id']
          : int.tryParse("${json['pay_m_id']}") ?? 0,
      name: json['name']?.toString() ?? "N/A",
      nameAr: json['name_ar']?.toString() ?? "N/A",
      type: json['type']?.toString() ?? "N/A",
      status: json['status']?.toString() ?? "N/A",
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
