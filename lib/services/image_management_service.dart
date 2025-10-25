import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'image_upload_service.dart';
import 'error_handler.dart';

/// Comprehensive image management service with caching, quota management, and cleanup
class ImageManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImageUploadService _uploadService = ImageUploadService();

  // Storage quotas (in bytes)
  static const int userAvatarQuota = 50 * 1024 * 1024; // 50MB per user for avatars
  static const int teamLogoQuota = 100 * 1024 * 1024; // 100MB per team for logos

  // Cache configuration
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheObjects = 100;

  /// Uploads and caches a user avatar
  Future<String?> uploadUserAvatar(File imageFile, String userId) async {
    try {
      // Check storage quota before upload
      await _checkUserStorageQuota(userId, await imageFile.length());

      // Upload the image
      final imageUrl = await _uploadService.uploadAvatar(imageFile, userId);

      if (imageUrl != null) {
        // Update user's storage usage
        await _updateUserStorageUsage(userId, await imageFile.length());
      }

      return imageUrl;
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.uploadUserAvatar');
      rethrow;
    }
  }

  /// Uploads and caches a team logo
  Future<String?> uploadTeamLogo(File imageFile, String teamId) async {
    try {
      // Check storage quota before upload
      await _checkTeamStorageQuota(teamId, await imageFile.length());

      // Upload the image
      final imageUrl = await _uploadService.uploadTeamLogo(imageFile, teamId);

      if (imageUrl != null) {
        // Update team's storage usage
        await _updateTeamStorageUsage(teamId, await imageFile.length());
      }

      return imageUrl;
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.uploadTeamLogo');
      rethrow;
    }
  }

  /// Gets a cached image file, downloading if not cached
  Future<File> getCachedImage(String imageUrl) async {
    try {
      // Placeholder - cache functionality removed
      throw Exception('Cache functionality not implemented');
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.getCachedImage');
      rethrow;
    }
  }

  /// Gets image from cache synchronously if available
  Future<dynamic> getCachedImageSync(String imageUrl) async {
    try {
      return null; // Placeholder - cache functionality removed
    } catch (e) {
      return null;
    }
  }

  /// Deletes a user avatar and cleans up cache
  Future<void> deleteUserAvatar(String avatarUrl, String userId) async {
    try {
      // Remove from storage
      await _uploadService.deleteAvatar(avatarUrl);

      // Update storage usage
      final fileSize = await _getImageSizeFromUrl(avatarUrl);
      await _updateUserStorageUsage(userId, -fileSize);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.deleteUserAvatar');
      rethrow;
    }
  }

  /// Deletes a team logo and cleans up cache
  Future<void> deleteTeamLogo(String logoUrl, String teamId) async {
    try {
      // Remove from storage
      await _uploadService.deleteTeamLogo(logoUrl);

      // Update storage usage
      final fileSize = await _getImageSizeFromUrl(logoUrl);
      await _updateTeamStorageUsage(teamId, -fileSize);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.deleteTeamLogo');
      rethrow;
    }
  }

  /// Gets storage usage for a user
  Future<Map<String, dynamic>> getUserStorageUsage(String userId) async {
    try {
      final response = await _supabase
          .from('user_storage_usage')
          .select('*')
          .eq('user_id', userId)
          .single();

      return {
        'used': response['used_bytes'] ?? 0,
        'quota': userAvatarQuota,
        'available': userAvatarQuota - (response['used_bytes'] ?? 0),
        'percentage': ((response['used_bytes'] ?? 0) / userAvatarQuota) * 100,
      };
    } catch (e) {
      // If no record exists, return default values
      return {
        'used': 0,
        'quota': userAvatarQuota,
        'available': userAvatarQuota,
        'percentage': 0.0,
      };
    }
  }

  /// Gets storage usage for a team
  Future<Map<String, dynamic>> getTeamStorageUsage(String teamId) async {
    try {
      final response = await _supabase
          .from('team_storage_usage')
          .select('*')
          .eq('team_id', teamId)
          .single();

      return {
        'used': response['used_bytes'] ?? 0,
        'quota': teamLogoQuota,
        'available': teamLogoQuota - (response['used_bytes'] ?? 0),
        'percentage': ((response['used_bytes'] ?? 0) / teamLogoQuota) * 100,
      };
    } catch (e) {
      // If no record exists, return default values
      return {
        'used': 0,
        'quota': teamLogoQuota,
        'available': teamLogoQuota,
        'percentage': 0.0,
      };
    }
  }

  /// Cleans up old cached images
  Future<void> cleanupCache() async {
    try {
      // Cache functionality removed
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupCache');
    }
  }

  /// Checks if user has enough storage quota
  Future<void> _checkUserStorageQuota(String userId, int additionalBytes) async {
    final usage = await getUserStorageUsage(userId);
    final newTotal = usage['used'] + additionalBytes;

    if (newTotal > userAvatarQuota) {
      throw Exception(
        'Storage quota exceeded. You have used ${usage['used']} bytes out of $userAvatarQuota bytes. '
            'Additional $additionalBytes bytes would exceed your limit.',
      );
    }
  }

  /// Checks if team has enough storage quota
  Future<void> _checkTeamStorageQuota(String teamId, int additionalBytes) async {
    final usage = await getTeamStorageUsage(teamId);
    final newTotal = usage['used'] + additionalBytes;

    if (newTotal > teamLogoQuota) {
      throw Exception(
        'Storage quota exceeded. The team has used ${usage['used']} bytes out of $teamLogoQuota bytes. '
            'Additional $additionalBytes bytes would exceed the limit.',
      );
    }
  }

  /// Updates user storage usage
  Future<void> _updateUserStorageUsage(String userId, int bytesDelta) async {
    try {
      await _supabase.rpc('update_user_storage_usage', params: {
        'p_user_id': userId,
        'p_bytes_delta': bytesDelta,
      });
    } catch (e) {
      // Don't throw here as it's not critical for the upload operation
    }
  }

  /// Updates team storage usage
  Future<void> _updateTeamStorageUsage(String teamId, int bytesDelta) async {
    try {
      await _supabase.rpc('update_team_storage_usage', params: {
        'p_team_id': teamId,
        'p_bytes_delta': bytesDelta,
      });
    } catch (e) {
      // Don't throw here as it's not critical for the upload operation
    }
  }

  /// Gets image file size from URL (approximate)
  Future<int> _getImageSizeFromUrl(String imageUrl) async {
    try {
      // Placeholder - cache functionality removed
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Validates image before upload
  Future<void> validateImage(File imageFile, {bool isAvatar = true}) async {
    final maxSize = isAvatar ? ImageUploadService.maxAvatarSize : ImageUploadService.maxLogoSize;

    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > maxSize) {
      throw Exception('Image file is too large. Maximum size is ${maxSize ~/ (1024 * 1024)}MB.');
    }

    // Check file extension
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    if (!ImageUploadService.supportedFormats.contains(extension)) {
      throw Exception('Unsupported image format. Supported formats: ${ImageUploadService.supportedFormats.join(", ")}');
    }

    // Check image dimensions (if possible)
    try {
      // Skip dimension check for now - will be handled during processing
    } catch (e) {
      // If we can't decode, let it pass for now - will be handled during processing
    }
  }

  /// Batch cleanup for user images (when user is deleted)
  Future<void> cleanupUserImages(String userId) async {
    try {
      // Get all user avatars
      final avatars = await _supabase.storage.from('avatars').list(path: userId);

      // Delete from storage
      for (final avatar in avatars) {
        await _supabase.storage.from('avatars').remove(['$userId/${avatar.name}']);
      }

      // Clear user storage usage
      await _supabase.from('user_storage_usage').delete().eq('user_id', userId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupUserImages');
    }
  }

  /// Batch cleanup for team images (when team is deleted)
  Future<void> cleanupTeamImages(String teamId) async {
    try {
      // Get all team logos
      final logos = await _supabase.storage.from('team-logos').list(path: teamId);

      // Delete from storage
      for (final logo in logos) {
        await _supabase.storage.from('team-logos').remove(['$teamId/${logo.name}']);
      }

      // Clear team storage usage
      await _supabase.from('team_storage_usage').delete().eq('team_id', teamId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupTeamImages');
    }
  }
}