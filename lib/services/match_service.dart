import '../models/match.dart';
import '../models/user.dart' as app_user;
import '../repositories/match_repository.dart';

class MatchService {
  final MatchRepository _matchRepository;

  MatchService(this._matchRepository);

  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return _matchRepository.getMatches(limit: limit, offset: offset);
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) async {
    return _matchRepository.getAllMatches(limit: limit, offset: offset);
  }

  Future<Match> getMatch(String matchId) async {
    return _matchRepository.getMatch(matchId);
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
    // Business logic validation
    if (team1Id == team2Id) {
      throw ArgumentError('Team 1 and Team 2 cannot be the same');
    }

    if (matchDate.isBefore(DateTime.now())) {
      throw ArgumentError('Match date cannot be in the past');
    }

    if (maxPlayers != null && (maxPlayers < 10 || maxPlayers > 44)) {
      throw ArgumentError('Max players must be between 10 and 44');
    }

    return _matchRepository.createMatch(
      team1Id: team1Id,
      team2Id: team2Id,
      matchDate: matchDate,
      location: location,
      title: title?.trim(),
      maxPlayers: maxPlayers,
      matchType: matchType,
    );
  }

  Future<void> closeMatch(String matchId) async {
    return _matchRepository.closeMatch(matchId);
  }

  Future<void> joinMatch(String matchId) async {
    return _matchRepository.joinMatch(matchId);
  }

  Future<void> leaveMatch(String matchId) async {
    return _matchRepository.leaveMatch(matchId);
  }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    return _matchRepository.getMatchPlayers(matchId);
  }
}
