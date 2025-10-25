import 'package:flutter/material.dart';
import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/api_service.dart';

class MatchProvider with ChangeNotifier {
  final MatchRepository _matchRepository;
  final ApiService _apiService;

  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;

  MatchProvider(this._matchRepository, this._apiService) {
    _initializeRealtimeUpdates();
  }

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initializeRealtimeUpdates() {
    _apiService.matchesStream.listen(
      (matches) {
        _matches = matches;
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
      // Attempt to reconnect after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_matches.isEmpty) {
          loadAllMatches();
        }
      });
    });
  }

  Future<void> loadMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matches = await _matchRepository.getMatches();
      _matches = matches;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matches = await _matchRepository.getAllMatches();
      _matches = matches;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMatch({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _matchRepository.createMatch(
        team1Id: team1Id,
        team2Id: team2Id,
        matchDate: matchDate,
        location: location,
        title: title,
        maxPlayers: maxPlayers,
        matchType: matchType,
      );
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinMatch(String matchId) async {
    try {
      await _matchRepository.joinMatch(matchId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveMatch(String matchId) async {
    try {
      await _matchRepository.leaveMatch(matchId);
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