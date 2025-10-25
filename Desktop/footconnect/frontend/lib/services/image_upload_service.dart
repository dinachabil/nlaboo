import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'error_handler.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads an image file to Supabase Storage and returns the public URL
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    try {
      print('Starting avatar upload for user: $userId');

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }
      print('Current authenticated user: ${currentUser.id}');

      // Create a unique filename
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Upload to avatars bucket
      final fileBytes = await imageFile.readAsBytes();
      final filePath = '$userId/$fileName'; // Use user folder structure

      print('Uploading to path: $filePath, file size: ${fileBytes.length} bytes');

      // Determine content type based on file extension
      final extension = path.extension(imageFile.path).toLowerCase();
      String contentType;
      switch (extension) {
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Default fallback
      }

      print('Attempting upload with content type: $contentType');

      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      print('Upload successful, getting public URL');

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e, st) {
      print('Error uploading avatar: $e');
      // Log the storage/network error and throw a user-friendly message
      ErrorHandler.logError(e, st, 'ImageUploadService.uploadAvatar');

      // Provide more specific error messages
      String errorMessage = 'Failed to upload avatar';
      if (e.toString().contains('Bucket not found')) {
        errorMessage = 'Avatar storage is not configured. Please run the setup_avatars_bucket.sql script in Supabase.';
      } else if (e.toString().contains('Unauthorized') || e.toString().contains('permission')) {
        errorMessage = 'You do not have permission to upload avatars. Please check your authentication.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }

      throw Exception(errorMessage);
    }
  }

  /// Deletes an avatar from storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      final avatarsIndex = pathSegments.indexOf('avatars');

      if (avatarsIndex == -1) {
        // Log invalid URL and throw a user-facing error so caller can react
        ErrorHandler.logError('Could not find "avatars" in URL path', null, 'ImageUploadService.deleteAvatar');
        throw Exception(ErrorHandler.userMessage('Could not find "avatars" in URL path'));
      }

      final filePath = pathSegments.sublist(avatarsIndex).join('/');

      await _supabase.storage.from('avatars').remove([filePath]);
    } catch (e, st) {
      // Log and surface a friendly error to callers
      ErrorHandler.logError(e, st, 'ImageUploadService.deleteAvatar');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
}