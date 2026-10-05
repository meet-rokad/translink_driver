import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _partner;
  Map<String, dynamic>? _truck;
  Map<String, dynamic>? _activeRequirement;
  List<Map<String, dynamic>> _notifications = [];
  int _viewsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load partner by auth_id (stored in JWT sub claim)
      final partnerRes = await supabase
          .from('partners')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      if (partnerRes == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      _partner = partnerRes;
      final partnerId = partnerRes['id'];

      // Load active truck
      final truckRes = await supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_active', true)
          .maybeSingle();
      _truck = truckRes;

      // Load active return requirement
      final reqRes = await supabase
          .from('return_requirements')
          .select()
          .eq('partner_id', partnerId)
          .eq('status', 'ACTIVE')
          .maybeSingle();
      _activeRequirement = reqRes;

      // Load recent unread notifications (max 3)
      final notifRes = await supabase
          .from('notifications')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(3);
      _notifications = List<Map<String, dynamic>>.from(notifRes);

      // Load driver number views
      try {
        final viewsRes = await supabase
            .from('driver_number_views')
            .select('id')
            .eq('partner_id', partnerId);
        _viewsCount = (viewsRes as List).length;
      } catch (e) {
        print('Error loading views: $e');
      }

    } catch (e) {
      print('Dashboard load error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = _partner?['full_name'] as String? ?? 'Partner';
    final status = _partner?['status'] as String? ?? 'NEW';
    final verified = _partner?['verification_status'] == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFFFC107),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(name, verified),
                          const SizedBox(height: 8),
                          if (!verified) _buildVerificationBanner(status),
                          const SizedBox(height: 24),
                          _buildReturnRequirementSection(),
                          const SizedBox(height: 24),
                          _buildAnalyticsSection(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          if (_truck != null) _buildMyTruckCard(),
                          if (_truck == null) _buildAddTruckCard(),
                          const SizedBox(height: 24),
                          if (_notifications.isNotEmpty) _buildNotificationsSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, bool verified) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Row(
      children: [
        // Profile pic
        GestureDetector(
          onTap: () => context.go('/account'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E7EB),
              image: (_partner?['profile_photo_url'] as String?)?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(_partner!['profile_photo_url'] as String),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (_partner?['profile_photo_url'] as String?)?.isEmpty != false
                ? const Icon(Icons.person, color: Color(0xFF6B7280))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              Row(
                children: [
                  Text(
                    '$name 👋',
                    style: const TextStyle(
                      color: Color(0xFF0A1128),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notifications bell
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Icon(Icons.notifications_none, size: 20, color: Color(0xFF0A1128)),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBanner(String status) {
    String message;
    Color color;
    IconData icon;

    if (status == 'VERIFICATION_PENDING') {
      message = 'Your profile is under review. We\'ll notify you soon.';
      color = const Color(0xFFFEF3C7);
      icon = Icons.access_time;
    } else if (status == 'DOCUMENTS_INCOMPLETE') {
      message = 'Upload required documents to get verified.';
      color = const Color(0xFFFEF3C7);
      icon = Icons.warning_amber_outlined;
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push('/document_upload'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD97706), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnRequirementSection() {
    if (_activeRequirement != null) {
      return _buildActiveRequirementCard();
    }

    // No active requirement — show CTA
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFFFFC107), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Return Load',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Need a Return Load?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Post your return requirement and let shippers find you.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/requirement/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF0A1128),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Return Requirement',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequirementCard() {
    final req = _activeRequirement!;
    final origin = req['origin'] as String? ?? 'Origin';
    final destination = req['destination'] as String? ?? 'Destination';
    final date = req['route_date'] as String?;
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE REQUIREMENT',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  origin,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFFFFC107), size: 18),
                ),
              ),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReqAction(Icons.edit_outlined, 'Edit', () => context.push('/requirement/edit')),
              _buildReqAction(Icons.location_on_outlined, 'Update Location', () {}),
              _buildReqAction(Icons.check_circle_outline, 'Complete', () => _completeRequirement()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReqAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _completeRequirement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Requirement?'),
        content: const Text('Are you sure you want to mark this return requirement as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _activeRequirement != null) {
      try {
        await Supabase.instance.client
            .from('return_requirements')
            .update({'status': 'COMPLETED', 'completed_at': DateTime.now().toIso8601String()})
            .eq('id', _activeRequirement!['id']);
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ANALYTICS',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_viewsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Total Number Views',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.local_shipping_outlined, 'My Truck', const Color(0xFF3B82F6), () => context.push('/my_vehicles'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.description_outlined, 'Documents', const Color(0xFF8B5CF6), () => context.push('/document_upload'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.history, 'History', const Color(0xFFF97316), () => context.go('/history'))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.support_agent_outlined, 'Support', const Color(0xFF10B981), () {})),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0A1128))),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTruckCard() {
    final truck = _truck!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MY TRUCK',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/my_vehicles'),
          child: Container(
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck['vehicle_number'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${truck['vehicle_type'] ?? 'N/A'} • ${truck['body_type'] ?? 'N/A'} • ${truck['capacity'] ?? ''} ${truck['capacity_unit'] ?? 'Ton'}',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTruckCard() {
    return GestureDetector(
      onTap: () => context.push('/add_vehicle'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: Color(0xFFFFC107), size: 24),
            SizedBox(width: 8),
            Text('Add Your Truck', style: TextStyle(color: Color(0xFF0A1128), fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: const Text('See all', style: TextStyle(color: Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._notifications.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (n['message'] != null)
                        Text(n['message'] as String, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
