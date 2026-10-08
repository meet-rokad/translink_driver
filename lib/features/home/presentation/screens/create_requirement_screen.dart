import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

// ---------------------------------------------------------------------------
// Mapbox Geocoding token
// ---------------------------------------------------------------------------
const _kMapboxToken =
    'pk.eyJ1IjoidG9tODE1NSIsImEiOiJjbXJheGkzZHoyNms2MndxcmE2N3NidzFhIn0.UT6Ql_m2sJScB7mKiIN9MQ';

// ---------------------------------------------------------------------------
// City Autocomplete Field Widget
// ---------------------------------------------------------------------------
class _CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSelected;

  const _CityAutocompleteField({
    required this.controller,
    required this.hintText,
    this.onSelected,
  });

  @override
  State<_CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<_CityAutocompleteField> {
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _removeOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.length < 2) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json'
        '?access_token=$_kMapboxToken'
        '&country=IN'
        '&types=place,locality,district'
        '&language=en'
        '&limit=6',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        if (mounted) {
          setState(() {
            _suggestions = features.cast<Map<String, dynamic>>();
            _loading = false;
          });
          _showOverlay();
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: _layerLink.leaderSize?.width ?? 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 8,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final feat = _suggestions[i];
                  final placeName = feat['place_name'] as String? ?? '';
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      widget.controller.text = placeName;
                      widget.onSelected?.call(placeName);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.location_city,
                          color: Colors.grey.shade400, size: 20),
                      title: Text(placeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            hintText: widget.hintText,
          hintStyle: const TextStyle(
              fontWeight: FontWeight.normal, color: Colors.black38),
          border: InputBorder.none,
          isDense: true,
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF3B82F6)),
                  ),
                )
              : null,
        ),
        onChanged: (val) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), () {
            _fetchSuggestions(val.trim());
          });
        },
      ),
    );
  }
}


class CreateRequirementScreen extends ConsumerStatefulWidget {
  const CreateRequirementScreen({super.key});

  @override
  ConsumerState<CreateRequirementScreen> createState() => _CreateRequirementScreenState();
}

class _CreateRequirementScreenState extends ConsumerState<CreateRequirementScreen> {
  // Route controllers (used by autocomplete fields)
  final _originCityController = TextEditingController();
  final _destinationCityController = TextEditingController();

  DateTime? _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _timeWindow = 'Any Time';
  bool _isLoadingLocation = false;
  bool _isSaving = false;

  double? _originLat;
  double? _originLng;
  double? _originAccuracy;
  DateTime? _originTimestamp;
  String _locationSource = 'GPS';

  Map<String, dynamic>? _partner;
  Map<String, dynamic>? _truck;

  @override
  void initState() {
    super.initState();
    _loadPartnerAndTruck();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _originCityController.dispose();
    _destinationCityController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerAndTruck() async {
    // DEV BYPASS: if no user is logged in, provide mock data for UI testing
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _partner = {'id': 'mock-partner-id'};
          _truck = {
            'id': 'mock-truck-id',
            'vehicle_number': 'GJ 05 XY 1234',
            'vehicle_type': 'Open Body',
            'capacity': '10',
            'capacity_unit': 'Ton'
          };
        });
      }
      return;
    }

    try {
      final profilesList = await supabase
          .from('profiles')
          .select('id')
          .eq('auth_user_id', user.id)
          .limit(1);

      if (profilesList.isEmpty) return;
      final profileId = profilesList.first['id'].toString();

      Map<String, dynamic>? partner;
      final partnerList = await supabase
          .from('partners')
          .select('id')
          .eq('profile_id', profileId)
          .limit(1);

      if (partnerList.isNotEmpty) {
        partner = partnerList.first;
      } else {
        try {
          final partnerByAuth = await supabase
              .from('partners')
              .select('id')
              .eq('id', user.id)
              .limit(1);
          if (partnerByAuth.isNotEmpty) {
            partner = partnerByAuth.first;
          }
        } catch (_) {}
      }

      if (partner == null || partner['id'] == null) {
        debugPrint('No partner found for user');
        return;
      }
      
      final partnerId = partner['id'];
      if (mounted) setState(() => _partner = {'id': partnerId});

      // Use partner ID (not profile ID) to find the truck
      final truckRes = await supabase
          .from('trucks')
          .select()
          .eq('partner_id', partnerId)
          .limit(1)
          .maybeSingle();
          
      if (mounted) setState(() => _truck = truckRes);
    } catch (e) {
      debugPrint("Error loading partner/truck: $e");
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          setState(() {
            _isLoadingLocation = false;
            _locationSource = 'MANUAL';
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _originLat = position.latitude;
        _originLng = position.longitude;
        _originAccuracy = position.accuracy;
        _originTimestamp = DateTime.now();
        _locationSource = 'GPS';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationSource = 'MANUAL';
      });
    }
  }

  Future<void> _saveRequirement() async {
    final returnOrigin = _originCityController.text.trim();
    final returnDest = _destinationCityController.text.trim();

    if (returnOrigin.isEmpty) {
      _showError('Please enter return pickup city');
      return;
    }
    if (returnDest.isEmpty) {
      _showError('Please enter return drop city');
      return;
    }
    
    if (_selectedDate == null) {
      _showError('Please select available date');
      return;
    }
    if (_partner == null) {
      _showError('Profile not loaded correctly.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      // DEV MOCK: Check if we are in test mode
      if (supabase.auth.currentUser == null) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Mode: Return trip posted successfully!'), backgroundColor: Colors.green));
          context.pop(true);
        }
        return;
      }

      // 1. Cancel any existing active return requirement for this partner
      await supabase.from('truck_availability')
          .update({'status': 'cancelled'})
          .eq('partner_id', _partner!['id'])
          .eq('status', 'available');

      TimeOfDay? start;
      TimeOfDay? end;
      switch (_timeWindow) {
        case 'Morning': start = const TimeOfDay(hour: 6, minute: 0); end = const TimeOfDay(hour: 12, minute: 0); break;
        case 'Afternoon': start = const TimeOfDay(hour: 12, minute: 0); end = const TimeOfDay(hour: 17, minute: 0); break;
        case 'Evening': start = const TimeOfDay(hour: 17, minute: 0); end = const TimeOfDay(hour: 21, minute: 0); break;
        default: start = const TimeOfDay(hour: 0, minute: 0); end = const TimeOfDay(hour: 23, minute: 59);
      }
      
      // Post DIRECT Return Trip into truck_availability
      final returnData = {
        'partner_id': _partner!['id'],
        'truck_id': _truck?['id'],
        'origin_city': returnOrigin,
        'destination_city': returnDest,
        'origin_latitude': _originLat,
        'origin_longitude': _originLng,
        'available_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'available_from_time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
        'available_until_time': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
        'status': 'available', // Ready for customer load matching
      };

      await supabase.from('truck_availability').insert(returnData);

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return trip posted successfully!'), backgroundColor: Color(0xFF10B981)));
        context.pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background for contrast
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Post New Trip',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TRUCK INFO CARD ---
                  _buildTruckCard(),
                  const SizedBox(height: 20),

                  // --- RETURN TRIP ROUTE CARD ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('RETURN ROUTE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ),
                  _buildRouteCard(),
                  const SizedBox(height: 20),

                  // --- DATE & TIME CARD ---
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('RETURN AVAILABILITY TIMINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  ),
                  _buildDateTimeCard(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: _isSaving 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : PrimaryButton(
              text: 'Post Return Trip',
              onPressed: _saveRequirement,
            ),
      ),
    );
  }

  // Helper UI Builders
  Widget _buildTruckCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping, color: AppColors.primaryDark, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _truck != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truck!['vehicle_number'] ?? _truck!['truck_number'] ?? 'No Number',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_truck!['vehicle_type'] ?? _truck!['truck_type'] ?? 'N/A'} • ${_truck!['capacity'] ?? _truck!['capacity_tons'] ?? ''} ${_truck!['capacity_unit'] ?? 'Ton'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              : const Text('Loading vehicle...', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // GPS Tag (Optional)
          if (_originLat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text('GPS Active', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  const Icon(Icons.circle, color: Colors.green, size: 16),
                  Container(height: 40, width: 2, color: Colors.grey.shade200),
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    // ORIGIN — Mapbox city autocomplete
                    _CityAutocompleteField(
                      controller: _originCityController,
                      hintText: 'Return From / Pickup (e.g. Mumbai)',
                    ),
                    const Divider(height: 30),
                    // DESTINATION — Mapbox city autocomplete
                    _CityAutocompleteField(
                      controller: _destinationCityController,
                      hintText: 'Return To / Drop (e.g. Surat)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: AppColors.textPrimary)), child: child!),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null ? DateFormat('EEEE, dd MMM yyyy').format(_selectedDate!) : 'Select Date',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Time Chips
          const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Morning', 'Afternoon', 'Evening', 'Any Time'].map((time) {
              final isSelected = _timeWindow == time;
              return GestureDetector(
                onTap: () => setState(() => _timeWindow = time),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textPrimary : Colors.white,
                    border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
