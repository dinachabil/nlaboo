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
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // Normalize and support several backend shapes:
    // - joined relation: { teams: { name: '...' } }
    // - flat keys: team_name, teamName
    // - team1/team2 names as team1_name / team1Name
    return Match(
      id: json['id'] ?? '',
      teamId: json['team_id'] ?? '',
      matchDate: json['match_date'] != null ? DateTime.parse(json['match_date']) : DateTime.now(),
      location: json['location'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      // Resolve team name from multiple possible keys to avoid inconsistencies
      teamName: json['teams']?['name'] ?? json['team_name'] ?? json['teamName'],
      title: json['title'] ?? json['match_title'],
      // Support optional team1/team2 ids and names coming from different queries
      team1Id: json['team1_id'] ?? json['team_1_id'],
      team2Id: json['team2_id'] ?? json['team_2_id'],
      team1Name: json['team1_name'] ?? json['team_1_name'] ?? json['team1Name'],
      team2Name: json['team2_name'] ?? json['team_2_name'] ?? json['team2Name'],
      maxPlayers: json['max_players'] ?? json['maxPlayers'],
      description: json['description'],
      createdBy: json['created_by'] ?? json['createdBy'],
      matchType: json['match_type'] ?? json['matchType'] ?? 'mixed',
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
  String get displayTitle => title ?? teamName ?? 'Match vs ${teamId.length >= 8 ? teamId.substring(0, 8) : teamId}';
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