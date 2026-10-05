class ContactEvent {
  final String? id;
  final String consumerId;
  final String partnerId;
  final String? truckId;
  final String? requirementId;
  final String contactType; // e.g., 'WhatsApp', 'Phone Call'
  final DateTime contactTime;

  ContactEvent({
    this.id,
    required this.consumerId,
    required this.partnerId,
    this.truckId,
    this.requirementId,
    required this.contactType,
    required this.contactTime,
  });

  factory ContactEvent.fromJson(Map<String, dynamic> json) {
    return ContactEvent(
      id: json['id'],
      consumerId: json['consumer_identifier'] ?? 'guest',
      partnerId: json['partner_id'],
      requirementId: json['requirement_id'],
      contactType: json['contact_type'],
      contactTime: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'consumer_identifier': consumerId,
      'partner_id': partnerId,
      if (requirementId != null) 'requirement_id': requirementId,
      'contact_type': contactType,
    };
  }
}
