class TripModel {
  final String id;
  final String loadId;
  final String driverId;
  final String? truckId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  TripModel({
    required this.id,
    required this.loadId,
    required this.driverId,
    this.truckId,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      loadId: json['load_id'],
      driverId: json['driver_id'],
      truckId: json['truck_id'],
      status: json['status'],
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }
}
