class LoadModel {
  final String id;
  final String shipperId;
  final String shipperName;
  final String shipperContact;
  final String origin;
  final String destination;
  final String pickupLocation;
  final String dropLocation;
  final DateTime pickupDate;
  final String truckType;
  final String materialType;
  final String? distance;
  final double price;
  final String status;

  LoadModel({
    required this.id,
    required this.shipperId,
    required this.shipperName,
    required this.shipperContact,
    required this.origin,
    required this.destination,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupDate,
    required this.truckType,
    required this.materialType,
    this.distance,
    required this.price,
    required this.status,
  });

  factory LoadModel.fromJson(Map<String, dynamic> json) {
    return LoadModel(
      id: json['id'],
      shipperId: json['shipper_id'],
      shipperName: json['shipper_name'],
      shipperContact: json['shipper_contact'],
      origin: json['origin'],
      destination: json['destination'],
      pickupLocation: json['pickup_location'],
      dropLocation: json['drop_location'],
      pickupDate: DateTime.parse(json['pickup_date']),
      truckType: json['truck_type'],
      materialType: json['material_type'],
      distance: json['distance'],
      price: double.parse(json['price'].toString()),
      status: json['status'],
    );
  }
}
