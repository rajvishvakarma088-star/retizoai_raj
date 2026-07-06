// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures
//-✅-SecureStorageService------------------------------------------------✅-//
import 'dart:convert';

import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // ✅ Secure Storage Initialization with Platform Options
  static final FlutterSecureStorage SecureStorage = FlutterSecureStorage(
    aOptions: _getAndroidOptions(),
    iOptions: _getIOSOptions(),
    mOptions: _getMacOptions(),
    webOptions: _getWebOptions(),
  );

  static bool _hasLoggedOnce = false;

  // ---------- Platform Specific Options ---------- //
  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true, // Android storage
  );

  static IOSOptions _getIOSOptions() => const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock, // iOS Keychain
  );

  static MacOsOptions _getMacOptions() =>
      const MacOsOptions(accessibility: KeychainAccessibility.first_unlock);

  static WebOptions _getWebOptions() =>
      const WebOptions(dbName: 'SecureStorageDB');

  // 🔹 Write data
  static Future<void> Write(String key, dynamic value) async {
    try {
      final data = jsonEncode(value);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, data);
      } else {
        await SecureStorage.write(key: key, value: data);
      }

      if (!_hasLoggedOnce) {
        _hasLoggedOnce = true;
      }
    } catch (e) {
      GlobalFunction().debugFunction(
        "❌ UserProfile Info Key: $key | Error: $e",
      );
    }
  }

  // 🔹 Read data
  static Future<dynamic> Read(String key) async {
    try {
      String? data;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        data = prefs.getString(key);
      } else {
        data = await SecureStorage.read(key: key);
      }

      if (data == null) {
        GlobalFunction().debugFunction("Key: $key not found");
        return null;
      }

      final decoded = jsonDecode(data);
      return decoded;
    } catch (e) {
      GlobalFunction().debugFunction(
        "❌ [SecureStorage Read Error] Key: $key | Error: $e",
      );
      return null;
    }
  }

  // 🔹 Delete specific key
  static Future<void> Delete(String key) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } else {
        await SecureStorage.delete(key: key);
      }
    } catch (e) {
      GlobalFunction().debugFunction(
        "❌ [SecureStorage Delete Error] Key: $key | Error: $e",
      );
    }
  }

  // 🔹 Clear all data (Logout time)
  static Future<void> ClearAll() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } else {
        await SecureStorage.deleteAll();
      }

      _hasLoggedOnce = false; // reset flag after clearing
    } catch (e) {
      GlobalFunction().debugFunction(
        "❌ [SecureStorage ClearAll Error] Error: $e",
      );
    }
  }

  // 🔹 Reset logger manually
  static void resetLogger() {
    _hasLoggedOnce = false;
  }
}

//-✅---------------------------------------------------------------------✅-//
