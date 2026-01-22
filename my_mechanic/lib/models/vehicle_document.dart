class VehicleDocument {
  final String? id;
  final String vehicleId;
  final String documentName;
  final String documentType;
  final String fileUrl;
  final int fileSize;
  final DateTime uploadedAt;

  VehicleDocument({
    this.id,
    required this.vehicleId,
    required this.documentName,
    required this.documentType,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'document_name': documentName,
      'document_type': documentType,
      'file_url': fileUrl,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      documentName: json['document_name'],
      documentType: json['document_type'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
