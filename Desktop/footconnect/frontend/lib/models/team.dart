import 'user.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final String? location;
  final String? description;
  final String? logo;
  final int maxPlayers;
  final bool isRecruiting;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.location,
    this.description,
    this.logo,
    required this.maxPlayers,
    required this.isRecruiting,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerId: json['owner_id'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      location: json['location'],
      description: json['description'],
      logo: json['logo_url'] ?? json['logo'],
      maxPlayers: json['max_players'] ?? 11,
      isRecruiting: json['is_recruiting'] ?? false,
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
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    String? location,
    String? description,
    String? logo,
    int? maxPlayers,
    bool? isRecruiting,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isRecruiting: isRecruiting ?? this.isRecruiting,
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
  });

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    return TeamJoinRequest(
      id: json['id'] ?? '',
      teamId: json['team_id'] ?? '',
      userId: json['user_id'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      team: json['teams'] != null ? Team.fromJson(json['teams']) : null,
      user: json['users'] != null ? User.fromJson(json['users']) : null,
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