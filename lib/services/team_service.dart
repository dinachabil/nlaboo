import '../models/team.dart';
import '../models/city.dart';
import '../models/team.dart' as team_models;
import '../models/user.dart' as app_user;
import '../repositories/team_repository.dart';
import '../services/cache_service.dart';
import '../services/user_service.dart';
import '../services/image_management_service.dart';
import 'dart:io';

class TeamService {
  final TeamRepository _teamRepository;
  final CacheService _cacheService;
  final ImageManagementService _imageService;

  TeamService(this._teamRepository)
      : _cacheService = CacheService(),
        _imageService = ImageManagementService();

  // Optional UserService for batch operations
  UserService? _userService;
  void setUserService(UserService userService) {
    _userService = userService;
  }

  Future<List<Team>> getUserTeams() async {
    return _teamRepository.getUserTeams();
  }

  Future<List<Team>> getMyTeams() async {
    return _teamRepository.getMyTeams();
  }

  Future<List<Team>> getAllTeams() async {
    // Try to get from cache first
    final cachedTeams = _cacheService.getCachedTeams();
    if (cachedTeams != null && cachedTeams.isNotEmpty) {
      return cachedTeams;
    }

    // Fetch from API and cache
    final teams = await _teamRepository.getAllTeams();
    await _cacheService.cacheTeams(teams);
    return teams;
  }

  Future<List<City>> getCities() async {
    // Try to get from cache first
    final cachedCities = _cacheService.getCachedCities();
    if (cachedCities != null && cachedCities.isNotEmpty) {
      return cachedCities;
    }

    // Fetch from API and cache
    final cities = await _teamRepository.getCities();
    await _cacheService.cacheCities(cities);
    return cities;
  }

  Future<Team> getTeam(String teamId) async {
    return _teamRepository.getTeam(teamId);
  }

  Future<List<Team>> searchTeams(String query) async {
    return _teamRepository.searchTeams(query);
  }

  Future<Team> createTeam({
    required String name,
    String? location,
    int? numberOfPlayers,
    String? description,
    String? logo,
    bool? isRecruiting,
    int? minAge,
    int? maxAge,
  }) async {
    // Business logic validation
    if (name.trim().isEmpty) {
      throw ArgumentError('Team name cannot be empty');
    }

    if (numberOfPlayers != null &&
        (numberOfPlayers < 5 || numberOfPlayers > 22)) {
      throw ArgumentError('Number of players must be between 5 and 22');
    }

    if (minAge != null && (minAge < 10 || minAge > 60)) {
      throw ArgumentError('Min age must be between 10 and 60');
    }

    if (maxAge != null && (maxAge < 10 || maxAge > 60)) {
      throw ArgumentError('Max age must be between 10 and 60');
    }

    if (minAge != null && maxAge != null && minAge > maxAge) {
      throw ArgumentError('Min age cannot be greater than max age');
    }

    return _teamRepository.createTeam(
      name.trim(),
      location: location,
      numberOfPlayers: numberOfPlayers,
      description: description?.trim(),
      logo: logo,
      isRecruiting: isRecruiting,
      minAge: minAge,
      maxAge: maxAge,
    );
  }

  /// Uploads a team logo and updates the team record
  Future<Team> uploadTeamLogo(String teamId, File imageFile) async {
    try {
      // Upload the logo using the image management service
      final logoUrl = await _imageService.uploadTeamLogo(imageFile, teamId);

      if (logoUrl != null) {
        // Update the team record with the new logo URL
        // Note: This would typically be done via the repository/API
        // For now, we'll assume the team repository has an update method
        // You may need to add this method to your repository
        final updatedTeam = await _teamRepository.updateTeam(teamId, logo: logoUrl);

        // Invalidate cache since team data changed
        await _cacheService.invalidateTeamsCache();

        return updatedTeam;
      } else {
        throw Exception('Failed to upload team logo');
      }
    } catch (e) {
      throw Exception('Failed to upload team logo: $e');
    }
  }

  /// Deletes a team logo and updates the team record
  Future<Team> deleteTeamLogo(String teamId, String logoUrl) async {
    try {
      // Delete the logo from storage
      await _imageService.deleteTeamLogo(logoUrl, teamId);

      // Update the team record to remove the logo URL
      final updatedTeam = await _teamRepository.updateTeam(teamId, logo: null);

      // Invalidate cache since team data changed
      await _cacheService.invalidateTeamsCache();

      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to delete team logo: $e');
    }
  }

  /// Gets team storage usage information
  Future<Map<String, dynamic>> getTeamStorageUsage(String teamId) async {
    return _imageService.getTeamStorageUsage(teamId);
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    return _teamRepository.toggleTeamRecruiting(teamId);
  }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
    return _teamRepository.deleteTeam(teamId, reason: reason);
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(
    String teamId,
  ) async {
    return _teamRepository.getTeamJoinRequests(teamId);
  }

  Future<team_models.TeamJoinRequest> createJoinRequest(
    String teamId, {
    String? message,
  }) async {
    return _teamRepository.createJoinRequest(teamId, message: message);
  }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
    String teamId,
    String requestId,
    String status,
  ) async {
    // Business logic validation
    final validStatuses = ['accepted', 'rejected', 'pending'];
    if (!validStatuses.contains(status)) {
      throw ArgumentError('Invalid status: $status');
    }

    return _teamRepository.updateJoinRequestStatus(teamId, requestId, status);
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    return _teamRepository.getMyJoinRequests();
  }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
    return _teamRepository.cancelJoinRequest(teamId, requestId);
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    return _teamRepository.getTeamMembers(teamId);
  }

  /// Batch fetch team data to optimize performance
  Future<Map<String, dynamic>> getTeamDataBatch(List<String> teamIds) async {
    final Map<String, Map<String, dynamic>> ownersMap = {};
    final Map<String, int> memberCountsMap = {};

    // Process in batches to avoid overwhelming the API
    const batchSize = 5;
    for (var i = 0; i < teamIds.length; i += batchSize) {
      final batch = teamIds.sublist(
        i,
        i + batchSize > teamIds.length ? teamIds.length : i + batchSize,
      );

      final futures = batch.map((teamId) async {
        try {
          final team = await _teamRepository.getTeam(teamId);
          final owner = _userService != null
              ? await _userService!.getUserById(team.ownerId)
              : null;
          final members = await getTeamMembers(teamId);
          return {
            'teamId': teamId,
            'owner': owner != null
                ? {
                    'name': owner.name,
                    'id': owner.id,
                    'position': owner.position,
                    'imageUrl': owner.imageUrl,
                  }
                : {'name': 'Unknown Owner', 'id': team.ownerId},
            'memberCount': members.length,
          };
        } catch (e) {
          return {
            'teamId': teamId,
            'owner': {'name': 'Unknown Owner', 'id': teamId},
            'memberCount': 0,
          };
        }
      });

      final results = await Future.wait(futures);

      for (final result in results) {
        final teamId = result['teamId'] as String;
        ownersMap[teamId] = result['owner'] as Map<String, dynamic>;
        memberCountsMap[teamId] = result['memberCount'] as int;
      }
    }

    return {'owners': ownersMap, 'memberCounts': memberCountsMap};
  }
}
