// profile_repository.dart — Rewritten to use Supabase only.
// No Firestore, no Firebase Storage (uses Supabase Storage).

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<UserProfile?> getUserProfile(String authId) async {
    try {
      final data = await _supabase
          .from('partners')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromMap(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    await _supabase.from('partners').insert({
      'auth_id': profile.uid,
      'full_name': profile.fullName,
      'mobile_number': profile.phoneNumber,
      'city': profile.city,
      'profile_photo_url': profile.profileImageUrl,
      'status': 'NEW',
    });
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _supabase.from('partners').update({
      'full_name': profile.fullName,
      'city': profile.city,
      'profile_photo_url': profile.profileImageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('auth_id', profile.uid);
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final path = 'profiles/$uid/avatar.jpg';
    await _supabase.storage
        .from('partner-documents')
        .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from('partner-documents').getPublicUrl(path);
  }
}
