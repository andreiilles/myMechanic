import 'maintenance_record.dart';

enum ReminderType {
  date,
  mileage,
  both
}

class MaintenanceReminder {
  final String? id;
  final String vehicleId;
  final MaintenanceType maintenanceType;
  final ReminderType reminderType;
  final DateTime? reminderDate;
  final int? reminderMileage;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceReminder({
    this.id,
    required this.vehicleId,
    required this.maintenanceType,
    required this.reminderType,
    this.reminderDate,
    this.reminderMileage,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'maintenance_type': maintenanceType.name,
      'reminder_type': reminderType.name,
      'reminder_date': reminderDate?.toIso8601String(),
      'reminder_mileage': reminderMileage,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    return MaintenanceReminder(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      maintenanceType: MaintenanceType.values.firstWhere(
        (e) => e.name == json['maintenance_type'],
        orElse: () => MaintenanceType.other,
      ),
      reminderType: ReminderType.values.firstWhere(
        (e) => e.name == json['reminder_type'],
        orElse: () => ReminderType.date,
      ),
      reminderDate: json['reminder_date'] != null 
          ? DateTime.parse(json['reminder_date']) 
          : null,
      reminderMileage: json['reminder_mileage'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  MaintenanceReminder copyWith({
    String? id,
    String? vehicleId,
    MaintenanceType? maintenanceType,
    ReminderType? reminderType,
    DateTime? reminderDate,
    int? reminderMileage,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceReminder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      reminderType: reminderType ?? this.reminderType,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderMileage: reminderMileage ?? this.reminderMileage,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
