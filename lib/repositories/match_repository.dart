import '../models/match.dart';
import '../models/user.dart' as app_user;
import '../services/api_service.dart';
import '../utils/validators.dart';

class MatchRepository {
  final ApiService _apiService;

  MatchRepository(this._apiService);

  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return _apiService.getMatches(limit: limit, offset: offset);
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) async {
    return _apiService.getAllMatches(limit: limit, offset: offset);
  }

  Future<Match> getMatch(String matchId) async {
    return _apiService.getMatch(matchId);
  }

  Future<Match> createMatch({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
  }) async {
    // Repository-level validation before calling API
    final dateError = validateMatchDateTime(matchDate);
    if (dateError != null) throw ArgumentError(dateError);

    final locationError = validateLocation(location);
    if (locationError != null) throw ArgumentError(locationError);

    if (title != null && title.isNotEmpty) {
      final titleError = validateMatchTitle(title);
      if (titleError != null) throw ArgumentError(titleError);
    }

    if (maxPlayers != null) {
      final playersError = validateMaxPlayers(maxPlayers);
      if (playersError != null) throw ArgumentError(playersError);
    }

    if (matchType != null && !['male', 'female', 'mixed'].contains(matchType)) {
      throw ArgumentError('Match type must be male, female, or mixed');
    }

    if (team1Id.trim().isEmpty) {
      throw ArgumentError('Team 1 ID cannot be empty');
    }

    if (team2Id.trim().isEmpty) {
      throw ArgumentError('Team 2 ID cannot be empty');
    }

    return _apiService.createMatch(
      team1Id: team1Id,
      team2Id: team2Id,
      matchDate: matchDate,
      location: location,
      title: title,
      maxPlayers: maxPlayers,
      matchType: matchType,
    );
  }

  Future<void> closeMatch(String matchId) async {
    return _apiService.closeMatch(matchId);
  }

  Future<void> joinMatch(String matchId) async {
    return _apiService.joinMatch(matchId);
  }

  Future<void> leaveMatch(String matchId) async {
    return _apiService.leaveMatch(matchId);
  }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    return _apiService.getMatchPlayers(matchId);
  }
}
