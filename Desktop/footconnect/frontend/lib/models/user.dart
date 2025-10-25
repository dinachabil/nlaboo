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
  }) : isAdmin = isAdmin ?? (role == 'admin');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      // Prefer 'full_name' (database), but support legacy 'name'
      name: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      position: json['position'],
      bio: json['bio'],
      // Support both avatar_url and image_url coming from different parts of the app
      imageUrl: json['avatar_url'] ?? json['image_url'],
      role: json['role'] ?? 'player',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      age: json['age'],
      phone: json['phone'],
      gender: json['gender'],
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
    );
  }
}