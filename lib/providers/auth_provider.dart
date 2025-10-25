import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
   final ApiService _apiService = ApiService();
   app_user.User? _currentUser;
   bool _isLoading = false;
   final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

   // Debug logging
   void _log(String message, {String? context, dynamic error}) {
     final timestamp = DateTime.now().toIso8601String();
     final logMessage = '[AuthProvider:$timestamp] $message';
     if (context != null) {
       debugPrint('$logMessage (Context: $context)');
     } else {
       debugPrint(logMessage);
     }
     if (error != null) {
       debugPrint('$logMessage Error: $error');
     }
   }


  void _safeNotifyListeners() {
    // Only notify if there are active listeners to prevent assertion errors
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Clean up resources when the provider is disposed
    _profileSubscription?.cancel();
    _apiService.dispose();
    _currentUser = null;
    super.dispose();
  }

  app_user.User? get currentUser => _currentUser;
  app_user.User? get user => _currentUser; // For compatibility
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null; // For compatibility
  bool get isAdmin => _currentUser?.role == 'admin';

  // Add token getter for backward compatibility with tests
  String? get token => null; // Supabase handles tokens automatically

  AuthProvider() {
    _initialize();
  }

  StreamSubscription? _profileSubscription;

  void _initializeRealtimeUpdates() {
    // Only setup real-time updates if user is authenticated
    if (_currentUser == null) return;

    // Cancel existing subscription to prevent duplicates
    _profileSubscription?.cancel();

    _profileSubscription = _apiService.userProfileStream.listen(
      (user) {
        if (user != null) {
          _currentUser = user;
          _isLoading = false;
          _safeNotifyListeners();
        }
      },
      onError: (error) {
        _isLoading = false;
        _safeNotifyListeners();
      },
    );
  }

  Future<void> _initialize() async {
    // Commented out to preserve authentication between app restarts
    // await clearAllStoredData();
    await _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
     _log('Loading saved authentication state', context: 'loadSavedToken');
     // With Supabase, token management is handled automatically
     // We just need to check if user is authenticated
     try {
       _isLoading = true;
       _safeNotifyListeners();

       _log('Attempting to get current user from ApiService', context: 'loadSavedToken');
       final user = await _apiService.getCurrentUser();
       _currentUser = user;
       _log('Current user loaded successfully: ${user?.name ?? 'null'}', context: 'loadSavedToken');

       // Initialize real-time updates only after successful authentication
       if (_currentUser != null) {
         _log('Initializing real-time updates for authenticated user', context: 'loadSavedToken');
         _initializeRealtimeUpdates();
         // Initialize real-time subscriptions in ApiService
         _apiService.initializeRealtimeSubscriptions();
       } else {
         _log('No authenticated user found', context: 'loadSavedToken');
       }
     } catch (e) {
       // User not authenticated - this is expected on first launch
       // FIXED: Don't log this as an error since it's expected behavior
       _log('Authentication check failed (expected for first launch)', context: 'loadSavedToken', error: e);
       _currentUser = null;
     } finally {
       _isLoading = false;
       _safeNotifyListeners();
     }
   }

  // Token management is now handled automatically by Supabase client
  // These methods are kept for backward compatibility but don't store tokens
  Future<void> _saveToken(String token) async {
    // Supabase handles token storage automatically
  }

  Future<void> _clearToken() async {
    // Supabase handles token clearing automatically
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    int? age,
    String? phone,
    String? gender,
    String? role,
  }) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final response = await _apiService.signup(
        name: name,
        email: email,
        password: password,
        age: age,
        phone: phone,
        gender: gender,
        role: role ?? 'player',
      );

      // Handle Supabase Auth response structure
      if (response.containsKey('user')) {
        final userData = response['user'];
        final sessionData = response['session'];

        // Create user object from response
        _currentUser = app_user.User.fromJson(userData);

        // Store session token if available (for confirmed accounts)
        if (sessionData != null && sessionData.containsKey('access_token')) {
          await _saveToken(sessionData['access_token']);
          _isLoading = false;
          _safeNotifyListeners();
          return true; // Email confirmed and session active
        } else {
          // Email confirmation required - user created but not confirmed
          _isLoading = false;
          _safeNotifyListeners();
          return false; // Email confirmation pending
        }
      } else {
        throw Exception('Signup failed: No user data returned');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.signup');
      _isLoading = false;
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
     _log('Starting login process', context: 'login');
     _isLoading = true;
     _safeNotifyListeners();

     try {
       _log('Calling ApiService.login', context: 'login');
       final response = await _apiService.login(
         email: email,
         password: password,
       );

       _log('Login response received', context: 'login');

       // FIXED: Check for 'session' instead of 'access_token' to match Supabase Auth response
       if (response.containsKey('session') && response.containsKey('user')) {
         _log('Login successful, processing session data', context: 'login');
         final session = response['session'];
         if (session != null && session.containsKey('access_token')) {
           await _saveToken(session['access_token']);
         }
         _currentUser = app_user.User.fromJson(response['user']);
         _log('User set: ${_currentUser?.name}', context: 'login');

         // Initialize real-time updates after successful login
         _log('Initializing real-time updates', context: 'login');
         _initializeRealtimeUpdates();
         // Initialize real-time subscriptions in ApiService
         _apiService.initializeRealtimeSubscriptions();
       } else {
         _log('Login response missing required fields', context: 'login');
       }

       _isLoading = false;
       _safeNotifyListeners();
     } catch (e, st) {
       _log('Login failed', context: 'login', error: e);
       ErrorHandler.logError(e, st, 'AuthProvider.login');
       _isLoading = false;
       _safeNotifyListeners();
       rethrow;
     }
   }

  /// Login with enhanced error handling and user feedback
  Future<void> loginWithFeedback(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // Assuming the response contains token and user data
      if (response.containsKey('access_token') &&
          response.containsKey('user')) {
        await _saveToken(response['access_token']);
        _currentUser = app_user.User.fromJson(response['user']);
      }

      _isLoading = false;
      _safeNotifyListeners();

      // Show success feedback
      if (context.mounted) {
        // Note: context.showSuccess is not a standard Flutter method
        // This should be replaced with proper ScaffoldMessenger usage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.loginWithFeedback');
      _isLoading = false;
      _safeNotifyListeners();

      // Show error feedback
      if (context.mounted) {
        // Note: context.showError is not a standard Flutter method
        // This should be replaced with proper ScaffoldMessenger usage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () =>
                  loginWithFeedback(context, email: email, password: password),
            ),
          ),
        );
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    // Clean up real-time subscriptions before logout
    _profileSubscription?.cancel();
    await _apiService.dispose();

    await _clearToken();
    _currentUser = null;
    _safeNotifyListeners();
  }

  Future<bool> logoutWithConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(true);
                await logout();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> clearAllStoredData() async {
    await _secureStorage.deleteAll();
    _currentUser = null;
    // Auth token is now handled automatically by Supabase client
    _safeNotifyListeners();
  }

  // Debug method to force clear stored data (for development)
  Future<void> forceClearStoredData() async {
    await clearAllStoredData();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      _safeNotifyListeners();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.refreshUser');
      rethrow;
    }
  }

  Future<void> updateProfile({
     String? name,
     String? position,
     String? bio,
     String? imageUrl,
     String? gender,
     String? phone,
     int? age,
     String? location,
   }) async {
     _log('Starting profile update', context: 'updateProfile');
     try {
       _log('Calling ApiService.updateProfile', context: 'updateProfile');
       final updatedUser = await _apiService.updateProfile(
         name: name,
         position: position,
         bio: bio,
         imageUrl: imageUrl,
         gender: gender,
         phone: phone,
         age: age,
         location: location,
       );
       _currentUser = updatedUser;
       _log('Profile updated successfully', context: 'updateProfile');

       _safeNotifyListeners();
     } catch (e, st) {
       _log('Profile update failed', context: 'updateProfile', error: e);
       ErrorHandler.logError(e, st, 'AuthProvider.updateProfile');
       rethrow;
     }
   }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return await _apiService.getUserStats();
    } catch (e, st) {
      // Log the error but return safe defaults
      ErrorHandler.logError(e, st, 'AuthProvider.getUserStats');
      return {'matches_joined': 0, 'matches_created': 0, 'teams_owned': 0};
    }
  }
}
