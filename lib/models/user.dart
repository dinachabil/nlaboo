class User {
  final String id;
  final String name;
  final String email;
  final String? position;
  final String? bio;
  final String? imageUrl;
  final String role; // Hidden from UI but used for logic
  final bool isAdmin; // Computed from role
  final DateTime createdAt;
  final int? age;
  final String? phone;
  final String? gender; // 'male', 'female'
  final String? location;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.position,
    this.bio,
    this.imageUrl,
    required this.role,
    bool? isAdmin, // Make optional, computed from role
    required this.createdAt,
    this.age,
    this.phone,
    this.gender,
    this.location,
  }) : isAdmin = isAdmin ?? (role == 'admin') {
    // Constructor validation
    if (id.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('User name cannot be empty');
    }
    if (email.trim().isEmpty) {
      throw ArgumentError('User email cannot be empty');
    }
    if (!['player', 'admin', 'moderator'].contains(role)) {
      throw ArgumentError('Invalid role: must be player, admin, or moderator');
    }
    if (age != null && (age! < 0 || age! > 150)) {
      throw ArgumentError('Age must be between 0 and 150');
    }
    if (gender != null && !['male', 'female', 'other'].contains(gender)) {
      throw ArgumentError('Gender must be male, female, or other');
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) {
      throw FormatException('User ID is required and cannot be empty');
    }

    final name = json['full_name'] ?? json['name'];
    if (name == null || name.toString().trim().isEmpty) {
      throw FormatException('User name is required and cannot be empty');
    }

    final email = json['email'];
    if (email == null || email.toString().trim().isEmpty) {
      throw FormatException('User email is required and cannot be empty');
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

    // Validate age if provided
    final age = json['age'];
    if (age != null) {
      final ageInt = int.tryParse(age.toString());
      if (ageInt == null || ageInt < 0 || ageInt > 150) {
        throw FormatException(
          'Invalid age: must be a number between 0 and 150',
        );
      }
    }

    // Validate role
    final role = json['role']?.toString() ?? 'player';
    if (!['player', 'admin', 'moderator'].contains(role)) {
      throw FormatException(
        'Invalid role: must be player, admin, or moderator',
      );
    }

    // Validate gender if provided
    final gender = json['gender']?.toString();
    if (gender != null && !['male', 'female', 'other'].contains(gender)) {
      throw FormatException('Invalid gender: must be male, female, or other');
    }

    return User(
      id: id.toString(),
      name: name.toString().trim(),
      email: email.toString().trim(),
      position: json['position']?.toString(),
      bio: json['bio']?.toString(),
      imageUrl: json['avatar_url']?.toString() ?? json['image_url']?.toString(),
      role: role,
      createdAt: createdAt,
      age: age != null ? int.parse(age.toString()) : null,
      phone: json['phone']?.toString(),
      gender: gender,
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Use database-friendly snake_case keys (full_name) to avoid inconsistency
      'full_name': name,
      'email': email,
      'position': position,
      'bio': bio,
      // Use avatar_url as canonical key for profile images (backend expects this)
      'avatar_url': imageUrl,
      // Persist role instead of computed is_admin flag
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'age': age,
      'phone': phone,
      'gender': gender,
      'location': location,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? position,
    String? bio,
    String? imageUrl,
    String? role,
    bool? isAdmin,
    DateTime? createdAt,
    int? age,
    String? phone,
    String? gender,
    String? location,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      location: location ?? this.location,
    );
  }
}
