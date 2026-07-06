// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
//-✅---------------------------------------------------------------------✅-//
class DropDownOneModel {
  bool? success; // Corrected spelling from "sucess" to "success"
  List<DropDownOneListModel>? data;

  DropDownOneModel({this.success, this.data});

  // JSON deserialization
  DropDownOneModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((item) => DropDownOneListModel.fromJson(item))
          .toList();
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DropDownOneListModel {
  String? id;
  String? title;

  DropDownOneListModel({this.id, this.title});

  // JSON deserialization
  DropDownOneListModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString(); // Ensures id is always a String
    title =
        json['Title']?.toString() ?? ""; // Defaults to an empty string if null
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['Title'] = title;
    return data;
  }
}

//-✅---------------------------------------------------------------------✅-//
