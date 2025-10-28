class Mechanic {
  final String? id;
  final String userId; // References users table
  final String businessName;
  final String? businessAddress;
  final String? licenseNumber;
  final List<String> specializations;
  final double? rating;
  final int totalReviews;
  final bool isVerified;
  final String? description;
  final double? hourlyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Mechanic({
    this.id,
    required this.userId,
    required this.businessName,
    this.businessAddress,
    this.licenseNumber,
    this.specializations = const [],
    this.rating,
    this.totalReviews = 0,
    this.isVerified = false,
    this.description,
    this.hourlyRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = <String, dynamic>{
      'user_id': userId,
      'business_name': businessName,
      'business_address': businessAddress,
      'license_number': licenseNumber,
      'specializations': specializations,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_verified': isVerified,
      'description': description,
      'hourly_rate': hourlyRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it exists and we're not excluding it (for updates)
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    return Mechanic(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      businessAddress: json['business_address'],
      licenseNumber: json['license_number'],
      specializations: json['specializations'] != null 
          ? List<String>.from(json['specializations'])
          : [],
      rating: json['rating']?.toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      description: json['description'],
      hourlyRate: json['hourly_rate']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Mechanic copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessAddress,
    String? licenseNumber,
    List<String>? specializations,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    String? description,
    double? hourlyRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mechanic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
