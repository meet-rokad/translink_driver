class ReturnRequirement {
  final String? id;
  final String partnerId;
  final String? truckId;
  final String origin;
  final String destination;
  final DateTime routeDate;
  final DateTime? expectedAvailability;
  final double? currentLocationLat;
  final double? currentLocationLng;
  final String? loadType;
  final String? notes;
  final String status;
  final int contactCount;
  final double? price;

  ReturnRequirement({
    this.id,
    required this.partnerId,
    this.truckId,
    required this.origin,
    required this.destination,
    required this.routeDate,
    this.expectedAvailability,
    this.currentLocationLat,
    this.currentLocationLng,
    this.loadType,
    this.notes,
    this.status = 'Active',
    this.contactCount = 0,
    this.price,
  });

  factory ReturnRequirement.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['contact_events'] != null && json['contact_events'] is List && json['contact_events'].isNotEmpty) {
      count = json['contact_events'][0]['count'] ?? 0;
    }

    return ReturnRequirement(
      id: json['id'],
      partnerId: json['partner_id'],
      truckId: json['truck_id'],
      origin: json['origin'],
      destination: json['destination'],
      routeDate: DateTime.parse(json['route_date']),
      expectedAvailability: json['availability_time'] != null ? DateTime.parse(json['availability_time']) : null,
      currentLocationLat: json['current_location'] != null ? double.tryParse(json['current_location'].toString().split(',')[0]) : null,
      currentLocationLng: json['current_location'] != null ? double.tryParse(json['current_location'].toString().split(',')[1]) : null,
      notes: json['notes'],
      status: json['status'] ?? 'Active',
      contactCount: count,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      'truck_id': truckId,
      'origin': origin,
      'destination': destination,
      'route_date': routeDate.toIso8601String().split('T').first,
      'availability_time': expectedAvailability?.toIso8601String(),
      'current_location': (currentLocationLat != null && currentLocationLng != null) ? '$currentLocationLat,$currentLocationLng' : null,
      'status': status,
      if (price != null) 'price': price,
    };
  }
}
