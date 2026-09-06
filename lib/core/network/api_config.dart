import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Configuration for the backend API endpoints.
///
/// Automatically switches between the local ngrok tunnel in debug mode
/// and the production domain in release mode.
class ApiConfig {
  ApiConfig._();

  // The active ngrok proxy tunnel mapped to localhost:8000 for local testing
  static const String debugBaseUrl = 'https://1253-2401-4900-1c5a-185b-615c-154c-1a34-a4d5.ngrok-free.app';
  
  // The production domain deployed for the release builds
  static const String releaseBaseUrl = 'https://banana.aryan.cfd';

  static String? _resolvedDebugBaseUrl;

  /// Returns the appropriate base URL based on the compilation environment.
  static String get baseUrl {
    if (kDebugMode) {
      return _resolvedDebugBaseUrl ?? debugBaseUrl;
    } else {
      return releaseBaseUrl;
    }
  }

  /// Dynamically resolves the debug base URL by querying sh.aryan.cfd/localtesting.
  /// Keep querying until it responds, and then capture the redirection url.
  static Future<void> resolveDebugBaseUrl() async {
    if (!kDebugMode) return;

    final dio = Dio(BaseOptions(
      followRedirects: false,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      validateStatus: (status) => status != null && status < 500,
    ));

    debugPrint('[ApiConfig] Querying sh.aryan.cfd/localtesting for dynamic ngrok URL...');

    while (true) {
      try {
        final response = await dio.get('https://sh.aryan.cfd/localtesting');
        if (response.statusCode != null && response.statusCode! >= 300 && response.statusCode! < 400) {
          final location = response.headers.value('location');
          if (location != null && location.isNotEmpty) {
            if (location.endsWith('/')) {
              _resolvedDebugBaseUrl = location.substring(0, location.length - 1);
            } else {
              _resolvedDebugBaseUrl = location;
            }
            debugPrint('[ApiConfig] Successfully resolved dynamic debug baseUrl: $_resolvedDebugBaseUrl');
            break;
          }
        } else if (response.statusCode == 200) {
          debugPrint('[ApiConfig] Received 200 OK from sh.aryan.cfd/localtesting, expected redirect. Retrying in 2 seconds...');
        } else {
          debugPrint('[ApiConfig] Received status ${response.statusCode} from sh.aryan.cfd/localtesting. Retrying in 2 seconds...');
        }
      } catch (e) {
        debugPrint('[ApiConfig] Failed to resolve debug baseUrl: $e. Retrying in 2 seconds...');
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Forces a fresh dynamic debug URL resolution attempt (one-off, non-blocking).
  static Future<bool> forceResolveDebugBaseUrl() async {
    if (!kDebugMode) return false;

    final dio = Dio(BaseOptions(
      followRedirects: false,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      validateStatus: (status) => status != null && status < 500,
    ));

    debugPrint('[ApiConfig] Forced dynamic debug URL resolution check...');
    try {
      final response = await dio.get('https://sh.aryan.cfd/localtesting');
      if (response.statusCode != null && response.statusCode! >= 300 && response.statusCode! < 400) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          if (location.endsWith('/')) {
            _resolvedDebugBaseUrl = location.substring(0, location.length - 1);
          } else {
            _resolvedDebugBaseUrl = location;
          }
          debugPrint('[ApiConfig] Forced-resolved dynamic debug baseUrl successfully: $_resolvedDebugBaseUrl');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ApiConfig] Forced dynamic debug URL resolution failed: $e');
    }
    return false;
  }
}
