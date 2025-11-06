enum AccessLevel {
  view('View'),
  edit('Edit'),
  owner('Owner');

  const AccessLevel(this.displayName);
  final String displayName;
}

class VehicleAccess {
  final String? id;
  final String vehicleId;
  final String userId;
  final AccessLevel accessLevel;
  final String grantedBy;
  final DateTime grantedAt;

  VehicleAccess({
    this.id,
    required this.vehicleId,
    required this.userId,
    this.accessLevel = AccessLevel.view,
    required this.grantedBy,
    DateTime? grantedAt,
  }) : grantedAt = grantedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final json = <String, dynamic>{
      'vehicle_id': vehicleId,
      'user_id': userId,
      'access_level': accessLevel.name,
      'granted_by': grantedBy,
      'granted_at': grantedAt.toIso8601String(),
    };
    
    if (!excludeId && id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory VehicleAccess.fromJson(Map<String, dynamic> json) {
    return VehicleAccess(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      userId: json['user_id'],
      accessLevel: AccessLevel.values.firstWhere(
        (e) => e.name == json['access_level'],
        orElse: () => AccessLevel.view,
      ),
      grantedBy: json['granted_by'],
      grantedAt: DateTime.parse(json['granted_at']),
    );
  }

  VehicleAccess copyWith({
    String? id,
    String? vehicleId,
    String? userId,
    AccessLevel? accessLevel,
    String? grantedBy,
    DateTime? grantedAt,
  }) {
    return VehicleAccess(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      accessLevel: accessLevel ?? this.accessLevel,
      grantedBy: grantedBy ?? this.grantedBy,
      grantedAt: grantedAt ?? this.grantedAt,
    );
  }
}
