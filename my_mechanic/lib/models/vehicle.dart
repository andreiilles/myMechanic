class Vehicle {
  final String? id;
  final String userId;
  final String make;
  final String model;
  final int year;
  final String vin;
  final int currentMileage;
  final String? licensePlate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.currentMileage,
    this.licensePlate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      'user_id': userId,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'current_mileage': currentMileage,
      'license_plate': licensePlate,
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
      userId: json['user_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vin: json['vin'],
      currentMileage: json['current_mileage'],
      licensePlate: json['license_plate'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? currentMileage,
    String? licensePlate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      currentMileage: currentMileage ?? this.currentMileage,
      licensePlate: licensePlate ?? this.licensePlate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
