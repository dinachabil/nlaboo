import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _token;
  SharedPreferences? _prefs;

  app_user.User? get currentUser => _currentUser;
  app_user.User? get user => _currentUser; // For compatibility
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null; // For compatibility
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    if (_prefs == null) return;

    final token = _prefs!.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService.setAuthToken(token);
      // Try to restore user data using the token
      try {
        // We need to add a method to ApiService to get user with token
        // For now, we'll assume the token is valid and user is authenticated
        // In a real app, you'd validate the token with the backend
        _isLoading = true;
        notifyListeners();

        // TODO: Add method to get current user with token
        // For now, we'll create a placeholder user
        _currentUser = app_user.User(
          id: 'restored_user',
          name: 'Restored User',
          email: 'user@example.com',
          role: 'player',
          createdAt: DateTime.now(),
        );

        _isLoading = false;
        notifyListeners();
      } catch (e) {
        print('Error loading saved token: $e');
        // If token is invalid, clear it
        await _clearToken();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveToken(String token) async {
    if (_prefs == null) return;
    _token = token;
    await _prefs!.setString('auth_token', token);
    _apiService.setAuthToken(token);
  }

  Future<void> _clearToken() async {
    if (_prefs == null) return;
    _token = null;
    await _prefs!.remove('auth_token');
    _apiService.clearAuthToken();
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
    notifyListeners();

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

      // Assuming the response contains token and user data
      if (response.containsKey('access_token') && response.containsKey('user')) {
        await _saveToken(response['access_token']);
        _currentUser = app_user.User.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true; // Email confirmed
      } else {
        // Email confirmation required
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // Assuming the response contains token and user data
      if (response.containsKey('access_token') && response.containsKey('user')) {
        await _saveToken(response['access_token']);
        _currentUser = app_user.User.fromJson(response['user']);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _clearToken();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? position,
    String? bio,
    String? imageUrl,
    String? gender,
  }) async {
    try {
      final updatedUser = await _apiService.updateProfile(
        name: name,
        position: position,
        bio: bio,
        imageUrl: imageUrl,
        gender: gender,
      );
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}