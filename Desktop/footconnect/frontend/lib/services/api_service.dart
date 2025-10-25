import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'error_handler.dart';
import '../models/user.dart' as app_user;
import '../models/match.dart';
import '../models/team.dart';
import '../models/notification.dart';
import '../models/team.dart' as team_models;
 
class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
 
  // Auth methods
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String role = 'player',
    String? gender,
    int? age,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/auth/signup'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'gender': gender,
          'age': age,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Signup failed: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.signup');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.login');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  // User methods
  Future<app_user.User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/users/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return app_user.User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get current user: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getCurrentUser');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      print('Uploading avatar via backend API...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/v1/users/me/avatar'),
      );

      // Add authorization header
      request.headers.addAll(_headers);

      // Add file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseData);
        print('Avatar uploaded successfully: ${jsonResponse['avatar_url']}');
        return jsonResponse['avatar_url'];
      } else {
        throw Exception('Failed to upload avatar: $responseData');
      }
    } catch (e, st) {
      print('Error uploading avatar via backend: $e');
      ErrorHandler.logError(e, st, 'ApiService.uploadAvatar');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<app_user.User> updateProfile({
    String? name,
    String? position,
    String? bio,
    String? imageUrl,
    String? gender,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (position != null) updates['position'] = position;
      if (bio != null) updates['bio'] = bio;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (gender != null) updates['gender'] = gender;

      final response = await http.put(
        Uri.parse('http://localhost:8000/api/v1/users/me'),
        headers: _headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return app_user.User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.updateProfile');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .order('created_at');
 
      return (response as List).map((json) => app_user.User.fromJson(json)).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getAllUsers');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.deleteUser');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Match methods
  Future<List<Match>> getMatches() async {
    try {
      // For now, use Supabase directly but handle RLS errors gracefully
      final response = await _supabase
          .from('matches')
          .select('*, teams!matches_team_id_fkey(name)') // Specify the exact relationship
          .eq('status', 'open')
          .order('match_date');

      return (response as List).map((json) => Match.fromJson(json)).toList();
    } catch (e, st) {
      // If RLS error, provide helpful message
      if (e.toString().contains('infinite recursion') || e.toString().contains('policy')) {
        throw Exception('Database configuration issue. Please run the SQL script in Supabase dashboard to disable RLS policies for development.');
      }
      ErrorHandler.logError(e, st, 'ApiService.getMatches');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<Match> getMatch(String matchId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*')
          .eq('id', matchId)
          .single();
 
      return Match.fromJson(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getMatch');
      throw Exception(ErrorHandler.userMessage(e));
    }
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
    try {
      final Map<String, dynamic> matchData = {
        'match_date': matchDate.toIso8601String(),
        'location': location,
        'team1_id': team1Id,
        'team2_id': team2Id,
      };

      if (title != null && title.isNotEmpty) {
        matchData['title'] = title;
      }

      if (maxPlayers != null) {
        matchData['max_players'] = maxPlayers;
      }

      if (matchType != null && matchType.isNotEmpty) {
        matchData['match_type'] = matchType;
      }

      final response = await _supabase
          .from('matches')
          .insert(matchData)
          .select('*, teams!matches_team_id_fkey(name)')
          .single();

      return Match.fromJson(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.createMatch');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<void> closeMatch(String matchId) async {
    try {
      await _supabase
          .from('matches')
          .update({'status': 'closed'})
          .eq('id', matchId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.closeMatch');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Team methods
  Future<List<Team>> getUserTeams() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
 
      final response = await _supabase
          .from('teams')
          .select('*')
          .eq('owner_id', user.id)
          .order('created_at');
 
      return (response as List).map((json) => Team.fromJson(json)).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getUserTeams');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<Team> createTeam(String name, {String? location, int? numberOfPlayers, String? description, String? logo, bool? isRecruiting}) async {
    try {
      // Authentication is handled by the Authorization header in _headers
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/teams/'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'location': location,
          'description': description,
          'logo_url': logo,
          'max_players': numberOfPlayers ?? 11,
          'is_recruiting': isRecruiting ?? false,
        }),
      );

      if (response.statusCode == 200) {
        return Team.fromJson(jsonDecode(response.body));
      } else {
        // Handle specific error cases
        final errorData = jsonDecode(response.body);
        if (response.statusCode == 400 && errorData['detail']?.contains('already have a team') == true) {
          throw Exception('You already have a team with this name');
        }
        throw Exception('Failed to create team: ${errorData['detail'] ?? response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.createTeam');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Participant methods
  Future<void> joinMatch(String matchId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/participants/$matchId/join'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join match: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.joinMatch');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<void> leaveMatch(String matchId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/v1/participants/$matchId/leave'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to leave match: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.leaveMatch');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    try {
      final response = await _supabase
          .from('match_players')
          .select('users(*)')
          .eq('match_id', matchId);
 
      return (response as List).map((json) => app_user.User.fromJson(json['users'])).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getMatchPlayers');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Admin methods
  Future<List<Match>> getAllMatches() async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*, teams!matches_team_id_fkey(name)')
          .order('created_at', ascending: false);
 
      return (response as List).map((json) => Match.fromJson(json)).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getAllMatches');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Notification methods
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false);
 
      return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getNotifications');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.markNotificationAsRead');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
      });
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.createNotification');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }
 
  // Team browsing methods
  Future<List<Team>> getAllTeams() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/teams/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Team.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get teams: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getAllTeams');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      final response = await _supabase
          .from('teams')
          .select('*')
          .eq('id', teamId)
          .single();

      return Team.fromJson(response);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getTeam');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    try {
      // Get team members directly from team_members table
      final response = await _supabase
          .from('team_members')
          .select('*, users(*)')
          .eq('team_id', teamId);

      return (response as List).map((json) => app_user.User.fromJson({...json['users'], 'role': json['role']})).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getTeamMembers');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  // Team Join Request methods
  Future<team_models.TeamJoinRequest> createJoinRequest(String teamId, {String? message}) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/teams/$teamId/join-requests'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return team_models.TeamJoinRequest.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create join request: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.createJoinRequest');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(String teamId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/teams/$teamId/join-requests'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => team_models.TeamJoinRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get join requests: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getTeamJoinRequests');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(String teamId, String requestId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/v1/teams/$teamId/join-requests/$requestId'),
        headers: _headers,
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return team_models.TeamJoinRequest.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update join request: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.updateJoinRequestStatus');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/teams/my-join-requests'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => team_models.TeamJoinRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get my join requests: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.getMyJoinRequests');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<List<Team>> searchTeams(String query) async {
    try {
      final response = await _supabase
          .from('teams')
          .select('*')
          .or('name.ilike.%$query%,location.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Team.fromJson(json)).toList();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.searchTeams');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/v1/teams/$teamId/recruiting'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle recruiting status: ${response.body}');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ApiService.toggleTeamRecruiting');
      throw Exception(ErrorHandler.userMessage(e));
    }
  }


  // User statistics methods
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
 
    try {
      // Get matches joined count
      final matchesJoinedResponse = await _supabase
          .from('match_players')
          .select('id')
          .eq('user_id', user.id);
 
      // Get matches created count (if team owner/admin)
      final userTeams = await getUserTeams();
      final teamIds = userTeams.map((team) => team.id).toList();
 
      int matchesCreated = 0;
      if (teamIds.isNotEmpty) {
        // Count matches created by user's teams
        for (final teamId in teamIds) {
          final teamMatchesResponse = await _supabase
              .from('matches')
              .select('id')
              .eq('team_id', teamId);
          matchesCreated += teamMatchesResponse.length;
        }
      }
 
      return {
        'matches_joined': matchesJoinedResponse.length,
        'matches_created': matchesCreated,
        'teams_owned': userTeams.length,
      };
    } catch (e, st) {
      // Use logging and return safe defaults instead of exposing raw errors.
      // Keep returning safe defaults so callers don't crash; the error is logged.
      ErrorHandler.logError(e, st, 'ApiService.getUserStats');
      return {
        'matches_joined': 0,
        'matches_created': 0,
        'teams_owned': 0,
      };
    }
  }
}