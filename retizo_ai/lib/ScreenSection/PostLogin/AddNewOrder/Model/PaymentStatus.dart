// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class PaymentStatusModel {
  final int id;
  final String title;

  PaymentStatusModel({required this.id, required this.title});

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatusModel(id: json["id"] ?? 0, title: json["Title"] ?? "");
  }

  Map<String, dynamic> toJson() => {"id": id, "Title": title};
}

//-✅---------------------------------------------------------------------✅-//
