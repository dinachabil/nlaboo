import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final UserRepository _userRepository;
  final ApiService _apiService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._userRepository, this._apiService) {
    _initializeRealtimeUpdates();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _initializeRealtimeUpdates() {
    _apiService.userNotificationsStream.listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    ).onDone(() {
      // Handle stream completion (connection lost)
      _error = 'Connection lost. Attempting to reconnect...';
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        if (_notifications.isEmpty) {
          loadNotifications();
        }
      });
    });
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _userRepository.getNotifications();
      _notifications = notifications;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _userRepository.markNotificationAsRead(notificationId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _userRepository.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
      );
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}