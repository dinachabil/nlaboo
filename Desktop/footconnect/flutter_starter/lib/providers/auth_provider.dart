import 'package:flutter/material.dart';

class User {
  final String email;
  final String role;

  User({required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
    };
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication - in real app, this would call your API
    if (email.isNotEmpty && password.isNotEmpty) {
      _user = User(email: email, role: email.contains('admin') ? 'admin' : 'user');
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> signup(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock signup - in real app, this would call your API
    if (email.isNotEmpty && password.isNotEmpty) {
      _user = User(email: email, role: 'user');
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Invalid data');
    }
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}