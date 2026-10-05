class ActivityModel {
  final String id;
  final String driverId;
  final String activityType;
  final String title;
  final String? subtitle;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.driverId,
    required this.activityType,
    required this.title,
    this.subtitle,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      driverId: json['driver_id'],
      activityType: json['activity_type'],
      title: json['title'],
      subtitle: json['subtitle'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
