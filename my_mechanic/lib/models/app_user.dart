enum UserType {
  customer('Customer'),
  mechanic('Mechanic');

  const UserType(this.displayName);
  final String displayName;
}

class AppUser {
  final String? id;
  final String authId; // References auth.users(id)
  final String email;
  final String firstName;
  final String lastName;
  final UserType userType;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    this.id,
    required this.authId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phoneNumber,
    this.profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = <String, dynamic>{
      'auth_id': authId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType.name,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it exists and we're not excluding it (for updates)
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      authId: json['auth_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: UserType.values.firstWhere(
        (e) => e.name == json['user_type'],
        orElse: () => UserType.customer,
      ),
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  AppUser copyWith({
    String? id,
    String? authId,
    String? email,
    String? firstName,
    String? lastName,
    UserType? userType,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
