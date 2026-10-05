// notification_service.dart — Firebase Messaging removed (not in dependencies).
// Notifications are stored in Supabase `notifications` table.
// Push notifications can be added later via firebase_messaging package.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final _supabase = Supabase.instance.client;

  /// Fetch unread notifications for the current partner.
  Future<List<Map<String, dynamic>>> getUnreadNotifications(String partnerId) async {
    try {
      final result = await _supabase
          .from('notifications')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  /// Mark all as read for a partner.
  Future<void> markAllAsRead(String partnerId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('partner_id', partnerId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
