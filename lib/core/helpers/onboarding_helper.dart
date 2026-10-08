// lib/core/helpers/onboarding_helper.dart
// Checks how far the user has completed onboarding and returns the correct route.
// Step 1: Profile complete (owner_name != 'Pending' && != null)
// Step 2: At least one truck added
// Step 3: At least one document uploaded for that truck

import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingHelper {
  static final _supabase = Supabase.instance.client;
  static bool _isOnboardedCached = false;
  static String? _cachedUserId;

  static bool get isOnboarded => _isOnboardedCached;

  static void resetCache() {
    _isOnboardedCached = false;
    _cachedUserId = null;
  }

  /// Returns the route the user should be on based on their onboarding progress.
  /// '/dashboard'       → all 3 steps done
  /// '/document_upload' → step 3 incomplete
  /// '/add_vehicle'     → step 2 incomplete
  /// '/profile_setup'   → step 1 incomplete
  /// '/login'           → not logged in
  static Future<String> getOnboardingRoute() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _isOnboardedCached = false;
        _cachedUserId = null;
        return '/login';
      }

      // If user is already verified onboarded in current session, immediately return dashboard
      if (_isOnboardedCached && _cachedUserId == user.id) {
        return '/dashboard';
      }

      // 1. Fetch Profile
      final profilesList = await _supabase
          .from('profiles')
          .select('id, full_name, mobile_number, city')
          .eq('auth_user_id', user.id)
          .limit(1);

      if (profilesList.isEmpty) return '/profile_setup';
      final profileResp = profilesList.first;
      final String profileId = profileResp['id'].toString();
      final String? fullName = profileResp['full_name'] as String?;

      // 2. Fetch Partner
      Map<String, dynamic>? partner;
      final partnerList = await _supabase
          .from('partners')
          .select('id, owner_name')
          .eq('profile_id', profileId)
          .limit(1);

      if (partnerList.isNotEmpty) {
        partner = partnerList.first;
      } else {
        try {
          final partnerByAuth = await _supabase
              .from('partners')
              .select('id, owner_name')
              .eq('id', user.id)
              .limit(1);
          if (partnerByAuth.isNotEmpty) {
            partner = partnerByAuth.first;
          }
        } catch (_) {}
      }

      final ownerName = partner?['owner_name'] as String?;

      // Step 1 check: Profile complete?
      final isNameValid = fullName != null && fullName != 'Pending' && fullName.trim().isNotEmpty;
      final isOwnerValid = ownerName != null && ownerName != 'Pending' && ownerName.trim().isNotEmpty;

      if (!isNameValid && !isOwnerValid) {
        return '/profile_setup';
      }

      // Step 2 check: Truck added?
      String? partnerId = partner?['id']?.toString();
      List<dynamic> trucks = [];
      if (partnerId != null) {
        try {
          trucks = await _supabase
              .from('trucks')
              .select('id')
              .eq('partner_id', partnerId)
              .limit(1);
        } catch (_) {}
      }

      if (trucks.isEmpty) {
        try {
          final trucksByAuth = await _supabase
              .from('trucks')
              .select('id')
              .eq('partner_id', user.id)
              .limit(1);
          if (trucksByAuth.isNotEmpty) {
            trucks = trucksByAuth;
          }
        } catch (_) {}
      }

      if (trucks.isEmpty) return '/add_vehicle';

      // Step 3 check: Documents uploaded?
      final truckId = trucks[0]['id'];
      bool hasDocs = false;
      if (truckId != null) {
        try {
          final docCount = await _supabase
              .from('truck_documents')
              .select('id')
              .eq('truck_id', truckId)
              .limit(1);
          if ((docCount as List).isNotEmpty) {
            hasDocs = true;
          }
        } catch (_) {}
      }

      if (!hasDocs && partnerId != null) {
        try {
          final oldDocCount = await _supabase
              .from('documents')
              .select('id')
              .eq('partner_id', partnerId)
              .limit(1);
          if ((oldDocCount as List).isNotEmpty) {
            hasDocs = true;
          }
        } catch (_) {}
      }

      if (!hasDocs) return '/document_upload';

      // All done!
      _isOnboardedCached = true;
      _cachedUserId = user.id;
      return '/dashboard';
    } catch (e) {
      print('OnboardingHelper error: $e');
      // If error occurs but user is logged in, default to dashboard rather than kicking them out
      return '/dashboard';
    }
  }
}
