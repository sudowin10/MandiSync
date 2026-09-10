// =========================================================
// MANDISYNC FLUTTER — OPENSTREETMAP LOGISTICS MAP WIDGET
// Uses flutter_map + OpenStreetMap tiles (free, no API key)
// Real OSRM routing for live route polylines
// =========================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// ─── City geocode database (lat/lng for Indian agri cities) ─────────────────
class _CityCoord {
  final double lat;
  final double lng;
  final String displayName;
  const _CityCoord(this.lat, this.lng, this.displayName);
}

const Map<String, _CityCoord> _cityDB = {
  'ludhiana': _CityCoord(30.9010, 75.8573, 'Ludhiana'),
  'delhi': _CityCoord(28.6139, 77.2090, 'Delhi'),
  'nashik': _CityCoord(19.9975, 73.7898, 'Nashik'),
  'mumbai': _CityCoord(19.0760, 72.8777, 'Mumbai'),
  'indore': _CityCoord(22.7196, 75.8577, 'Indore'),
  'ahmedabad': _CityCoord(23.0225, 72.5714, 'Ahmedabad'),
  'jaipur': _CityCoord(26.9124, 75.7873, 'Jaipur'),
  'pune': _CityCoord(18.5204, 73.8567, 'Pune'),
  'chandigarh': _CityCoord(30.7333, 76.7794, 'Chandigarh'),
  'amritsar': _CityCoord(31.6340, 74.8723, 'Amritsar'),
  'hyderabad': _CityCoord(17.3850, 78.4867, 'Hyderabad'),
  'bangalore': _CityCoord(12.9716, 77.5946, 'Bangalore'),
  'chennai': _CityCoord(13.0827, 80.2707, 'Chennai'),
  'kolkata': _CityCoord(22.5726, 88.3639, 'Kolkata'),
  'bhopal': _CityCoord(23.2599, 77.4126, 'Bhopal'),
  'nagpur': _CityCoord(21.1458, 79.0882, 'Nagpur'),
  'surat': _CityCoord(21.1702, 72.8311, 'Surat'),
  'lucknow': _CityCoord(26.8467, 80.9462, 'Lucknow'),
  'patna': _CityCoord(25.5941, 85.1376, 'Patna'),
  'kota': _CityCoord(25.2138, 75.8648, 'Kota'),
  'agra': _CityCoord(27.1767, 78.0081, 'Agra'),
  'varanasi': _CityCoord(25.3176, 82.9739, 'Varanasi'),
  'coimbatore': _CityCoord(11.0168, 76.9558, 'Coimbatore'),
  'visakhapatnam': _CityCoord(17.6868, 83.2185, 'Visakhapatnam'),
  'rajkot': _CityCoord(22.3039, 70.8022, 'Rajkot'),
  'vadodara': _CityCoord(22.3072, 73.1812, 'Vadodara'),
};

_CityCoord? _resolveCity(String query) {
  final q = query.toLowerCase().trim();
  for (final key in _cityDB.keys) {
    if (q.contains(key)) return _cityDB[key];
  }
  return null;
}

// ─── Route data model ────────────────────────────────────────────────────────
class RouteDetails {
  final String origin;
  final String destination;
  final double distanceKm;
  final String estimatedHours;
  final int co2SavedPct;
  final String sharedFarmers;

  const RouteDetails({
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.estimatedHours,
    required this.co2SavedPct,
    required this.sharedFarmers,
  });
}

// ─── Main Widget ─────────────────────────────────────────────────────────────
class RouteMapWidget extends StatefulWidget {
  final String origin;
  final String destination;
  final Function(String, String)? onQuickSelect;

  const RouteMapWidget({
    super.key,
    required this.origin,
    required this.destination,
    this.onQuickSelect,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  final MapController _mapController = MapController();

  bool _isLoading = false;
  String? _errorMsg;

  List<LatLng> _routePoints = [];
  RouteDetails? _routeDetails;

  _CityCoord? _originCoord;
  _CityCoord? _destCoord;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    final originCoord = _resolveCity(widget.origin);
    final destCoord = _resolveCity(widget.destination);

    if (originCoord == null || destCoord == null) {
      setState(() {
        _errorMsg =
            'Could not locate "${originCoord == null ? widget.origin : widget.destination}". Try a major Indian city.';
        _routePoints = [];
        _routeDetails = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _originCoord = originCoord;
      _destCoord = destCoord;
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${originCoord.lng},${originCoord.lat};'
        '${destCoord.lng},${destCoord.lat}'
        '?overview=full&geometries=geojson',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes[0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();

          final distanceM = (route['distance'] as num).toDouble();
          final durationS = (route['duration'] as num).toDouble();
          final distKm = distanceM / 1000.0;
          final hours = durationS / 3600.0;
          final hStr = '${hours.toStringAsFixed(1)} hours';

          setState(() {
            _routePoints = points;
            _routeDetails = RouteDetails(
              origin: originCoord.displayName,
              destination: destCoord.displayName,
              distanceKm: distKm,
              estimatedHours: hStr,
              co2SavedPct: (22 + (distKm % 16).toInt()).clamp(22, 40),
              sharedFarmers:
                  distKm > 300 ? '4 Farmers • 2 Trucks' : '3 Farmers • 1 Truck',
            );
            _isLoading = false;
          });

          if (points.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                final bounds = LatLngBounds.fromPoints(points);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(48),
                  ),
                );
              }
            });
          }
        } else {
          _setFallback(originCoord, destCoord, 'No route found between cities.');
        }
      } else {
        _setFallback(
            originCoord, destCoord, 'Route service unavailable. Showing direct path.');
      }
    } catch (_) {
      _setFallback(
        originCoord,
        destCoord,
        'Offline or timeout — showing straight-line estimate.',
      );
    }
  }

  void _setFallback(_CityCoord orig, _CityCoord dest, String msg) {
    final distKm = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(orig.lat, orig.lng),
      LatLng(dest.lat, dest.lng),
    );
    setState(() {
      _isLoading = false;
      _errorMsg = msg;
      _routePoints = [LatLng(orig.lat, orig.lng), LatLng(dest.lat, dest.lng)];
      _routeDetails = RouteDetails(
        origin: orig.displayName,
        destination: dest.displayName,
        distanceKm: distKm,
        estimatedHours: '${(distKm / 60).toStringAsFixed(1)} hours (est.)',
        co2SavedPct: 28,
        sharedFarmers: '3 Farmers • 1 Truck',
      );
    });
  }

  LatLng get _mapCenter {
    if (_originCoord != null && _destCoord != null) {
      return LatLng(
        (_originCoord!.lat + _destCoord!.lat) / 2,
        (_originCoord!.lng + _destCoord!.lng) / 2,
      );
    }
    return const LatLng(22.5, 78.9);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFE7E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildMapArea()),
                  Container(width: 1, color: const Color(0xFFDFE7E2)),
                  Expanded(flex: 2, child: _buildMetricsSidebar()),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                SizedBox(height: 280, child: _buildMapArea()),
                const Divider(height: 1, color: Color(0xFFDFE7E2)),
                _buildMetricsSidebar(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMapArea() {
    return Stack(
      children: [
        SizedBox(
          height: 380,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 6.0,
              minZoom: 4.0,
              maxZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mandisync.app',
                maxZoom: 19,
                tileBuilder: _warmTileBuilder,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 10.0,
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF0B7A4B),
                    ),
                  ],
                ),
              if (_originCoord != null && _destCoord != null)
                MarkerLayer(
                  markers: [
                    _buildMarker(
                      LatLng(_originCoord!.lat, _originCoord!.lng),
                      _originCoord!.displayName,
                      const Color(0xFF0B7A4B),
                      Icons.location_on,
                    ),
                    _buildMarker(
                      LatLng(_destCoord!.lat, _destCoord!.lng),
                      _destCoord!.displayName,
                      const Color(0xFFEF4444),
                      Icons.pin_drop,
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // Corridor badge
        if (_routeDetails != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDFE7E2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                      radius: 4, backgroundColor: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    '${_routeDetails!.origin} \u279E ${_routeDetails!.destination}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFF123B2A),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Warning banner
        if (_errorMsg != null)
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                          fontSize: 10.5, color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Loading overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.75),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFF0B7A4B), strokeWidth: 3),
                    SizedBox(height: 10),
                    Text(
                      'Calculating optimal route\u2026',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0B7A4B),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Zoom controls
        Positioned(
          right: 12,
          bottom: 40,
          child: _buildZoomControls(),
        ),

        // Recenter
        Positioned(
          right: 12,
          bottom: 110,
          child: _buildRecenterButton(),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final cam = _mapController.camera;
              _mapController.move(
                  cam.center, (cam.zoom + 1).clamp(4.0, 16.0));
            },
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, size: 18, color: Color(0xFF123B2A)),
            ),
          ),
          Container(height: 1, width: 30, color: Colors.grey[200]),
          InkWell(
            onTap: () {
              final cam = _mapController.camera;
              _mapController.move(
                  cam.center, (cam.zoom - 1).clamp(4.0, 16.0));
            },
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(Icons.remove, size: 18, color: Color(0xFF123B2A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (_routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(
              CameraFit.bounds(
                  bounds: bounds, padding: const EdgeInsets.all(48)),
            );
          } else {
            _mapController.move(_mapCenter, 6.0);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child:
              Icon(Icons.my_location, size: 18, color: Color(0xFF0B7A4B)),
        ),
      ),
    );
  }

  Marker _buildMarker(
      LatLng point, String label, Color color, IconData icon) {
    return Marker(
      point: point,
      width: 140,
      height: 60,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }

  Widget _warmTileBuilder(
      BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.95, 0, 0, 0, 0,
        0, 0.97, 0, 0, 0,
        0, 0, 0.92, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  Widget _buildMetricsSidebar() {
    if (_isLoading && _routeDetails == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF0B7A4B), strokeWidth: 2),
        ),
      );
    }

    if (_routeDetails == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined,
                size: 48, color: Color(0xFFDFE7E2)),
            const SizedBox(height: 12),
            const Text(
              'Enter origin and destination\nto see route details',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Supported: Ludhiana, Delhi, Nashik,\nMumbai, Indore, Ahmedabad, Jaipur,\nPune, Hyderabad, Bangalore\u2026',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      );
    }

    final r = _routeDetails!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMetricRow(
            icon: Icons.alt_route,
            iconColor: const Color(0xFF0B7A4B),
            title: 'Optimized Route',
            value: '${r.distanceKm.toStringAsFixed(0)} km',
            subtext: 'OSRM road distance',
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            icon: Icons.groups,
            iconColor: const Color(0xFF0284C7),
            title: 'Shared Transport',
            value: r.sharedFarmers,
            subtext: 'Load Consolidation',
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            icon: Icons.schedule,
            iconColor: const Color(0xFFF59E0B),
            title: 'Estimated Time',
            value: r.estimatedHours,
            subtext: 'Highway transit',
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            icon: Icons.eco,
            iconColor: const Color(0xFF10B981),
            title: 'CO\u2082 Saved',
            value: '${r.co2SavedPct}%',
            subtext: 'vs. individual trips',
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFE7E2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined,
                    size: 13, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Powered by OpenStreetMap + OSRM',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtext,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          radius: 18,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123B2A))),
              Text(subtext,
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }
}
