import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';

/// Representation of client-side configurations retrieved dynamically from the backend.
class AppConfig {
  final String adminEmail;

  AppConfig({required this.adminEmail});

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      adminEmail: json['admin_email'] as String,
    );
  }
}

/// Global FutureProvider that fetches configuration parameters from the server dynamically.
final configProvider = FutureProvider<AppConfig>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/config');
  return AppConfig.fromJson(response.data as Map<String, dynamic>);
});

/// Global FutureProvider that fetches the secure Admin API Key from the backend.
/// Since it requires standard OAuth2 token validation, it will return null
/// if the currently logged-in user is not the authorized administrator.
final adminConfigProvider = FutureProvider<String?>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/api/admin/config');
    final data = response.data as Map<String, dynamic>;
    return data['admin_api_key'] as String;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AdminConfigProvider] Failed to fetch Admin API Key (User not authorized or backend down): $e');
    }
    return null;
  }
});
