import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapboxView extends StatelessWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker>? markers;
  final void Function(TapPosition, LatLng)? onTap;

  const MapboxView({
    super.key,
    this.initialCenter = const LatLng(23.0225, 72.5714), // Default Ahmedabad
    this.initialZoom = 13.0,
    this.markers,
    this.onTap,
  });

  // Mapbox Access Token
  // TODO: Use flutter_dotenv or similar for secure storage. Hardcoded token removed for github push.
  static const String _mapboxToken = 'pk.eyJ1IjoidG9tODE1NSIsImEiOiJjbXJheGkzZHoyNms2MndxcmE2N3NidzFhIn0.UT6Ql_m2sJScB7mKiIN9MQ';
  
  // You can change 'streets-v12' to 'navigation-day-v1' or 'satellite-v9' etc.
  static const String _mapboxStyle = 'mapbox/streets-v12';

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: onTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: {
            'accessToken': _mapboxToken,
            'id': _mapboxStyle,
          },
        ),
        if (markers != null && markers!.isNotEmpty)
          MarkerLayer(
            markers: markers!,
          ),
      ],
    );
  }
}
