enum MaintenanceType {
  oilChange('Oil Change'),
  inspection('ITP/Inspection'),
  tireRotation('Tire Rotation'),
  brakeService('Brake Service'),
  engineService('Engine Service'),
  transmission('Transmission Service'),
  coolantFlush('Coolant Flush'),
  sparkPlugs('Spark Plugs'),
  airFilter('Air Filter'),
  fuelFilter('Fuel Filter'),
  batteryReplacement('Battery Replacement'),
  other('Other');

  const MaintenanceType(this.displayName);
  final String displayName;
}

class MaintenanceRecord {
  final String? id;
  final String vehicleId;
  final String? performedByUserId;
  final MaintenanceType type;
  final String? description;
  final double cost;
  final int mileageAtService;
  final DateTime serviceDate;
  final String? serviceProvider;
  final String? invoiceUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    this.performedByUserId,
    required this.type,
    this.description,
    required this.cost,
    required this.mileageAtService,
    required this.serviceDate,
    this.serviceProvider,
    this.invoiceUrl,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      'vehicle_id': vehicleId,
      'performed_by_user_id': performedByUserId,
      'maintenance_type': type.name,
      'description': description,
      'cost': cost,
      'mileage_at_service': mileageAtService,
      'service_date': serviceDate.toIso8601String(),
      'service_provider': serviceProvider,
      'invoice_url': invoiceUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      performedByUserId: json['performed_by_user_id'],
      type: MaintenanceType.values.firstWhere(
        (e) => e.name == json['maintenance_type'],
        orElse: () => MaintenanceType.other,
      ),
      description: json['description'],
      cost: (json['cost'] as num).toDouble(),
      mileageAtService: json['mileage_at_service'],
      serviceDate: DateTime.parse(json['service_date']),
      serviceProvider: json['service_provider'],
      invoiceUrl: json['invoice_url'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    String? performedByUserId,
    MaintenanceType? type,
    String? description,
    double? cost,
    int? mileageAtService,
    DateTime? serviceDate,
    String? serviceProvider,
    String? invoiceUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      type: type ?? this.type,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      mileageAtService: mileageAtService ?? this.mileageAtService,
      serviceDate: serviceDate ?? this.serviceDate,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
