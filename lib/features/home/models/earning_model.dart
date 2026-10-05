class EarningModel {
  final String id;
  final String driverId;
  final String? tripId;
  final double amount;
  final String status;
  final DateTime transactionDate;
  final String? description;

  EarningModel({
    required this.id,
    required this.driverId,
    this.tripId,
    required this.amount,
    required this.status,
    required this.transactionDate,
    this.description,
  });

  factory EarningModel.fromJson(Map<String, dynamic> json) {
    return EarningModel(
      id: json['id'],
      driverId: json['driver_id'],
      tripId: json['trip_id'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      transactionDate: DateTime.parse(json['transaction_date']),
      description: json['description'],
    );
  }
}
