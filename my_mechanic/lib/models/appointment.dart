enum AppointmentStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const AppointmentStatus(this.displayName);
  final String displayName;
}

class Appointment {
  final String? id;
  final String customerId;
  final String mechanicId;
  final String vehicleId;
  final DateTime appointmentDate;
  final int durationMinutes;
  final String serviceType;
  final String? description;
  final AppointmentStatus status;
  final double? estimatedCost;
  final double? finalCost;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    this.id,
    required this.customerId,
    required this.mechanicId,
    required this.vehicleId,
    required this.appointmentDate,
    this.durationMinutes = 60,
    required this.serviceType,
    this.description,
    this.status = AppointmentStatus.pending,
    this.estimatedCost,
    this.finalCost,
    this.notes,
    this.cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = {
      'customer_id': customerId,
      'mechanic_id': mechanicId,
      'vehicle_id': vehicleId,
      'appointment_date': appointmentDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'service_type': serviceType,
      'description': description,
      'status': status.name,
      'estimated_cost': estimatedCost,
      'final_cost': finalCost,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      customerId: json['customer_id'],
      mechanicId: json['mechanic_id'],
      vehicleId: json['vehicle_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      durationMinutes: json['duration_minutes'] ?? 60,
      serviceType: json['service_type'],
      description: json['description'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      estimatedCost: json['estimated_cost']?.toDouble(),
      finalCost: json['final_cost']?.toDouble(),
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Appointment copyWith({
    String? id,
    String? customerId,
    String? mechanicId,
    String? vehicleId,
    DateTime? appointmentDate,
    int? durationMinutes,
    String? serviceType,
    String? description,
    AppointmentStatus? status,
    double? estimatedCost,
    double? finalCost,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      mechanicId: mechanicId ?? this.mechanicId,
      vehicleId: vehicleId ?? this.vehicleId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      status: status ?? this.status,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
