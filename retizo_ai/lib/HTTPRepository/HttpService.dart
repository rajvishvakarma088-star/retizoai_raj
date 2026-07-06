// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls
import 'dart:io';
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

//-✅---------------------------------------------------------------------✅-//
/// HttpServiceProvider
/// ------------------
/// This provider manages the HTTP client, login state, API requests,
/// and file uploads in a Flutter application.
///
/// Usage:
/// 1. Call startHttpClient() before first API request (auto-start supported)
/// 2. Call closeHttpClient() on logout
/// 3. Use request() or uploadImage() to interact with API
class HttpServiceProvider extends ChangeNotifier {
  /// Internal HTTP client
  late http.Client _client;

  /// Tracks whether HTTP client is active (login state)
  bool isApiActiveFlag = false;

  /// Constructor initializes the HTTP client
  HttpServiceProvider() {
    _client = _buildClient();
  }

  /// Creates a custom HTTP client that trusts all SSL certificates.
  /// Real Android devices on release builds enforce strict TLS validation;
  /// the backend runs on a non-standard port (6050) which can cause
  /// handshake failures even with valid certificates.
  http.Client _buildClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  /// Getter for client active state
  bool get isApiActive => isApiActiveFlag;

  /// Default headers for all API requests
  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // ------------------- HTTP Client Start / Stop -------------------

  /// Starts the HTTP client (login)
  void startHttpClient() {
    isApiActiveFlag = true;
    _client = _buildClient();
    notifyListeners();
  }

  /// Closes the HTTP client (logout)
  void closeHttpClient() {
    isApiActiveFlag = false;
    _client.close();
    GlobalFunction().debugFunction("🔒 HTTP client closed / User logged out");
    notifyListeners();
  }

  /// Manually dispose HTTP client if needed
  void disposeClient() {
    _client.close();
    GlobalFunction().debugFunction("🗑️ HTTP client manually disposed");
  }

  // ------------------- HTTP Requests -------------------

  /// Generic HTTP request method
  /// [requireLogin] → true if this request requires active HTTP client
  Future<T> request<T>({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required BuildContext context,
    bool requireLogin = true,
    bool ignoreUnauthorized = false,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (requireLogin && !isApiActiveFlag) startHttpClient();

    final uri = Uri.parse(url);
    final combinedHeaders = {
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    // Retry loop: attempt 0 = normal try; attempt 1 = retry after stale connection
    for (int _attempt = 0; _attempt <= 1; _attempt++) {
      try {
        _logRequestDetails(method, url, combinedHeaders, body);

        late http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await _client
                .get(uri, headers: combinedHeaders)
                .timeout(timeout);
            break;
          case 'POST':
            response = await _client
                .post(uri, headers: combinedHeaders, body: jsonEncode(body))
                .timeout(timeout);
            break;
          case 'PUT':
            response = await _client
                .put(uri, headers: combinedHeaders, body: jsonEncode(body))
                .timeout(timeout);
            break;
          case 'PATCH':
            response = await _client
                .patch(uri, headers: combinedHeaders, body: jsonEncode(body))
                .timeout(timeout);
            break;
          case 'DELETE':
            response = await _client
                .delete(uri, headers: combinedHeaders)
                .timeout(timeout);
            break;
          default:
            throw UnsupportedError('Unsupported HTTP method: $method');
        }

        _logResponseDetails(response);

        // 🔹 Parse response dynamically
        final dynamic jsonBody = json.decode(response.body);

        // 🔒 401 Unauthorized — token expired/invalid → force logout and navigate to Login
        if (response.statusCode == 401 && !ignoreUnauthorized) {
          _handleUnauthorized(context);
          throw Exception('Session expired. Please login again.');
        }

        // ✅ Success codes
        if ([200, 201].contains(response.statusCode)) {
          return jsonBody as T;
        }

        // ✅ Client errors
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return jsonBody as T;
        }

        // ✅ Server errors
        if (response.statusCode >= 500) {
          throw Exception(
            'Server error ${response.statusCode}: ${jsonBody['message'] ?? response.body}',
          );
        }

        return jsonBody as T;
      } catch (e) {
        // On the first attempt only: if the server closed a keep-alive connection
        // (common immediately after a POST response), rebuild the client and retry
        // once with a fresh socket — no user-visible delay or error shown.
        final errStr = e.toString();
        if (_attempt == 0 &&
            (errStr.contains('Connection closed') ||
                errStr.contains('Connection reset'))) {
          GlobalFunction().debugFunction(
            '🔄 Stale connection detected, retrying with fresh connection...',
          );
          _client = _buildClient();
          continue;
        }
        GlobalFunction().debugFunction("❌ Request failed: $e");
        rethrow;
      }
    }
    // Unreachable in practice — loop always returns or rethrows.
    throw StateError('Unreachable: request loop exhausted');
  }

  /// Upload image using multipart/form-data
  Future<http.Response> uploadImage({
    required BuildContext context,
    required Uri uri,
    required File imageFile,
    required String imageKey,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!isApiActiveFlag) {
      throw Exception('User not logged in. Upload blocked.');
    }

    var request = http.MultipartRequest(method, uri)
      ..headers.addAll(headers ?? {});

    if (body != null) {
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });
    }

    final image = await http.MultipartFile.fromPath(imageKey, imageFile.path);
    request.files.add(image);

    // Debug logs
    GlobalFunction().debugFunction('📤 Uploading Image...');
    GlobalFunction().debugFunction('🔸 URL: $uri');
    GlobalFunction().debugFunction('🔸 Method: $method');
    GlobalFunction().debugFunction('🔸 Headers: ${headers.toString()}');
    GlobalFunction().debugFunction('🔸 Body: ${body.toString()}');
    GlobalFunction().debugFunction('🔸 Image: ${imageFile.path}');

    try {
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logResponseDetails(response);

      return response;
    } catch (e) {
      GlobalFunction().debugFunction("❌ Upload failed: $e");
      rethrow;
    }
  }

  // ------------------- Unauthorized (401) Handler -------------------

  bool _isHandlingUnauthorized = false;

  void _handleUnauthorized(BuildContext context) {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    closeHttpClient();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navContext = navigatorKey.currentContext;
      if (navContext != null) {
        try {
          await Provider.of<UserInfoProvider>(
            navContext,
            listen: false,
          ).Logout();
        } catch (_) {}
      }
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      Future.delayed(const Duration(seconds: 3), () {
        _isHandlingUnauthorized = false;
      });
    });
  }

  // ------------------- Logging -------------------

  void _logRequestDetails(
    String method,
    String url,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    if (kDebugMode) {
      GlobalFunction().debugFunction('\n📤 REQUEST START');
      GlobalFunction().debugFunction('🔸 Method: $method');
      GlobalFunction().debugFunction('🔸 URL: $url');
      GlobalFunction().debugFunction('🔸 Headers:');
      headers.forEach(
        (key, value) => GlobalFunction().debugFunction('   $key: $value'),
      );
      GlobalFunction().debugFunction(
        '🔸 Body: ${body != null ? jsonEncode(body) : "None"}',
      );
    }
  }

  void _logResponseDetails(http.Response response) {
    if (kDebugMode) {
      GlobalFunction().debugFunction('\n📥 RESPONSE RECEIVED');
      GlobalFunction().debugFunction('🔸 Status Code: ${response.statusCode}');
      try {
        final jsonBody = json.decode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonBody);
        GlobalFunction().debugFunction('🔸 Body:\n$prettyJson');
      } catch (_) {
        GlobalFunction().debugFunction('🔸 Body: ${response.body}');
      }
      GlobalFunction().debugFunction('📥 RESPONSE END\n');
    }
  }
}

//-✅---------------------------------------------------------------------✅-//
