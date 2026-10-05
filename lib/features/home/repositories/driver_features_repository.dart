import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/load_model.dart';
import '../models/trip_model.dart';
import '../models/earning_model.dart';
import '../models/activity_model.dart';

final driverFeaturesRepositoryProvider = Provider<DriverFeaturesRepository>((ref) {
  return DriverFeaturesRepository(Supabase.instance.client);
});

class DriverFeaturesRepository {
  final SupabaseClient _supabase;

  DriverFeaturesRepository(this._supabase);

  // --- LOADS ---
  Future<List<LoadModel>> getAvailableLoads() async {
    try {
      final response = await _supabase
          .from('driver_loads')
          .select()
          .eq('status', 'available')
          .order('created_at', ascending: false);
      return (response as List).map((e) => LoadModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching loads: $e');
      return [];
    }
  }
  
  Future<void> createLoad(Map<String, dynamic> loadData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Automatically assign shipper_id and name
      loadData['shipper_id'] = user.id;
      loadData['shipper_name'] = loadData['shipper_name'] ?? 'Demo Shipper';
      loadData['shipper_contact'] = loadData['shipper_contact'] ?? '9876543210';
      loadData['status'] = 'available';

      await _supabase.from('driver_loads').insert(loadData);
    } catch (e) {
      print('Error creating load: $e');
      rethrow;
    }
  }
  
  Future<LoadModel?> getLoadById(String id) async {
    try {
      final response = await _supabase.from('driver_loads').select().eq('id', id).maybeSingle();
      if (response != null) return LoadModel.fromJson(response);
      return null;
    } catch (e) {
      print('Error fetching load details: $e');
      return null;
    }
  }

  // --- TRIPS ---
  Future<List<TripModel>> getDriverTrips() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      final response = await _supabase
          .from('driver_trips')
          .select()
          .eq('driver_id', user.id)
          .order('created_at', ascending: false);
      return (response as List).map((e) => TripModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }
  
  Future<void> assignLoadToDriver(String loadId, String truckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update load status
      await _supabase.from('driver_loads').update({'status': 'assigned'}).eq('id', loadId);
      
      // Create trip record
      await _supabase.from('driver_trips').insert({
        'load_id': loadId,
        'driver_id': user.id,
        'truck_id': truckId,
        'status': 'confirmed'
      });
      
      // Log activity
      await logActivity('load_request', 'Trip Confirmed', 'You successfully booked a load.');
    } catch (e) {
      print('Error assigning load: $e');
      rethrow;
    }
  }

  // --- EARNINGS ---
  Future<List<EarningModel>> getDriverEarnings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      final response = await _supabase
          .from('driver_earnings')
          .select()
          .eq('driver_id', user.id)
          .order('transaction_date', ascending: false);
      return (response as List).map((e) => EarningModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching earnings: $e');
      return [];
    }
  }

  // --- ACTIVITIES ---
  Future<List<ActivityModel>> getDriverActivities() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      final response = await _supabase
          .from('driver_activities')
          .select()
          .eq('driver_id', user.id)
          .order('created_at', ascending: false);
      return (response as List).map((e) => ActivityModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }
  
  Future<void> logActivity(String type, String title, String subtitle) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      await _supabase.from('driver_activities').insert({
        'driver_id': user.id,
        'activity_type': type,
        'title': title,
        'subtitle': subtitle
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }
}
