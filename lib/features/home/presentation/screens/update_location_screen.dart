import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/mapbox_view.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateLocationScreen extends StatefulWidget {
  final String requirementId;

  const UpdateLocationScreen({super.key, required this.requirementId});

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  LatLng? _selectedLocation;
  bool _isLoading = false;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  Future<void> _updateLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client
          .from('return_requirements')
          .update({
            'current_location': '${_selectedLocation!.latitude},${_selectedLocation!.longitude}',
          })
          .eq('id', widget.requirementId);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Current Location', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          MapboxView(
            onTap: _onMapTap,
            markers: _selectedLocation != null
                ? [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    )
                  ]
                : null,
          ),
          if (_selectedLocation == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap on the map to set your current location',
                  style: TextStyle(color: Colors.white, textAlign: TextAlign.center),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Confirm Location',
                    onPressed: _selectedLocation == null ? () {} : _updateLocation,
                  ),
          )
        ],
      ),
    );
  }
}
