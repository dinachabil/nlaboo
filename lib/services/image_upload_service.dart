import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'error_handler.dart';
import 'image_compression_service.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Image size limits
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxLogoSize = 10 * 1024 * 1024; // 10MB
  static const int maxAvatarDimension = 512;
  static const int maxLogoDimension = 1024;

  // Supported image formats
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  /// Uploads an image file to Supabase Storage and returns the public URL
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    try {
      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Validate image
      await _validateImage(imageFile, maxAvatarSize, maxAvatarDimension);

      // Process image (resize and compress)
      final compressedBytes = await ImageCompressionService.compressAvatar(imageFile);
      final processedBytes = compressedBytes ?? await imageFile.readAsBytes();

      // Create a unique filename
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName'; // Use user folder structure

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e, st) {
      // Log the storage/network error and throw a user-friendly message
      ErrorHandler.logError(e, st, 'ImageUploadService.uploadAvatar');

      // Provide more specific error messages
      String errorMessage = 'Failed to upload avatar';
      if (e.toString().contains('Bucket not found')) {
        errorMessage =
            'Avatar storage is not configured. Please run the setup_avatars_bucket.sql script in Supabase.';
      } else if (e.toString().contains('Unauthorized') ||
          e.toString().contains('permission')) {
        errorMessage =
            'You do not have permission to upload avatars. Please check your authentication.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('size') || e.toString().contains('dimension')) {
        errorMessage = e.toString(); // Validation errors are user-friendly
      }

      throw Exception(errorMessage);
    }
  }

  /// Uploads a team logo to Supabase Storage and returns the public URL
  Future<String?> uploadTeamLogo(File imageFile, String teamId) async {
    try {
      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Validate image
      await _validateImage(imageFile, maxLogoSize, maxLogoDimension);

      // Process image (resize and compress)
      final compressedBytes = await ImageCompressionService.compressImage(imageFile);
      final processedBytes = compressedBytes ?? await imageFile.readAsBytes();

      // Create a unique filename
      final fileName = '${teamId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$teamId/$fileName';

      await _supabase.storage
          .from('team-logos')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('team-logos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageUploadService.uploadTeamLogo');

      String errorMessage = 'Failed to upload team logo';
      if (e.toString().contains('Bucket not found')) {
        errorMessage = 'Team logo storage is not configured. Please run the setup_team_logos_bucket.sql script in Supabase.';
      } else if (e.toString().contains('Unauthorized') || e.toString().contains('permission')) {
        errorMessage = 'You do not have permission to upload team logos. Please check your authentication.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('size') || e.toString().contains('dimension')) {
        errorMessage = e.toString(); // Validation errors are user-friendly
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
        ErrorHandler.logError(
          'Could not find "avatars" in URL path',
          null,
          'ImageUploadService.deleteAvatar',
        );
        throw Exception(
          ErrorHandler.userMessage('Could not find "avatars" in URL path'),
        );
      }

      final filePath = pathSegments.sublist(avatarsIndex).join('/');

      await _supabase.storage.from('avatars').remove([filePath]);
    } catch (e, st) {
      // Log and surface a friendly error to callers
      ErrorHandler.logError(e, st, 'ImageUploadService.deleteAvatar');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  /// Deletes a team logo from storage
  Future<void> deleteTeamLogo(String logoUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(logoUrl);
      final pathSegments = uri.pathSegments;
      final logosIndex = pathSegments.indexOf('team-logos');

      if (logosIndex == -1) {
        ErrorHandler.logError(
          'Could not find "team-logos" in URL path',
          null,
          'ImageUploadService.deleteTeamLogo',
        );
        throw Exception(
          ErrorHandler.userMessage('Could not find "team-logos" in URL path'),
        );
      }

      final filePath = pathSegments.sublist(logosIndex).join('/');

      await _supabase.storage.from('team-logos').remove([filePath]);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageUploadService.deleteTeamLogo');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  /// Validates image file
  Future<void> _validateImage(File imageFile, int maxSize, int maxDimension) async {
    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > maxSize) {
      throw Exception('Image file is too large. Maximum size is ${maxSize ~/ (1024 * 1024)}MB.');
    }

    // Check file extension
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    if (!supportedFormats.contains(extension)) {
      throw Exception('Unsupported image format. Supported formats: ${supportedFormats.join(", ")}');
    }

    // Check image dimensions (if possible)
    try {
      // Skip dimension check for now - will be handled during processing
    } catch (e) {
      // If we can't decode, let it pass for now - will be handled during processing
    }
  }

  /// Processes image: resizes and compresses
  Future<Uint8List?> _processImage(File imageFile, int maxDimension, int quality) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Could not decode image. Please ensure it is a valid image file.');
      }

      // Resize if necessary
      img.Image resizedImage = originalImage;
      if (originalImage.width > maxDimension || originalImage.height > maxDimension) {
        resizedImage = img.copyResize(
          originalImage,
          width: originalImage.width > originalImage.height
              ? maxDimension
              : null,
          height: originalImage.height >= originalImage.width
              ? maxDimension
              : null,
          maintainAspect: true,
        );
      }

      // Compress to JPEG
      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
    } catch (e) {
      // Return original bytes if processing fails
      return await imageFile.readAsBytes();
    }
  }
}
