// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_call
//-✅---------------------------------------------------------------------✅-//
class StationModel {
  int stationId;
  String stationName;
  String orgId;
  int branchId;

  // Constructor with default values to avoid null
  StationModel({
    this.stationId = 0,
    this.stationName = '',
    this.orgId = '',
    this.branchId = 0,
  });

  // Null-safe fromJson
  factory StationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // Return default object if json itself is null
      return StationModel();
    }

    return StationModel(
      stationId: json['station_id'] is int
          ? json['station_id'] as int
          : int.tryParse(json['station_id']?.toString() ?? '') ?? 0,
      stationName: json['station_name']?.toString() ?? '',
      orgId: json['org_id']?.toString() ?? '',
      branchId: json['branch_id'] is int
          ? json['branch_id'] as int
          : int.tryParse(json['branch_id']?.toString() ?? '') ?? 0,
    );
  }

  // Null-safe toJson
  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'org_id': orgId,
      'branch_id': branchId,
    };
  }
}

//-✅---------------------------------------------------------------------✅-//
