// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, strict_top_level_inference

//-✅---------------------------------------------------------------------✅-//
class APIHelper {
  /// 🔹 Common headers builder
  static Map<String, String> buildAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 🔹 Optional: Without token (for pre-login APIs)
  static Map<String, String> buildBasicHeaders() {
    return {'Content-Type': 'application/json'};
  }
}

//-✅---------------------------------------------------------------------✅-//
