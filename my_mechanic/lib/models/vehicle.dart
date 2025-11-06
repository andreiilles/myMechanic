class Vehicle {
  final String? id;
  final String ownerId;
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
    required this.ownerId,
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

  /// Calculate vehicle age in years
  int get vehicleAge {
    final now = DateTime.now();
    return now.year - year;
  }

  /// Calculate next technical inspection date based on Romanian ITP regulations
  DateTime? get nextTechnicalInspection {
    if (lastTechnicalInspection == null) return null;
    
    final age = vehicleAge;
    
    // New cars (0-3 years): First inspection at 3 years
    if (age < 3) {
      // Next inspection is 3 years from first registration (manufacturing year)
      return DateTime(year + 3, lastTechnicalInspection!.month, lastTechnicalInspection!.day);
    }
    // Cars 3-12 years old: Every 2 years
    else if (age >= 3 && age < 12) {
      return DateTime(
        lastTechnicalInspection!.year + 2,
        lastTechnicalInspection!.month,
        lastTechnicalInspection!.day,
      );
    }
    // Cars over 12 years old: Annual inspection
    else {
      return DateTime(
        lastTechnicalInspection!.year + 1,
        lastTechnicalInspection!.month,
        lastTechnicalInspection!.day,
      );
    }
  }

  /// Get inspection interval description
  String get inspectionIntervalDescription {
    final age = vehicleAge;
    
    if (age < 3) {
      return 'First inspection at 3 years';
    } else if (age >= 3 && age < 12) {
      return 'Every 2 years';
    } else {
      return 'Annual inspection';
    }
  }

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      'owner_id': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'current_mileage': currentMileage,
      'license_plate': licensePlate,
      'color': color,
      'image_url': imageUrl,
      'notes': notes,
      'last_technical_inspection': lastTechnicalInspection?.toIso8601String(),
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
    bool clearLastTechnicalInspection = false,
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
      lastTechnicalInspection: clearLastTechnicalInspection 
          ? null 
          : (lastTechnicalInspection ?? this.lastTechnicalInspection),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
