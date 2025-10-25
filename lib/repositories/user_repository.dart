import 'dart:io';
import 'dart:typed_data';
import '../models/user.dart' as app_user;
import '../models/notification.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<app_user.User> getCurrentUser() async {
    return _apiService.getCurrentUser();
  }

  Future<app_user.User> getUserById(String userId) async {
    return _apiService.getUserById(userId);
  }

  Future<app_user.User> getUser(String userId) async {
    return _apiService.getUser(userId);
  }

  Future<List<app_user.User>> getAllUsers() async {
    return _apiService.getAllUsers();
  }

  Future<void> deleteUser(String userId) async {
    return _apiService.deleteUser(userId);
  }

  Future<app_user.User> updateProfile({
    String? name,
    String? position,
    String? bio,
    String? imageUrl,
    String? gender,
    String? phone,
    int? age,
    String? location,
  }) async {
    // Repository-level validation before calling API
    if (name != null) {
      final nameError = validateName(name);
      if (nameError != null) throw ArgumentError(nameError);
    }

    if (phone != null && phone.isNotEmpty) {
      final phoneError = validatePhoneOptional(phone);
      if (phoneError != null) throw ArgumentError(phoneError);
    }

    if (age != null) {
      final ageError = validateAgeOptional(age.toString());
      if (ageError != null) throw ArgumentError(ageError);
    }

    if (location != null && location.isNotEmpty) {
      final locationError = validateLocation(location);
      if (locationError != null) throw ArgumentError(locationError);
    }

    if (gender != null && !['male', 'female', 'other'].contains(gender)) {
      throw ArgumentError('Gender must be male, female, or other');
    }

    return _apiService.updateProfile(
      name: name,
      position: position,
      bio: bio,
      imageUrl: imageUrl,
      gender: gender,
      phone: phone,
      age: age,
      location: location,
    );
  }

  Future<String?> uploadAvatar(File imageFile) async {
    return _apiService.uploadAvatar(imageFile);
  }

  Future<String?> uploadAvatarBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    return _apiService.uploadAvatarBytes(imageBytes, filename);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    return _apiService.getUserStats();
  }

  Future<List<NotificationModel>> getNotifications() async {
    return _apiService.getNotifications();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    return _apiService.markNotificationAsRead(notificationId);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    return _apiService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
    );
  }
}
