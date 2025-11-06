class Mechanic {
  final String? id;
  final String userId; // References users table
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? licenseNumber;
  final List<String> specializations;
  final double? averageRating;
  final int totalReviews;
  final bool isVerified;
  final bool isAcceptingClients;
  final String? description;
  final double? hourlyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Mechanic({
    this.id,
    required this.userId,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.licenseNumber,
    this.specializations = const [],
    this.averageRating,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isAcceptingClients = true,
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
      'business_phone': businessPhone,
      'license_number': licenseNumber,
      'specializations': specializations,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_verified': isVerified,
      'is_accepting_clients': isAcceptingClients,
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
      businessPhone: json['business_phone'],
      licenseNumber: json['license_number'],
      specializations: json['specializations'] != null 
          ? List<String>.from(json['specializations'])
          : [],
      averageRating: json['average_rating']?.toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isAcceptingClients: json['is_accepting_clients'] ?? true,
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
    String? businessPhone,
    String? licenseNumber,
    List<String>? specializations,
    double? averageRating,
    int? totalReviews,
    bool? isVerified,
    bool? isAcceptingClients,
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
      businessPhone: businessPhone ?? this.businessPhone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specializations: specializations ?? this.specializations,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isAcceptingClients: isAcceptingClients ?? this.isAcceptingClients,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
