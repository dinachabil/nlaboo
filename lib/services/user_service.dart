import 'dart:io';
import 'dart:typed_data';
import '../models/user.dart' as app_user;
import '../models/notification.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<app_user.User> getCurrentUser() async {
    return _userRepository.getCurrentUser();
  }

  Future<app_user.User> getUserById(String userId) async {
    return _userRepository.getUserById(userId);
  }

  Future<app_user.User> getUser(String userId) async {
    return _userRepository.getUser(userId);
  }

  Future<List<app_user.User>> getAllUsers() async {
    return _userRepository.getAllUsers();
  }

  Future<void> deleteUser(String userId) async {
    return _userRepository.deleteUser(userId);
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
    // Business logic validation
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    if (age != null && (age < 13 || age > 100)) {
      throw ArgumentError('Age must be between 13 and 100');
    }

    if (phone != null &&
        phone.isNotEmpty &&
        !RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(phone)) {
      throw ArgumentError('Invalid phone number format');
    }

    return _userRepository.updateProfile(
      name: name?.trim(),
      position: position?.trim(),
      bio: bio?.trim(),
      imageUrl: imageUrl,
      gender: gender,
      phone: phone?.trim(),
      age: age,
      location: location?.trim(),
    );
  }

  Future<String?> uploadAvatar(File imageFile) async {
    // Business logic validation
    if (!imageFile.existsSync()) {
      throw ArgumentError('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      // 5MB limit
      throw ArgumentError('Image file size must be less than 5MB');
    }

    return _userRepository.uploadAvatar(imageFile);
  }

  Future<String?> uploadAvatarBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    // Business logic validation
    if (imageBytes.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      // 5MB limit
      throw ArgumentError('Image data size must be less than 5MB');
    }

    return _userRepository.uploadAvatarBytes(imageBytes, filename);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    return _userRepository.getUserStats();
  }

  Future<List<NotificationModel>> getNotifications() async {
    return _userRepository.getNotifications();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    return _userRepository.markNotificationAsRead(notificationId);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    // Business logic validation
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    if (title.trim().isEmpty) {
      throw ArgumentError('Notification title cannot be empty');
    }

    if (message.trim().isEmpty) {
      throw ArgumentError('Notification message cannot be empty');
    }

    final validTypes = ['info', 'warning', 'error', 'success'];
    if (!validTypes.contains(type)) {
      throw ArgumentError('Invalid notification type: $type');
    }

    return _userRepository.createNotification(
      userId: userId.trim(),
      title: title.trim(),
      message: message.trim(),
      type: type,
      relatedId: relatedId,
    );
  }
}
