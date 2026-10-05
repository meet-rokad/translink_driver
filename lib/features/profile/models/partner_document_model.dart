class PartnerDocument {
  final String? id;
  final String partnerId;
  final String documentType; // PAN, Aadhaar, GST, Business Doc
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? fileUrl;
  final String verificationStatus; // Not Uploaded, Uploaded, Under Review, Approved, Rejected
  final String? rejectionReason;

  PartnerDocument({
    this.id,
    required this.partnerId,
    required this.documentType,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.fileUrl,
    this.verificationStatus = 'Uploaded',
    this.rejectionReason,
  });

  factory PartnerDocument.fromJson(Map<String, dynamic> json) {
    return PartnerDocument(
      id: json['id'],
      partnerId: json['partner_id'],
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
      'document_type': documentType,
      'document_number': documentNumber,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'file_url': fileUrl,
      'verification_status': verificationStatus,
      'rejection_reason': rejectionReason,
    };
  }
}
