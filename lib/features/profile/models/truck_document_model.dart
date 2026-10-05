class TruckDocument {
  final String? id;
  final String partnerId;
  final String truckId;
  final String documentType; // RC, Insurance, Fitness, PUC
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? fileUrl;
  final String verificationStatus; // Not Uploaded, Uploaded, Under Review, Approved, Rejected
  final String? rejectionReason;

  TruckDocument({
    this.id,
    required this.partnerId,
    required this.truckId,
    required this.documentType,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.fileUrl,
    this.verificationStatus = 'Uploaded',
    this.rejectionReason,
  });

  factory TruckDocument.fromJson(Map<String, dynamic> json) {
    return TruckDocument(
      id: json['id'],
      partnerId: json['partner_id'],
      truckId: json['truck_id'],
      documentType: json['document_type'],
      documentNumber: json['document_number'],
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      fileUrl: json['file_url'],
      verificationStatus: json['verification_status'] ?? 'Uploaded',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      'truck_id': truckId,
      'document_type': documentType,
      'document_number': documentNumber,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'file_url': fileUrl,
      'verification_status': verificationStatus,
      'rejection_reason': rejectionReason,
    };
  }
}
