class Review {
  final String? id;
  final String mechanicId;
  final String customerId;
  final String? appointmentId;
  final int rating;
  final String? reviewText;
  final String? responseText;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    this.id,
    required this.mechanicId,
    required this.customerId,
    this.appointmentId,
    required this.rating,
    this.reviewText,
    this.responseText,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      'mechanic_id': mechanicId,
      'customer_id': customerId,
      'appointment_id': appointmentId,
      'rating': rating,
      'review_text': reviewText,
      'response_text': responseText,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      mechanicId: json['mechanic_id'],
      customerId: json['customer_id'],
      appointmentId: json['appointment_id'],
      rating: json['rating'],
      reviewText: json['review_text'],
      responseText: json['response_text'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Review copyWith({
    String? id,
    String? mechanicId,
    String? customerId,
    String? appointmentId,
    int? rating,
    String? reviewText,
    String? responseText,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      mechanicId: mechanicId ?? this.mechanicId,
      customerId: customerId ?? this.customerId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      responseText: responseText ?? this.responseText,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
