import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_config.dart';
import 'auth_provider.dart';

/// Global provider for the Dio HTTP client configured with the appropriate
/// baseUrl, headers, and interceptors for logging and Auth0 token attachments.
final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Bypasses the ngrok landing page warning programmatically so the client resolves raw JSON payloads
      'ngrok-skip-browser-warning': 'true',
    },
  );

  final dio = Dio(options);

  // Integrate request interceptors to automatically append authorization headers and log telemetry
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (kDebugMode) {
        debugPrint('--> Dio Request: [${options.method}] ${options.uri}');
        debugPrint('Headers: ${options.headers}');
      }

      // Read the current Auth0 state
      final auth = ref.read(authProvider);
      
      if (kDebugMode) {
        final idToken = auth.credentials?.idToken;
        final accessToken = auth.accessToken;
        debugPrint('[InterceptorsWrapper] Auth Status: authenticated=${auth.isAuthenticated}');
        debugPrint('[InterceptorsWrapper] idToken: ${idToken != null ? "present (len: ${idToken.length}, segments: ${idToken.split('.').length})" : "null"}');
        debugPrint('[InterceptorsWrapper] accessToken: ${accessToken != null ? "present (len: ${accessToken.length}, segments: ${accessToken.split('.').length})" : "null"}');
      }
      
      // Send the Access Token (the standard OAuth2 token carrying the custom API audience)
      final token = auth.accessToken;
      
      if (auth.isAuthenticated && token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        // Fallback static identifier for offline/testing stages
        options.headers['X-Mock-User-Id'] = 'auth0|mock_user_123';
        options.headers['Authorization'] = 'Bearer mock-auth-token';
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      if (kDebugMode) {
        debugPrint('<-- Dio Response: [${response.statusCode}] ${response.requestOptions.uri}');
      }
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      if (kDebugMode) {
        debugPrint('[!] Dio Network Error: ${e.message} for [${e.requestOptions.method}] ${e.requestOptions.uri}');
        if (e.response != null) {
          debugPrint('Status Code: ${e.response?.statusCode}');
          debugPrint('Error Payload: ${e.response?.data}');
        }
      }
      return handler.next(e);
    },
  ));

  return dio;
});
