enum AppointmentStatus {
  pending('Pending'),           // Initial request from client
  accepted('Accepted'),          // Mechanic accepted the request
  declined('Declined'),          // Mechanic declined
  proposed('Date Proposed'),     // Mechanic proposed different date
  confirmed('Confirmed'),        // Client confirmed (or accepted proposal)
  inProgress('In Progress'),     // Service started
  completed('Completed'),        // Service completed
  cancelled('Cancelled');        // Cancelled by either party

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
  final DateTime? proposedDate;  // Mechanic's proposed alternative date
  final String? mechanicResponse;  // Mechanic's response message
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data loaded from joins
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? mechanic;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? mechanicShop;

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
    this.proposedDate,
    this.mechanicResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.customer,
    this.mechanic,
    this.vehicle,
    this.mechanicShop,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = <String, dynamic>{
      'customer_id': customerId,
      'mechanic_id': mechanicId,
      'vehicle_id': vehicleId,
      'appointment_date': appointmentDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'service_type': serviceType,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    // Only include optional fields if they have values
    if (description != null) json['description'] = description;
    if (estimatedCost != null) json['estimated_cost'] = estimatedCost;
    if (finalCost != null) json['final_cost'] = finalCost;
    if (notes != null) json['notes'] = notes;
    if (cancellationReason != null) json['cancellation_reason'] = cancellationReason;
    if (proposedDate != null) json['proposed_date'] = proposedDate!.toIso8601String();
    if (mechanicResponse != null) json['mechanic_response'] = mechanicResponse;
    
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
      proposedDate: json['proposed_date'] != null 
          ? DateTime.parse(json['proposed_date']) 
          : null,
      mechanicResponse: json['mechanic_response'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customer: json['customer'],
      mechanic: json['mechanic'],
      vehicle: json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty 
          ? (json['vehicles'] as List).first 
          : json['vehicle'],
      mechanicShop: json['mechanic_shop'],
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
    DateTime? proposedDate,
    String? mechanicResponse,
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
      proposedDate: proposedDate ?? this.proposedDate,
      mechanicResponse: mechanicResponse ?? this.mechanicResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
