import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/services/otp_service.dart';

// ============================================================
// Auth State Provider — tracks Supabase Auth changes
// ============================================================
final supabaseAuthProvider = Provider<sb.SupabaseClient>((ref) {
  return sb.Supabase.instance.client;
});

final authStateChangesProvider = StreamProvider<sb.AuthState>((ref) {
  return ref.watch(supabaseAuthProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<sb.User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.session?.user ?? sb.Supabase.instance.client.auth.currentUser;
});

// ============================================================
// OTP Verification State
// ============================================================
class OtpState {
  final bool isLoading;
  final String? error;
  
  const OtpState({
    this.isLoading = false,
    this.error,
  });
  
  OtpState copyWith({bool? isLoading, String? error}) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ============================================================
// Auth Controller
// ============================================================
final authControllerProvider = NotifierProvider<AuthController, OtpState>(() {
  return AuthController();
});

class AuthController extends Notifier<OtpState> {
  final OtpService _otpService = OtpService();
  
  @override
  OtpState build() => const OtpState();

  /// Step 1: Send OTP via custom Supabase Edge function
  Future<void> sendOtp(
    String phoneNumber, {
    required void Function() onCodeSent,
    required void Function(String) onError,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _otpService.sendOtp(phoneNumber);
      state = state.copyWith(isLoading: false);
      onCodeSent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError(e.toString());
    }
  }

  /// Step 2: Verify OTP via Supabase Auth
  Future<void> verifyOtp(
    String phoneNumber,
    String smsCode, {
    required void Function(String authId, String phoneNumber) onSuccess,
    required void Function(String) onError,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final supabase = sb.Supabase.instance.client;
      final response = await supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: smsCode,
        type: sb.OtpType.sms,
      );
      
      final user = response.user;
      
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Authentication failed.');
        onError('Authentication failed. Please try again.');
        return;
      }
      
      state = state.copyWith(isLoading: false);
      onSuccess(user.id, user.phone ?? phoneNumber);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      onError('Invalid OTP or something went wrong. Please try again.');
    }
  }

  /// Sign out from Supabase
  Future<void> signOut() async {
    await sb.Supabase.instance.client.auth.signOut();
    state = const OtpState();
  }
}

// ============================================================
// Partner Sync — lookup/create partner in Supabase
// ============================================================
final partnerSyncProvider = Provider<PartnerSync>((ref) => PartnerSync());

class PartnerSync {
  final _supabase = sb.Supabase.instance.client;

  /// After auth, find or create partner in Supabase.
  Future<Map<String, dynamic>?> findOrCreatePartner({
    required String authId, 
    required String mobileNumber,
  }) async {
    try {
      // 1. Look for existing partner using Supabase auth_id
      final existing = await _supabase
          .from('partners')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      
      if (existing != null) {
        return existing;
      }
      
      // 2. Create new partner
      final inserted = await _supabase
          .from('partners')
          .insert({
            'auth_id': authId, 
            'mobile_number': mobileNumber,
            'status': 'NEW',
          })
          .select()
          .single();
      
      return inserted;
    } catch (e) {
      print('Error finding/creating partner: $e');
      return null;
    }
  }

  /// Get current partner status
  Future<String?> getPartnerStatus(String authId) async {
    try {
      final result = await _supabase
          .from('partners')
          .select('status')
          .eq('auth_id', authId)
          .maybeSingle();
      return result?['status'] as String?;
    } catch (e) {
      return null;
    }
  }
}
