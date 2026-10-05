import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_model.dart';
import '../models/partner_model.dart';
import '../models/partner_profile_model.dart';
import '../models/truck_model.dart';
import '../models/return_requirement_model.dart';
import '../models/partner_document_model.dart';
import '../models/truck_document_model.dart';
import '../models/contact_event_model.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(Supabase.instance.client);
});

class PartnerRepository {
  final SupabaseClient _supabase;

  PartnerRepository(this._supabase);

  Future<Partner?> getPartnerById(String id) async {
    try {
      final response = await _supabase
          .from('partner_profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Partner.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching partner: $e');
      return null;
    }
  }

  Future<void> createPartner(Partner partner) async {
    try {
      await _supabase.from('partner_profiles').insert(partner.toJson());
    } catch (e) {
      print('Error creating partner: $e');
      rethrow;
    }
  }

  Future<PartnerProfile?> getPartnerProfile(String partnerId) async {
    try {
      final response = await _supabase
          .from('partner_profiles')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (response != null) {
        return PartnerProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching partner profile: $e');
      return null;
    }
  }

  Future<void> createPartnerProfile(PartnerProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabase.from('partner_profiles').upsert({
        'id': profile.partnerId,
        'owner_name': profile.ownerName,
        'city': profile.city,
        'state': profile.state,
        if (profile.mobileNumber != null) 'mobile_number': profile.mobileNumber,
        if (profile.profilePic != null) 'profile_pic': profile.profilePic,
        if (user.email != null) 'email': user.email,
        'account_status': 'under_verification',
      });
    } catch (e) {
      print('Error creating/updating partner profile: $e');
      rethrow;
    }
  }

  Future<void> createTruck(Truck truck) async {
    try {
      await _supabase.from('trucks').insert(truck.toJson());
    } catch (e) {
      print('Error creating truck: $e');
      rethrow;
    }
  }

  Future<Truck?> getActiveTruck(String partnerId) async {
    try {
      final response = await _supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        return Truck.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching active truck: $e');
      return null;
    }
  }

  Future<List<Truck>> getPartnerTrucks(String partnerId) async {
    try {
      final response = await _supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);
      return (response as List).map((t) => Truck.fromJson(t)).toList();
    } catch (e) {
      print('Error fetching partner trucks: $e');
      return [];
    }
  }

  Future<void> createReturnRequirement(ReturnRequirement req) async {
    try {
      await _supabase.from('return_requirements').insert(req.toJson());
    } catch (e) {
      print('Error creating requirement: $e');
      rethrow;
    }
  }

  Future<void> createPartnerDocument(PartnerDocument doc) async {
    try {
      // In the new schema, we consolidated this into the 'documents' table
      await _supabase.from('documents').insert({
        'partner_id': doc.partnerId,
        'document_type': doc.documentType,
        'file_path': doc.fileUrl,
      });
    } catch (e) {
      print('Error creating partner document: $e');
      rethrow;
    }
  }

  Future<void> createTruckDocument(TruckDocument doc) async {
    try {
      // Consolidated into 'documents' table
      await _supabase.from('documents').insert({
        'partner_id': doc.partnerId,
        'truck_id': doc.truckId,
        'document_type': doc.documentType,
        'file_path': doc.fileUrl,
      });
    } catch (e) {
      print('Error creating truck document: $e');
      rethrow;
    }
  }

  Future<List<ReturnRequirement>> getReturnRequirementsHistory(String partnerId) async {
    try {
      final response = await _supabase
          .from('return_requirements')
          .select('*, contact_events(count)')
          .eq('partner_id', partnerId)
          .order('route_date', ascending: false);
          
      return (response as List).map((req) => ReturnRequirement.fromJson(req)).toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<void> deleteReturnRequirement(String id) async {
    try {
      await _supabase
          .from('return_requirements')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting requirement: $e');
      rethrow;
    }
  }

  Future<void> createContactEvent(ContactEvent event) async {
    try {
      await _supabase.from('contact_events').insert(event.toJson());
    } catch (e) {
      print('Error logging contact event: $e');
      rethrow;
    }
  }
}





