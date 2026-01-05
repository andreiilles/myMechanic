class Vehicle {
  final String? id;
  final String? ownerId;
  final String make;
  final String model;
  final int year;
  final String vin;
  final int currentMileage;
  final String? licensePlate;
  final String? color;
  final String? imageUrl;
  final String? notes;
  final DateTime? lastTechnicalInspection;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    this.ownerId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.currentMileage,
    this.licensePlate,
    this.color,
    this.imageUrl,
    this.notes,
    this.lastTechnicalInspection,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      if (ownerId != null) 'owner_id': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'current_mileage': currentMileage,
      'license_plate': licensePlate,
      'color': color,
      'image_url': imageUrl,
      'notes': notes,
      'last_technical_inspection': lastTechnicalInspection?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      ownerId: json['owner_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vin: json['vin'],
      currentMileage: json['current_mileage'],
      licensePlate: json['license_plate'],
      color: json['color'],
      imageUrl: json['image_url'],
      notes: json['notes'],
      lastTechnicalInspection: json['last_technical_inspection'] != null 
          ? DateTime.parse(json['last_technical_inspection']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Vehicle copyWith({
    String? id,
    String? ownerId,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? currentMileage,
    String? licensePlate,
    String? color,
    String? imageUrl,
    String? notes,
    DateTime? lastTechnicalInspection,
    bool clearImageUrl = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      currentMileage: currentMileage ?? this.currentMileage,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      notes: notes ?? this.notes,
      lastTechnicalInspection: lastTechnicalInspection ?? this.lastTechnicalInspection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
