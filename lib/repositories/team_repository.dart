import '../models/team.dart';
import '../models/city.dart';
import '../models/team.dart' as team_models;
import '../models/user.dart' as app_user;
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeamRepository {
  final ApiService _apiService;

  TeamRepository(this._apiService);

  Future<List<Team>> getUserTeams() async {
    return _apiService.getUserTeams();
  }

  Future<List<Team>> getMyTeams() async {
    return _apiService.getMyTeams();
  }

  Future<List<Team>> getAllTeams() async {
    return _apiService.getAllTeams();
  }

  Future<List<City>> getCities() async {
    return _apiService.getCities();
  }

  Future<Team> getTeam(String teamId) async {
    return _apiService.getTeam(teamId);
  }

  Future<List<Team>> searchTeams(String query) async {
    return _apiService.searchTeams(query);
  }

  Future<Team> createTeam(
    String name, {
    String? location,
    int? numberOfPlayers,
    String? description,
    String? logo,
    bool? isRecruiting,
    int? minAge,
    int? maxAge,
  }) async {
    // Repository-level validation before calling API
    final nameError = validateTeamName(name);
    if (nameError != null) throw ArgumentError(nameError);

    if (location != null && location.isNotEmpty) {
      final locationError = validateLocation(location);
      if (locationError != null) throw ArgumentError(locationError);
    }

    if (numberOfPlayers != null) {
      final playersError = validateMaxPlayers(numberOfPlayers);
      if (playersError != null) throw ArgumentError(playersError);
    }

    return _apiService.createTeam(
      name,
      location: location,
      numberOfPlayers: numberOfPlayers,
      description: description,
      logo: logo,
      isRecruiting: isRecruiting,
      minAge: minAge,
      maxAge: maxAge,
    );
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    return _apiService.toggleTeamRecruiting(teamId);
  }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
    return _apiService.deleteTeam(teamId, reason: reason);
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(
    String teamId,
  ) async {
    return _apiService.getTeamJoinRequests(teamId);
  }

  Future<team_models.TeamJoinRequest> createJoinRequest(
    String teamId, {
    String? message,
  }) async {
    return _apiService.createJoinRequest(teamId, message: message);
  }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
    String teamId,
    String requestId,
    String status,
  ) async {
    return _apiService.updateJoinRequestStatus(teamId, requestId, status);
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    return _apiService.getMyJoinRequests();
  }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
    return _apiService.cancelJoinRequest(teamId, requestId);
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    return _apiService.getTeamMembers(teamId);
  }

  Future<Team> updateTeam(String teamId, {String? logo}) async {
    // This would typically call an API endpoint to update team data
    // For now, we'll implement a basic version that calls the API service
    // You may need to add an updateTeam method to ApiService

    // Since ApiService doesn't have updateTeam yet, we'll use a direct Supabase call
    // In a real implementation, you'd add this to ApiService
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('teams')
        .update({'logo_url': logo})
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(response);
  }
}
