import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';

/// Representation of the authentication state across the application.
class AuthState {
  AuthState({
    this.credentials,
    this.isLoading = false,
    this.errorMessage,
  });

  final Credentials? credentials;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => credentials != null;
  UserProfile? get user => credentials?.user;
  String? get accessToken => credentials?.accessToken;

  AuthState copyWith({
    Credentials? credentials,
    bool? isLoading,
    String? errorMessage,
    bool clearCredentials = false,
  }) {
    return AuthState(
      credentials: clearCredentials ? null : (credentials ?? this.credentials),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Riverpod Notifier managing our Auth0 state and CredentialsManager interactions.
class AuthNotifier extends Notifier<AuthState> {
  late final Auth0 _auth0;

  @override
  AuthState build() {
    _auth0 = Auth0(
      'dev-3pc3mxrpo2gnszza.us.auth0.com',
      'DjRONeH4vcG2lNYy8sLtil9DrPOZ7CXl',
    );
    
    // Automatically attempt to restore safe cached credentials asynchronously
    // on the next microtask tick once the notifier is fully built.
    Future.microtask(() => _restoreSession());
    
    return AuthState();
  }

  /// RESTORE SESSION: Quietly check the platform secure storage keychain/keystore
  /// for a valid non-expired access token to auto-log in the user.
  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final hasValid = await _auth0.credentialsManager.hasValidCredentials();
      if (hasValid) {
        final creds = await _auth0.credentialsManager.credentials();
        state = state.copyWith(credentials: creds, isLoading: false);
        _syncUserProfile(creds);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore session from storage: $e',
      );
    }
  }

  /// LOGIN: Trigger the secure platform-native web auth login flow with PKCE code challenge.
  Future<void> login() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final creds = await _auth0
          .webAuthentication(scheme: 'com.cyto.banana')
          .login(
            audience: 'https://banana-api',
            scopes: {'openid', 'profile', 'email', 'offline_access'},
          );
      
      state = state.copyWith(credentials: creds, isLoading: false);
      _syncUserProfile(creds);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// LOGOUT: Trigger web logout to clear the browser session and wipe keychain tokens.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _auth0.webAuthentication(scheme: 'com.cyto.banana').logout();
      await _auth0.credentialsManager.clearCredentials();
      state = AuthState(); // Reset to initial empty free state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear session: $e',
      );
    }
  }

  /// SYNC PROFILE: Send the authenticated user's email and name to the backend
  /// to create/update their profile shell in the database.
  Future<void> _syncUserProfile(Credentials creds) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/api/users/sync',
        data: {
          'email': creds.user.email ?? 'user@example.com',
          'name': creds.user.name ?? 'Auth0 Reader',
        },
      );
      if (kDebugMode) {
        debugPrint('[AuthNotifier] Successfully synchronized user profile with backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthNotifier] User profile synchronization failed: $e');
      }
    }
  }
}

/// Global provider for the active user authentication state.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
