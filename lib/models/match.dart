class Match {
  final String id;
  final String teamId;
  final DateTime matchDate;
  final String location;
  final String status;
  final DateTime createdAt;
  final String? teamName; // For display purposes (joined data)
  final String? title;
  final String? team1Id;
  final String? team2Id;
  final String? team1Name;
  final String? team2Name;
  final int? maxPlayers;
  final String? description;
  final String? createdBy;
  final String matchType; // 'male', 'female', 'mixed'

  Match({
    required this.id,
    required this.teamId,
    required this.matchDate,
    required this.location,
    required this.status,
    required this.createdAt,
    this.teamName,
    this.title,
    this.team1Id,
    this.team2Id,
    this.team1Name,
    this.team2Name,
    this.maxPlayers,
    this.description,
    this.createdBy,
    this.matchType = 'mixed',
  }) {
    // Constructor validation
    if (id.trim().isEmpty) {
      throw ArgumentError('Match ID cannot be empty');
    }
    if (teamId.trim().isEmpty) {
      throw ArgumentError('Team ID cannot be empty');
    }
    if (location.trim().isEmpty) {
      throw ArgumentError('Match location cannot be empty');
    }
    if (!['open', 'closed', 'cancelled', 'completed'].contains(status)) {
      throw ArgumentError(
        'Invalid status: must be open, closed, cancelled, or completed',
      );
    }
    if (maxPlayers != null && (maxPlayers! < 1 || maxPlayers! > 50)) {
      throw ArgumentError('Max players must be between 1 and 50');
    }
    if (!['male', 'female', 'mixed'].contains(matchType)) {
      throw ArgumentError('Match type must be male, female, or mixed');
    }
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) {
      throw FormatException('Match ID is required and cannot be empty');
    }

    final teamId = json['team_id'];
    if (teamId == null || teamId.toString().trim().isEmpty) {
      throw FormatException('Team ID is required and cannot be empty');
    }

    final location = json['location'];
    if (location == null || location.toString().trim().isEmpty) {
      throw FormatException('Match location is required and cannot be empty');
    }

    // Parse and validate matchDate
    DateTime matchDate;
    try {
      final matchDateStr = json['match_date'];
      if (matchDateStr != null && matchDateStr.toString().isNotEmpty) {
        matchDate = DateTime.parse(matchDateStr.toString());
      } else {
        throw FormatException('Match date is required');
      }
    } catch (e) {
      throw FormatException('Invalid match_date format: $e');
    }

    // Parse and validate createdAt
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'];
      if (createdAtStr != null && createdAtStr.toString().isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr.toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      throw FormatException('Invalid created_at format: $e');
    }

    // Validate status
    final status = json['status']?.toString() ?? 'open';
    if (!['open', 'closed', 'cancelled', 'completed'].contains(status)) {
      throw FormatException(
        'Invalid status: must be open, closed, cancelled, or completed',
      );
    }

    // Validate maxPlayers if provided
    final maxPlayers = json['max_players'] ?? json['maxPlayers'];
    if (maxPlayers != null) {
      final maxPlayersInt = int.tryParse(maxPlayers.toString());
      if (maxPlayersInt == null || maxPlayersInt < 1 || maxPlayersInt > 50) {
        throw FormatException(
          'Invalid max_players: must be a number between 1 and 50',
        );
      }
    }

    // Validate matchType
    final matchType =
        json['match_type']?.toString() ??
        json['matchType']?.toString() ??
        'mixed';
    if (!['male', 'female', 'mixed'].contains(matchType)) {
      throw FormatException(
        'Invalid match_type: must be male, female, or mixed',
      );
    }

    return Match(
      id: id.toString(),
      teamId: teamId.toString(),
      matchDate: matchDate,
      location: location.toString().trim(),
      status: status,
      createdAt: createdAt,
      teamName:
          json['teams']?['name']?.toString() ??
          json['team_name']?.toString() ??
          json['teamName']?.toString(),
      title: json['title']?.toString() ?? json['match_title']?.toString(),
      team1Id: json['team1_id']?.toString() ?? json['team_1_id']?.toString(),
      team2Id: json['team2_id']?.toString() ?? json['team_2_id']?.toString(),
      team1Name:
          json['team1_name']?.toString() ??
          json['team_1_name']?.toString() ??
          json['team1Name']?.toString(),
      team2Name:
          json['team2_name']?.toString() ??
          json['team_2_name']?.toString() ??
          json['team2Name']?.toString(),
      maxPlayers: maxPlayers != null ? int.parse(maxPlayers.toString()) : null,
      description: json['description']?.toString(),
      createdBy:
          json['owner_id']?.toString() ??
          json['created_by']?.toString() ??
          json['createdBy']?.toString(),
      matchType: matchType,
    );
  }

  Map<String, dynamic> toJson() {
    // Use canonical snake_case keys for persistence/DB compatibility.
    final Map<String, dynamic> map = {
      'id': id,
      'team_id': teamId,
      'match_date': matchDate.toIso8601String(),
      'location': location,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'match_type': matchType,
    };

    if (title != null) map['title'] = title;
    if (maxPlayers != null) map['max_players'] = maxPlayers;
    if (description != null) map['description'] = description;
    if (createdBy != null) map['created_by'] = createdBy;
    if (team1Id != null) map['team1_id'] = team1Id;
    if (team2Id != null) map['team2_id'] = team2Id;

    return map;
  }

  Match copyWith({
    String? id,
    String? teamId,
    DateTime? matchDate,
    String? location,
    String? status,
    DateTime? createdAt,
    String? teamName,
    String? title,
    String? team1Id,
    String? team2Id,
    String? team1Name,
    String? team2Name,
    int? maxPlayers,
    String? description,
    String? createdBy,
    String? matchType,
  }) {
    return Match(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      matchDate: matchDate ?? this.matchDate,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      teamName: teamName ?? this.teamName,
      title: title ?? this.title,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      matchType: matchType ?? this.matchType,
    );
  }

  // Computed properties for backward compatibility
  String get displayTitle =>
      title ??
      teamName ??
      'Match vs ${teamId.length >= 8 ? teamId.substring(0, 8) : teamId}';
  int get defaultMaxPlayers => maxPlayers ?? 11; // Default value
  String get ownerId => teamId; // For backward compatibility

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  String get formattedDate {
    final now = DateTime.now();
    final difference = matchDate.difference(now);

    if (difference.inDays == 0) {
      return 'Today ${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${matchDate.day}/${matchDate.month} ${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}';
    } else {
      return '${matchDate.day}/${matchDate.month}/${matchDate.year}';
    }
  }
}
