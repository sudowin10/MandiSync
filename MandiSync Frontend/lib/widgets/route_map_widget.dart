// =========================================================
// MANDISYNC FLUTTER — OPENSTREETMAP LOGISTICS MAP WIDGET
// flutter_map + OSM tiles (free) + OSRM real road routing
// =========================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// ─── Hardcoded geocoords for Indian agri-cities ──────────────────────────────
class _City {
  final double lat;
  final double lng;
  final String name;
  const _City(this.lat, this.lng, this.name);
}

const Map<String, _City> _db = {
  'ludhiana':     _City(30.9010, 75.8573, 'Ludhiana'),
  'delhi':        _City(28.6139, 77.2090, 'Delhi'),
  'ncr':          _City(28.6139, 77.2090, 'Delhi'),
  'nashik':       _City(19.9975, 73.7898, 'Nashik'),
  'mumbai':       _City(19.0760, 72.8777, 'Mumbai'),
  'indore':       _City(22.7196, 75.8577, 'Indore'),
  'ahmedabad':    _City(23.0225, 72.5714, 'Ahmedabad'),
  'jaipur':       _City(26.9124, 75.7873, 'Jaipur'),
  'pune':         _City(18.5204, 73.8567, 'Pune'),
  'chandigarh':   _City(30.7333, 76.7794, 'Chandigarh'),
  'amritsar':     _City(31.6340, 74.8723, 'Amritsar'),
  'hyderabad':    _City(17.3850, 78.4867, 'Hyderabad'),
  'bangalore':    _City(12.9716, 77.5946, 'Bangalore'),
  'bengaluru':    _City(12.9716, 77.5946, 'Bangalore'),
  'chennai':      _City(13.0827, 80.2707, 'Chennai'),
  'kolkata':      _City(22.5726, 88.3639, 'Kolkata'),
  'bhopal':       _City(23.2599, 77.4126, 'Bhopal'),
  'nagpur':       _City(21.1458, 79.0882, 'Nagpur'),
  'surat':        _City(21.1702, 72.8311, 'Surat'),
  'lucknow':      _City(26.8467, 80.9462, 'Lucknow'),
  'patna':        _City(25.5941, 85.1376, 'Patna'),
  'agra':         _City(27.1767, 78.0081, 'Agra'),
  'varanasi':     _City(25.3176, 82.9739, 'Varanasi'),
  'rajkot':       _City(22.3039, 70.8022, 'Rajkot'),
  'vadodara':     _City(22.3072, 73.1812, 'Vadodara'),
  'coimbatore':   _City(11.0168, 76.9558, 'Coimbatore'),
  'visakhapatnam':_City(17.6868, 83.2185, 'Visakhapatnam'),
};

_City? _resolve(String q) {
  final s = q.toLowerCase().trim();
  for (final k in _db.keys) {
    if (s.contains(k)) return _db[k];
  }
  return null;
}

// ─── Route model ─────────────────────────────────────────────────────────────
class RouteInfo {
  final double distKm;
  final double durationHrs;
  final int co2Pct;
  const RouteInfo(this.distKm, this.durationHrs, this.co2Pct);
}

// ─── Widget ──────────────────────────────────────────────────────────────────
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
  final MapController _map = MapController();

  // State
  bool _loading = false;
  bool _isRouteFetched = false;
  String? _warn;
  List<LatLng> _poly = [];
  RouteInfo? _info;
  _City? _orig;
  _City? _dest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RouteMapWidget old) {
    super.didUpdateWidget(old);
    if (old.origin != widget.origin || old.destination != widget.destination) {
      _load();
    }
  }

  Future<void> _load() async {
    final o = _resolve(widget.origin);
    final d = _resolve(widget.destination);

    if (o == null || d == null) {
      if (mounted) {
        setState(() {
          _warn = 'Unknown city: "${o == null ? widget.origin : widget.destination}". Try Ludhiana, Delhi, Mumbai, Pune…';
          _poly = [];
          _info = null;
          _isRouteFetched = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _warn = null;
        _orig = o;
        _dest = d;
        _isRouteFetched = false;
      });
    }

    // Move map immediately to show cities while route loads
    final midLat = (o.lat + d.lat) / 2;
    final midLng = (o.lng + d.lng) / 2;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _map.move(LatLng(midLat, midLng), 6.5);
    });

    await _fetchOSRM(o, d);
  }

  Future<void> _fetchOSRM(_City o, _City d) async {
    try {
      // Using OSRM public demo server with explicit headers
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${o.lng},${o.lat};${d.lng},${d.lat}'
        '?overview=full&geometries=geojson&steps=false',
      );

      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final code = body['code'] as String?;

        if (code == 'Ok') {
          final routes = body['routes'] as List;
          if (routes.isNotEmpty) {
            final r = routes[0] as Map<String, dynamic>;
            final coords = (r['geometry']['coordinates'] as List)
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
            final distM = (r['distance'] as num).toDouble();
            final durS  = (r['duration'] as num).toDouble();

            setState(() {
              _poly = coords;
              _info = RouteInfo(distM / 1000, durS / 3600, _co2(distM / 1000));
              _loading = false;
              _warn = null;
              _isRouteFetched = true;
            });

            // Fit bounds with padding
            await Future.delayed(const Duration(milliseconds: 150));
            if (mounted && coords.isNotEmpty) {
              _map.fitCamera(CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(coords),
                padding: const EdgeInsets.all(52),
              ));
            }
            return;
          }
        }
      }
      // Non-200 or bad code → fallback
      _useFallback(o, d, 'Route API busy — showing straight-line estimate.');
    } catch (e) {
      if (mounted) {
        _useFallback(o, d, 'No internet or timeout — showing straight-line estimate.');
      }
    }
  }

  void _useFallback(_City o, _City d, String msg) {
    final dist = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(o.lat, o.lng),
      LatLng(d.lat, d.lng),
    );
    setState(() {
      _loading = false;
      _warn = msg;
      _poly = [LatLng(o.lat, o.lng), LatLng(d.lat, d.lng)];
      _info = RouteInfo(dist, dist / 65, _co2(dist));
      _isRouteFetched = false;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _map.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_poly),
          padding: const EdgeInsets.all(80),
        ));
      }
    });
  }

  int _co2(double km) => (22 + (km % 16).toInt()).clamp(22, 40);

  LatLng get _center {
    if (_orig != null && _dest != null) {
      return LatLng((_orig!.lat + _dest!.lat) / 2, (_orig!.lng + _dest!.lng) / 2);
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (ctx, box) {
        final isWide = box.maxWidth >= 720;
        if (isWide) {
          return SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _mapArea()),
                Container(width: 1, color: const Color(0xFFDFE7E2)),
                SizedBox(width: box.maxWidth * 0.38, child: _sidebar()),
              ],
            ),
          );
        } else {
          return Column(children: [
            SizedBox(height: 280, child: _mapArea()),
            const Divider(height: 1, color: Color(0xFFDFE7E2)),
            _sidebar(),
          ]);
        }
      }),
    );
  }

  // ── Map area ────────────────────────────────────────────────────────────────
  Widget _mapArea() {
    return Stack(
      children: [
        // ─── OSM Map ──────────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 6.5,
              minZoom: 4.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Standard OSM tile layer — NO color filter so tiles are fully visible
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mandisync.app',
                maxZoom: 19,
              ),

              // Route polyline — glow + core
              if (_poly.isNotEmpty) ...[
                PolylineLayer(polylines: [
                  Polyline(
                    points: _poly,
                    strokeWidth: 12,
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                  Polyline(
                    points: _poly,
                    strokeWidth: !_isRouteFetched ? 3.5 : 5.5,
                    color: !_isRouteFetched
                        ? const Color(0xFF0B7A4B).withValues(alpha: 0.7)
                        : const Color(0xFF0B7A4B),
                    strokeCap: StrokeCap.round,
                  ),
                ]),
              ],

              // Origin & Destination markers
              if (_orig != null && _dest != null)
                MarkerLayer(markers: [
                  _pin(LatLng(_orig!.lat, _orig!.lng), _orig!.name, const Color(0xFF0B7A4B), Icons.location_on_rounded),
                  _pin(LatLng(_dest!.lat, _dest!.lng), _dest!.name, const Color(0xFFEF4444), Icons.flag_rounded),
                ]),

              // Required attribution
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10, color: Colors.black54)),
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),

        // ─── Corridor badge ────────────────────────────────────
        if (_orig != null && _dest != null)
          Positioned(
            top: 12, left: 12,
            child: _badge(
              Row(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  '${_orig!.name} \u279E ${_dest!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF123B2A)),
                ),
              ]),
            ),
          ),

        // ─── Warning banner ────────────────────────────────────
        if (_warn != null)
          Positioned(
            bottom: 8, left: 8, right: 56,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 5),
                Expanded(child: Text(_warn!, style: const TextStyle(fontSize: 10.5, color: Color(0xFF856404)))),
              ]),
            ),
          ),

        // ─── Loading overlay ───────────────────────────────────
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.65),
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Color(0xFF0B7A4B), strokeWidth: 3),
                  SizedBox(height: 8),
                  Text('Finding road route\u2026',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0B7A4B), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),

        // ─── Zoom controls (right side) ────────────────────────
        Positioned(
          right: 10, bottom: 36,
          child: _zoomControls(),
        ),

        // ─── Fit-route button ──────────────────────────────────
        Positioned(
          right: 10, bottom: 104,
          child: _iconBtn(Icons.fit_screen, () {
            if (_poly.isNotEmpty) {
              _map.fitCamera(CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(_poly),
                padding: const EdgeInsets.all(52),
              ));
            }
          }),
        ),
      ],
    );
  }

  // ── Markers ─────────────────────────────────────────────────────────────────
  Marker _pin(LatLng p, String label, Color color, IconData icon) {
    return Marker(
      point: p,
      width: 130,
      height: 58,
      alignment: Alignment.topCenter,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        ),
        Icon(icon, color: color, size: 26),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _badge(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDFE7E2)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
    ),
    child: child,
  );

  Widget _zoomControls() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(children: [
      _iconBtn(Icons.add, () {
        final c = _map.camera;
        _map.move(c.center, (c.zoom + 1).clamp(4.0, 18.0));
      }, topRadius: true),
      Container(height: 1, width: 32, color: Colors.grey[200]),
      _iconBtn(Icons.remove, () {
        final c = _map.camera;
        _map.move(c.center, (c.zoom - 1).clamp(4.0, 18.0));
      }, bottomRadius: true),
    ]),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool topRadius = false, bool bottomRadius = false}) {
    final radius = BorderRadius.only(
      topLeft:     topRadius    ? const Radius.circular(8) : Radius.zero,
      topRight:    topRadius    ? const Radius.circular(8) : Radius.zero,
      bottomLeft:  bottomRadius ? const Radius.circular(8) : Radius.zero,
      bottomRight: bottomRadius ? const Radius.circular(8) : Radius.zero,
    );

    // Standalone icon button (no top/bottom radius means it is standalone)
    final effectiveRadius = (!topRadius && !bottomRadius)
        ? BorderRadius.circular(8)
        : radius;

    return Material(
      color: Colors.white,
      borderRadius: effectiveRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: Container(
          decoration: (!topRadius && !bottomRadius)
              ? BoxDecoration(
                  borderRadius: effectiveRadius,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: const Color(0xFF123B2A)),
          ),
        ),
      ),
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────────
  Widget _sidebar() {
    if (_loading && _info == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF0B7A4B), strokeWidth: 2)),
      );
    }
    if (_info == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.map_outlined, size: 48, color: Color(0xFFDFE7E2)),
          const SizedBox(height: 12),
          const Text('Enter origin & destination\nto see route details',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(height: 10),
          Text('Ludhiana, Delhi, Nashik,\nMumbai, Indore, Ahmedabad,\nJaipur, Pune, Hyderabad…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ]),
      );
    }

    final r = _info!;
    final farmers = r.distKm > 300 ? '4 Farmers • 2 Trucks' : '3 Farmers • 1 Truck';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _metric(Icons.alt_route,   const Color(0xFF0B7A4B), 'Optimized Route',
              '${r.distKm.toStringAsFixed(0)} km',
              _isRouteFetched ? 'Real road distance (OSRM)' : 'Straight-line estimate'),
          const SizedBox(height: 16),
          _metric(Icons.groups,      const Color(0xFF0284C7), 'Shared Transport',
              farmers, 'Load Consolidation'),
          const SizedBox(height: 16),
          _metric(Icons.schedule,    const Color(0xFFF59E0B), 'Estimated Time',
              '${r.durationHrs.toStringAsFixed(1)} hrs',
              _isRouteFetched ? 'Based on OSRM routing' : 'Estimated @ 65 km/h'),
          const SizedBox(height: 16),
          _metric(Icons.eco,         const Color(0xFF10B981), 'CO\u2082 Saved',
              '${r.co2Pct}%', 'vs. individual trips'),
          const SizedBox(height: 18),
          // Credit badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFE7E2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _isRouteFetched ? Icons.route : Icons.show_chart,
                size: 12,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                _isRouteFetched ? 'Road route via OSRM + OpenStreetMap' : 'OpenStreetMap (road route loading\u2026)',
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, Color c, String title, String value, String sub) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        backgroundColor: c.withValues(alpha: 0.1),
        radius: 18,
        child: Icon(icon, color: c, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF123B2A))),
        Text(sub,   style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
      ])),
    ]);
  }
}
