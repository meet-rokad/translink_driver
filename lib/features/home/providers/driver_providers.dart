import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/driver_features_repository.dart';
import '../models/load_model.dart';
import '../models/trip_model.dart';
import '../models/earning_model.dart';
import '../models/activity_model.dart';

final availableLoadsProvider = FutureProvider<List<LoadModel>>((ref) async {
  final repo = ref.read(driverFeaturesRepositoryProvider);
  return repo.getAvailableLoads();
});

final driverTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final repo = ref.read(driverFeaturesRepositoryProvider);
  return repo.getDriverTrips();
});

final driverEarningsProvider = FutureProvider<List<EarningModel>>((ref) async {
  final repo = ref.read(driverFeaturesRepositoryProvider);
  return repo.getDriverEarnings();
});

final driverActivitiesProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final repo = ref.read(driverFeaturesRepositoryProvider);
  return repo.getDriverActivities();
});
