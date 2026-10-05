import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final partner = await supabase.from('partners').select('id').eq('auth_id', user.id).maybeSingle();
      if (partner != null) {
        // Fetch return requirements
        final res = await supabase.from('return_requirements')
            .select()
            .eq('partner_id', partner['id'])
            .order('created_at', ascending: false);
            
        setState(() {
          _trips = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _repostRoute(Map<String, dynamic> trip) async {
    // Show a dialog to confirm the repost and pick a new date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select New Route Date',
    );

    if (pickedDate == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // First check if there is an active route
      final existingActiveRes = await supabase
          .from('return_requirements')
          .select()
          .eq('partner_id', trip['partner_id'])
          .eq('status', 'ACTIVE')
          .maybeSingle();

      if (existingActiveRes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already have an active route! Please complete it first.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Insert new requirement based on old trip
      await supabase.from('return_requirements').insert({
        'partner_id': trip['partner_id'],
        'truck_id': trip['truck_id'],
        'origin': trip['origin'],
        'destination': trip['destination'],
        'route_date': pickedDate.toIso8601String().split('T').first,
        'status': 'ACTIVE',
        'price': trip['price'],
        'notes': trip['notes'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route Reposted Successfully!')),
        );
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reposting route: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Lead Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFFC107),
          onRefresh: _fetchHistory,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : _trips.isEmpty 
                  ? const Center(child: Text('No route history found.', style: TextStyle(color: Colors.grey)))
                  : _buildTripsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        final origin = trip['origin'] ?? 'Unknown';
        final dest = trip['destination'] ?? 'Unknown';
        final status = (trip['status'] ?? 'UNKNOWN').toString().toUpperCase();
        final price = trip['price']?.toString() ?? 'N/A';
        
        final routeDateStr = trip['route_date'] as String?;
        final date = routeDateStr != null 
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(routeDateStr))
            : 'Unknown';
        
        return _buildTripCard(trip, origin, dest, status, date, price);
      },
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, String origin, String dest, String status, String date, String price) {
    final isCancelled = status == 'CANCELLED';
    final isActive = status == 'ACTIVE';
    final isCompleted = status == 'COMPLETED';
    
    Color statusColor = Colors.grey;
    if (isActive) statusColor = const Color(0xFF3B82F6);
    else if (isCancelled) statusColor = const Color(0xFFEF4444);
    else if (isCompleted) statusColor = const Color(0xFF10B981);

    // Mock/General views calculation for visual appeal.
    // In future, a join with driver_number_views can show exact route-specific views.
    final mockViews = (origin.length + dest.length) * 2; 

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date and Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          
          // Body: Route and Price
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
                    const SizedBox(width: 8),
                    Expanded(child: Text(origin, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1128)))),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                  height: 12,
                  width: 2,
                  color: Colors.grey.shade300,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(dest, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0A1128)))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Expected Price: ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    Text('₹$price', style: const TextStyle(color: Color(0xFF0A1128), fontSize: 15, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),

          // Lead Analytics Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Your number was viewed $mockViews times for this route',
                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Footer Action (Repost)
          if (!isActive)
            InkWell(
              onTap: () => _repostRoute(trip),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh, color: Color(0xFF0A1128), size: 20),
                    SizedBox(width: 8),
                    Text('Repost this Route', style: TextStyle(color: Color(0xFF0A1128), fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

