// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class TipsAmountModel {
  bool success;
  List<TipsAmountListModel> data;

  TipsAmountModel({required this.success, required this.data});

  factory TipsAmountModel.fromJson(Map<String, dynamic> json) {
    return TipsAmountModel(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => TipsAmountListModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data.map((e) => e.toJson()).toList()};
  }
}

class TipsAmountListModel {
  String id;
  String title;
  IconData icon;

  TipsAmountListModel({
    required this.id,
    required this.title,
    required this.icon,
  });

  factory TipsAmountListModel.fromJson(Map<String, dynamic> json) {
    // Extract title dynamically (first key that is not 'id' or 'IconData')
    String tipTitle = "";
    json.forEach((key, value) {
      if (key != 'id' && key != 'IconData') {
        tipTitle = value.toString();
      }
    });

    // Extract icon safely
    IconData tipIcon = Icons.attach_money; // default icon
    if (json.containsKey('IconData') && json['IconData'] is IconData) {
      tipIcon = json['IconData'];
    }

    return TipsAmountListModel(
      id: json['id']?.toString() ?? "",
      title: tipTitle,
      icon: tipIcon,
    );
  }

  Map<String, dynamic> toJson() {
    // IconData can't be serialized directly. We'll store codePoint.
    return {'id': id, 'Title': title, 'IconData': icon.codePoint};
  }

  // Optional: convert codePoint back to IconData
  static IconData iconFromCode(int codePoint) {
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }
}

//-✅---------------------------------------------------------------------✅-//
