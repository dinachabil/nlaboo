import 'user.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final User? owner;
  final DateTime createdAt;
  final String? location;
  final String? description;
  final String? logo;
  final int maxPlayers;
  final bool isRecruiting;
  final DateTime? deletedAt;
  final int minAge;
  final int maxAge;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    this.owner,
    required this.createdAt,
    this.location,
    this.description,
    this.logo,
    required this.maxPlayers,
    required this.isRecruiting,
    this.deletedAt,
    this.minAge = 15,
    this.maxAge = 40,
  }) {
    // Constructor validation
    if (id.trim().isEmpty) {
      throw ArgumentError('Team ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Team name cannot be empty');
    }
    if (ownerId.trim().isEmpty) {
      throw ArgumentError('Owner ID cannot be empty');
    }
    if (maxPlayers < 1 || maxPlayers > 50) {
      throw ArgumentError('Max players must be between 1 and 50');
    }
    if (minAge < 10 || minAge > 60) {
      throw ArgumentError('Min age must be between 10 and 60');
    }
    if (maxAge < 10 || maxAge > 60) {
      throw ArgumentError('Max age must be between 10 and 60');
    }
    if (minAge > maxAge) {
      throw ArgumentError('Min age cannot be greater than max age');
    }
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) {
      throw FormatException('Team ID is required and cannot be empty');
    }

    final name = json['name'];
    if (name == null || name.toString().trim().isEmpty) {
      throw FormatException('Team name is required and cannot be empty');
    }

    final ownerId = json['owner_id'];
    if (ownerId == null || ownerId.toString().trim().isEmpty) {
      throw FormatException('Owner ID is required and cannot be empty');
    }

    // Parse and validate createdAt
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr.toString());
      } else {
        throw FormatException('Created date is required');
      }
    } catch (e) {
      throw FormatException('Invalid created_at format: $e');
    }

    // Validate maxPlayers
    final maxPlayers = json['max_players'] ?? 11;
    final maxPlayersInt = int.tryParse(maxPlayers.toString());
    if (maxPlayersInt == null || maxPlayersInt < 1 || maxPlayersInt > 50) {
      throw FormatException(
        'Invalid max_players: must be a number between 1 and 50',
      );
    }

    // Validate minAge and maxAge
    final minAge = json['min_age'] ?? 15;
    final maxAge = json['max_age'] ?? 40;
    final minAgeInt = int.tryParse(minAge.toString());
    final maxAgeInt = int.tryParse(maxAge.toString());
    if (minAgeInt == null || minAgeInt < 10 || minAgeInt > 60) {
      throw FormatException(
        'Invalid min_age: must be a number between 10 and 60',
      );
    }
    if (maxAgeInt == null || maxAgeInt < 10 || maxAgeInt > 60) {
      throw FormatException(
        'Invalid max_age: must be a number between 10 and 60',
      );
    }
    if (minAgeInt > maxAgeInt) {
      throw FormatException('min_age cannot be greater than max_age');
    }

    // Parse and validate deletedAt if provided
    DateTime? deletedAt;
    if (json['deleted_at'] != null) {
      try {
        deletedAt = DateTime.parse(json['deleted_at'].toString());
      } catch (e) {
        throw FormatException('Invalid deleted_at format: $e');
      }
    }

    // Parse owner if provided
    User? owner;
    if (json['users'] != null) {
      try {
        owner = User.fromJson({
          ...json['users'],
          'name': json['users']['full_name'] ?? json['users']['name'] ?? '',
        });
      } catch (e) {
        // Silently fail for owner parsing - not critical for team data
      }
    }

    return Team(
      id: id.toString(),
      name: name.toString().trim(),
      ownerId: ownerId.toString(),
      owner: owner,
      createdAt: createdAt,
      location: json['location']?.toString(),
      description: json['description']?.toString(),
      logo: json['logo_url']?.toString() ?? json['logo']?.toString(),
      maxPlayers: maxPlayersInt,
      isRecruiting: json['is_recruiting'] == true,
      deletedAt: deletedAt,
      minAge: minAgeInt,
      maxAge: maxAgeInt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'location': location,
      'description': description,
      'logo_url': logo,
      'max_players': maxPlayers,
      'is_recruiting': isRecruiting,
      'deleted_at': deletedAt?.toIso8601String(),
      'min_age': minAge,
      'max_age': maxAge,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? ownerId,
    User? owner,
    DateTime? createdAt,
    String? location,
    String? description,
    String? logo,
    int? maxPlayers,
    bool? isRecruiting,
    DateTime? deletedAt,
    int? minAge,
    int? maxAge,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isRecruiting: isRecruiting ?? this.isRecruiting,
      deletedAt: deletedAt ?? this.deletedAt,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
    );
  }
}

class TeamJoinRequest {
  final String id;
  final String teamId;
  final String userId;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Team? team;
  final User? user;

  TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.team,
    this.user,
  }) {
    // Constructor validation
    if (id.trim().isEmpty) {
      throw ArgumentError('Join request ID cannot be empty');
    }
    if (teamId.trim().isEmpty) {
      throw ArgumentError('Team ID cannot be empty');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (!['pending', 'approved', 'rejected', 'cancelled'].contains(status)) {
      throw ArgumentError(
        'Invalid status: must be pending, approved, rejected, or cancelled',
      );
    }
  }

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) {
      throw FormatException('Join request ID is required and cannot be empty');
    }

    final teamId = json['team_id'];
    if (teamId == null || teamId.toString().trim().isEmpty) {
      throw FormatException('Team ID is required and cannot be empty');
    }

    final userId = json['user_id'];
    if (userId == null || userId.toString().trim().isEmpty) {
      throw FormatException('User ID is required and cannot be empty');
    }

    // Parse and validate createdAt
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr.toString());
      } else {
        throw FormatException('Created date is required');
      }
    } catch (e) {
      throw FormatException('Invalid created_at format: $e');
    }

    // Parse and validate updatedAt
    DateTime updatedAt;
    try {
      final updatedAtStr = json['updated_at'];
      if (updatedAtStr != null && updatedAtStr.toString().isNotEmpty) {
        updatedAt = DateTime.parse(updatedAtStr.toString());
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      throw FormatException('Invalid updated_at format: $e');
    }

    // Validate status
    final status = json['status']?.toString() ?? 'pending';
    if (!['pending', 'approved', 'rejected', 'cancelled'].contains(status)) {
      throw FormatException(
        'Invalid status: must be pending, approved, rejected, or cancelled',
      );
    }

    // Parse nested objects with error handling
    Team? team;
    if (json['teams'] != null) {
      try {
        team = Team.fromJson(json['teams']);
      } catch (e) {
        // Silently fail for team parsing - not critical for join request data
      }
    }

    User? user;
    if (json['users'] != null) {
      try {
        user = User.fromJson(json['users']);
      } catch (e) {
        // Silently fail for user parsing - not critical for join request data
      }
    }

    return TeamJoinRequest(
      id: id.toString(),
      teamId: teamId.toString(),
      userId: userId.toString(),
      status: status,
      message: json['message']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      team: team,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TeamJoinRequest copyWith({
    String? id,
    String? teamId,
    String? userId,
    String? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    Team? team,
    User? user,
  }) {
    return TeamJoinRequest(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      team: team ?? this.team,
      user: user ?? this.user,
    );
  }
}
