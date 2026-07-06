// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use, strict_top_level_inference
//-✅---------------------------------------------------------------------✅-//
import 'package:culai/HTTPRepository/GlobalServiceURL.dart';

class LoginResponseModel {
  final bool success;
  final String token;
  final String message;
  final UserModel user;

  LoginResponseModel({
    required this.success,
    required this.token,
    required this.message,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      token: json['token']?.toString() ?? "",
      message: json['message']?.toString() ?? "",
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'token': token,
    'message': message,
    'user': user.toJson(),
  };
}

//================ User Model =================//
class UserModel {
  final String orgUserId;
  final String name;
  final String email;
  final String type;
  final String designation; // ⭐ Added
  final String orgId;
  final int branchId;
  final String orgName;
  final String branchName;
  final String vatNo;
  final String orgPicture; // restaurant/org logo URL path
  final String branchAddress;
  final String status;
  final String picture; // ⭐ Added
  final String appAccess; // ⭐ Added
  final Map<String, PermissionModel>? permissions;

  UserModel({
    this.orgUserId = "",
    this.name = "",
    this.email = "",
    this.type = "",
    this.designation = "", // ⭐ Added
    this.orgId = "",
    this.branchId = 0,
    this.orgName = "",
    this.branchName = "",
    this.vatNo = "",
    this.orgPicture = "",
    this.branchAddress = "",
    this.status = "",
    this.picture = "", // ⭐ Added
    this.appAccess = "", // ⭐ Added
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      orgUserId: json['org_user_id']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      type: json['type']?.toString() ?? "",
      designation: json['designation']?.toString() ?? "",
      // ⭐ Added
      orgId: json['org_id']?.toString() ?? "",
      branchId: json['branch_id'] != null
          ? int.tryParse(json['branch_id'].toString()) ?? 0
          : 0,
      orgName: json['org_name']?.toString() ?? "",
      branchName: json['branch_name']?.toString() ?? "",
      vatNo: json['vat_no']?.toString() ?? "",
      orgPicture: json['org_picture']?.toString() ?? "",
      branchAddress: json['branch_address']?.toString() ?? "",
      status: json['status']?.toString() ?? "",
      appAccess: json['app_access']?.toString() ?? "",
      picture: json['picture']?.toString() ?? GlobalServiceURL.noImage,
      // ⭐ Added
      permissions: json['permissions'] != null
          ? (json['permissions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, PermissionModel.fromJson(value)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'org_user_id': orgUserId,
    'name': name,
    'email': email,
    'type': type,
    'designation': designation, // ⭐ Added
    'org_id': orgId,
    'branch_id': branchId,
    'org_name': orgName,
    'branch_name': branchName,
    'vat_no': vatNo,
    'org_picture': orgPicture,
    'branch_address': branchAddress,
    'status': status,
    'app_access': appAccess,
    'picture': picture, // ⭐ Added
    'permissions': permissions?.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };
}

//================ Permission Model =================//
class PermissionModel {
  final String module;
  final List<String> rights;

  PermissionModel({this.module = "", this.rights = const []});

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      module: json['module']?.toString() ?? "",
      rights: json['rights'] != null
          ? List<String>.from(json['rights'].map((e) => e.toString()))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {'module': module, 'rights': rights};
}

//-✅---------------------------------------------------------------------✅-//
