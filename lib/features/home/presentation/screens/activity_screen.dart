import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/driver_providers.dart';
import '../../models/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _activeTab = 'All';

  @override
  Widget build(BuildContext context) {
    final activitiesAsyncValue = ref.watch(driverActivitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                _buildTab('All'),
                const SizedBox(width: 12),
                _buildTab('Trips'),
                const SizedBox(width: 12),
                _buildTab('Payments'),
              ],
            ),
          ),
          
          // Activity List
          Expanded(
            child: activitiesAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (activities) {
                // Filter
                List<ActivityModel> filtered = activities;
                if (_activeTab == 'Trips') {
                  filtered = activities.where((e) => e.activityType == 'load_request' || e.activityType == 'trip_update').toList();
                } else if (_activeTab == 'Payments') {
                  filtered = activities.where((e) => e.activityType == 'payment').toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No activities found', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filtered.length) return const SizedBox(height: 80);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildActivityCard(filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _activeTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A1128) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    IconData icon = Icons.notifications;
    Color iconColor = const Color(0xFF3B82F6);
    Color iconBgColor = const Color(0xFFEFF6FF);

    if (activity.activityType == 'load_request') {
      icon = Icons.local_shipping_outlined;
    } else if (activity.activityType == 'payment') {
      icon = Icons.check;
      iconColor = const Color(0xFF10B981);
      iconBgColor = const Color(0xFFECFDF5);
    } else if (activity.activityType == 'trip_update') {
      icon = Icons.flag_outlined;
      iconColor = const Color(0xFFF97316);
      iconBgColor = const Color(0xFFFFF7ED);
    } else if (activity.activityType == 'profile_update') {
      icon = Icons.person_outline;
      iconColor = const Color(0xFF8B5CF6);
      iconBgColor = const Color(0xFFF5F3FF);
    }

    final timeString = timeago.format(activity.createdAt);
    final subtitleWithTime = activity.subtitle != null ? '${activity.subtitle} — $timeString' : timeString;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleWithTime,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
