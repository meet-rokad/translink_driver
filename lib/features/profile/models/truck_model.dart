class Truck {
  final String? id;
  final String partnerId;
  final String truckNumber;
  final String? vehicleType;
  final String? bodyType;
  final double? capacity;
  final String? capacityUnit;
  final double? length;
  final double? width;
  final double? height;
  final String status;
  final bool isActive;
  final String? currentLocation;
  final String? regularStartingLocation;
  final String? regularRoutes;
  final String? driverName;
  final String? driverMobileNumber;

  Truck({
    this.id,
    required this.partnerId,
    required this.truckNumber,
    this.vehicleType,
    this.bodyType,
    this.capacity,
    this.capacityUnit,
    this.length,
    this.width,
    this.height,
    this.status = 'Available',
    this.isActive = false,
    this.currentLocation,
    this.regularStartingLocation,
    this.regularRoutes,
    this.driverName,
    this.driverMobileNumber,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      partnerId: json['partner_id'],
      truckNumber: json['truck_number'],
      vehicleType: json['vehicle_type'],
      bodyType: json['body_type'],
      capacity: json['capacity']?.toDouble(),
      capacityUnit: json['capacity_unit'],
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      status: json['status'] ?? 'Available',
      isActive: json['is_active'] ?? false,
      currentLocation: json['current_location'],
      regularStartingLocation: json['regular_starting_location'],
      regularRoutes: json['regular_routes'],
      driverName: json['driver_name'],
      driverMobileNumber: json['driver_mobile_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      'truck_number': truckNumber,
      'vehicle_type': vehicleType,
      'body_type': bodyType,
      'capacity': capacity,
      'is_active': isActive,
      'current_location': currentLocation,
      'regular_starting_location': regularStartingLocation,
      'regular_routes': regularRoutes,
      'driver_name': driverName,
      'driver_mobile_number': driverMobileNumber,
    };
  }
}
