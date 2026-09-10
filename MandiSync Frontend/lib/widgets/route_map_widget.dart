// =========================================================
// MANDISYNC FLUTTER — DYNAMIC SMART LOGISTICS ROUTE MAP WIDGET
// Dynamically recalculates path, waypoints, and metrics based on selected route
// =========================================================

import 'package:flutter/material.dart';

class RouteWaypoint {
  final String name;
  final double x; // normalized 0.0 - 1.0
  final double y; // normalized 0.0 - 1.0

  const RouteWaypoint(this.name, this.x, this.y);
}

class RouteDetails {
  final String origin;
  final String destination;
  final double distanceKm;
  final String estimatedHours;
  final int co2SavedPct;
  final String sharedFarmers;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final List<RouteWaypoint> waypoints;

  const RouteDetails({
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.estimatedHours,
    required this.co2SavedPct,
    required this.sharedFarmers,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.waypoints,
  });

  static RouteDetails resolve(String rawOrigin, String rawDest) {
    final orig = rawOrigin.trim().toLowerCase();
    final dest = rawDest.trim().toLowerCase();

    // 1. Ludhiana to Delhi
    if (orig.contains("ludhiana") || dest.contains("delhi")) {
      if (orig.contains("ludhiana")) {
        return const RouteDetails(
          origin: "Ludhiana, Punjab",
          destination: "Delhi, NCR",
          distanceKm: 180,
          estimatedHours: "4.5 hours",
          co2SavedPct: 28,
          sharedFarmers: "3 Farmers • 1 Truck",
          startX: 0.20,
          startY: 0.22,
          endX: 0.72,
          endY: 0.82,
          waypoints: [
            RouteWaypoint("Ambala", 0.38, 0.42),
            RouteWaypoint("Panipat", 0.54, 0.65),
          ],
        );
      }
    }

    // 2. Nashik to Mumbai
    if (orig.contains("nashik") || (orig.contains("mumbai") && dest.contains("nashik")) || dest.contains("mumbai")) {
      if (orig.contains("nashik") || dest.contains("mumbai")) {
        return const RouteDetails(
          origin: "Nashik, Maharashtra",
          destination: "Mumbai, Maharashtra",
          distanceKm: 168,
          estimatedHours: "3.8 hours",
          co2SavedPct: 32,
          sharedFarmers: "2 Farmers • 1 Truck",
          startX: 0.22,
          startY: 0.25,
          endX: 0.78,
          endY: 0.82,
          waypoints: [
            RouteWaypoint("Kasara Ghat", 0.42, 0.46),
            RouteWaypoint("Kalyan APMC", 0.60, 0.66),
          ],
        );
      }
    }

    // 3. Indore to Ahmedabad
    if (orig.contains("indore") || dest.contains("ahmedabad")) {
      return const RouteDetails(
        origin: "Indore, Madhya Pradesh",
        destination: "Ahmedabad, Gujarat",
        distanceKm: 385,
        estimatedHours: "6.5 hours",
        co2SavedPct: 35,
        sharedFarmers: "4 Farmers • 1 Truck",
        startX: 0.18,
        startY: 0.25,
        endX: 0.82,
        endY: 0.78,
        waypoints: [
          RouteWaypoint("Dhar Mandi", 0.38, 0.40),
          RouteWaypoint("Godhra Bypass", 0.62, 0.60),
        ],
      );
    }

    // 4. Jaipur to Delhi
    if (orig.contains("jaipur")) {
      return const RouteDetails(
        origin: "Jaipur, Rajasthan",
        destination: "Delhi, NCR",
        distanceKm: 280,
        estimatedHours: "4.5 hours",
        co2SavedPct: 30,
        sharedFarmers: "3 Farmers • 1 Truck",
        startX: 0.22,
        startY: 0.78,
        endX: 0.75,
        endY: 0.25,
        waypoints: [
          RouteWaypoint("Kotputli", 0.40, 0.58),
          RouteWaypoint("Gurgaon Hub", 0.60, 0.38),
        ],
      );
    }

    // 5. Pune to Mumbai
    if (orig.contains("pune")) {
      return const RouteDetails(
        origin: "Pune, Maharashtra",
        destination: "Mumbai, Maharashtra",
        distanceKm: 150,
        estimatedHours: "3.0 hours",
        co2SavedPct: 26,
        sharedFarmers: "2 Farmers • 1 Truck",
        startX: 0.25,
        startY: 0.75,
        endX: 0.78,
        endY: 0.28,
        waypoints: [
          RouteWaypoint("Lonavala", 0.48, 0.52),
          RouteWaypoint("Navi Mumbai", 0.66, 0.38),
        ],
      );
    }

    // Dynamic fallback for any user-typed city
    final cleanOrig = rawOrigin.isEmpty ? "Origin Mandi" : rawOrigin;
    final cleanDest = rawDest.isEmpty ? "Destination Market" : rawDest;
    final dist = ((cleanOrig.length * 17 + cleanDest.length * 23) % 350 + 120).toDouble();
    final hrs = (dist / 45.0).toStringAsFixed(1);
    final co2 = (22 + (dist.toInt() % 16));

    return RouteDetails(
      origin: cleanOrig,
      destination: cleanDest,
      distanceKm: dist,
      estimatedHours: "$hrs hours",
      co2SavedPct: co2,
      sharedFarmers: "3 Farmers • 1 Truck",
      startX: 0.20,
      startY: 0.25,
      endX: 0.78,
      endY: 0.80,
      waypoints: [
        RouteWaypoint("Central Corridor Hub", 0.42, 0.45),
        RouteWaypoint("Regional APMC Gateway", 0.62, 0.65),
      ],
    );
  }
}

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

class _RouteMapWidgetState extends State<RouteMapWidget> with SingleTickerProviderStateMixin {
  double _zoom = 1.0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = RouteDetails.resolve(widget.origin, widget.destination);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFE7E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                  Expanded(flex: 3, child: _buildMapCanvas(route)),
                  Container(width: 1, color: const Color(0xFFDFE7E2)),
                  Expanded(flex: 2, child: _buildMetricsSidebar(route)),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                SizedBox(height: 250, child: _buildMapCanvas(route)),
                const Divider(height: 1, color: Color(0xFFDFE7E2)),
                _buildMetricsSidebar(route),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMapCanvas(RouteDetails route) {
    return Stack(
      children: [
        // Custom Styled Dynamic Map Canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _DynamicRouteMapPainter(
                  route: route,
                  zoom: _zoom,
                  pulseValue: _pulseCtrl.value,
                ),
              );
            },
          ),
        ),

        // Corridor badge on top left of map
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDFE7E2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  "${route.origin.split(',')[0]} ➔ ${route.destination.split(',')[0]}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF123B2A)),
                ),
              ],
            ),
          ),
        ),

        // Zoom Controls
        Positioned(
          left: 14,
          bottom: 14,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _zoom = (_zoom + 0.15).clamp(0.8, 1.6)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 18, color: Color(0xFF123B2A)),
                  ),
                ),
                Container(height: 1, width: 28, color: Colors.grey[200]),
                InkWell(
                  onTap: () => setState(() => _zoom = (_zoom - 0.15).clamp(0.8, 1.6)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.remove, size: 18, color: Color(0xFF123B2A)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSidebar(RouteDetails route) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSidebarMetric(
            icon: Icons.alt_route,
            iconColor: const Color(0xFF0B7A4B),
            title: "Optimized Route",
            value: "${route.distanceKm.toInt()} km",
            subtext: "(Total Distance)",
          ),
          const SizedBox(height: 16),
          _buildSidebarMetric(
            icon: Icons.groups,
            iconColor: const Color(0xFF0284C7),
            title: "Shared Transport",
            value: route.sharedFarmers,
            subtext: "Load Consolidation",
          ),
          const SizedBox(height: 16),
          _buildSidebarMetric(
            icon: Icons.schedule,
            iconColor: const Color(0xFFF59E0B),
            title: "Estimated Time",
            value: route.estimatedHours,
            subtext: "Direct Highway Transit",
          ),
          const SizedBox(height: 16),
          _buildSidebarMetric(
            icon: Icons.eco,
            iconColor: const Color(0xFF10B981),
            title: "CO₂ Saved",
            value: "${route.co2SavedPct}%",
            subtext: "(vs. individual trips)",
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMetric({
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
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF123B2A))),
              Text(subtext, style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }
}

class _DynamicRouteMapPainter extends CustomPainter {
  final RouteDetails route;
  final double zoom;
  final double pulseValue;

  _DynamicRouteMapPainter({
    required this.route,
    required this.zoom,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background map terrain
    final bgPaint = Paint()..color = const Color(0xFFF4F7F2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Geography / River curve
    final riverPaint = Paint()
      ..color = const Color(0xFFE1EFF5)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final riverPath = Path()
      ..moveTo(size.width * 0.05, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.35, size.width * 0.15, size.height * 0.95);
    canvas.drawPath(riverPath, riverPaint);

    // 3. Grid road network
    final secRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.3), secRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.65), secRoadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.35, size.height), secRoadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.75, size.height), secRoadPaint);

    // 4. Compute Dynamic Positions based on RouteDetails
    final pStart = Offset(size.width * route.startX, size.height * route.startY);
    final pEnd = Offset(size.width * route.endX, size.height * route.endY);

    final points = <Offset>[pStart];
    for (final wp in route.waypoints) {
      points.add(Offset(size.width * wp.x, size.height * wp.y));
    }
    points.add(pEnd);

    // 5. Build Smooth Highway Route Path
    final routePath = Path();
    routePath.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      final midY = (prev.dy + curr.dy) / 2;
      routePath.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
      routePath.lineTo(curr.dx, curr.dy);
    }

    // 6. Draw Route Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, glowPaint);

    // 7. Draw Core Highway Line (Dark Green)
    final routePaint = Paint()
      ..color = const Color(0xFF0B7A4B)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routePaint);

    // 8. Draw Intermediate Waypoints
    for (int i = 0; i < route.waypoints.length; i++) {
      final wp = route.waypoints[i];
      final pos = Offset(size.width * wp.x, size.height * wp.y);
      _drawWaypointPin(canvas, pos, wp.name);
    }

    // 9. Draw Origin Pin (Green Pulse)
    final originName = route.origin.split(',')[0];
    _drawEndpointPin(
      canvas,
      pStart,
      originName,
      const Color(0xFF0B7A4B),
      isOrigin: true,
      pulse: pulseValue,
    );

    // 10. Draw Destination Pin (Red Pulse)
    final destName = route.destination.split(',')[0];
    _drawEndpointPin(
      canvas,
      pEnd,
      destName,
      const Color(0xFFEF4444),
      isOrigin: false,
      pulse: pulseValue,
    );
  }

  void _drawWaypointPin(Canvas canvas, Offset pos, String name) {
    canvas.drawCircle(pos, 5, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 4, Paint()..color = const Color(0xFF075B38));

    final span = TextSpan(
      text: name,
      style: const TextStyle(color: Color(0xFF374151), fontSize: 10, fontWeight: FontWeight.w700),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(pos.dx + 8, pos.dy - 6));
  }

  void _drawEndpointPin(
    Canvas canvas,
    Offset pos,
    String name,
    Color color, {
    required bool isOrigin,
    required double pulse,
  }) {
    // Pulse animation ring
    final pulseRadius = 8 + (pulse * 7);
    canvas.drawCircle(
      pos,
      pulseRadius,
      Paint()..color = color.withValues(alpha: (1.0 - pulse) * 0.4),
    );

    // Center pin
    canvas.drawCircle(pos, 7, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 5, Paint()..color = color);

    // Label banner
    final span = TextSpan(
      text: name,
      style: const TextStyle(
        color: Color(0xFF123B2A),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    final labelOffset = Offset(pos.dx + 12, pos.dy - 9);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelOffset.dx - 4, labelOffset.dy - 2, tp.width + 8, tp.height + 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.white);
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFDFE7E2)..style = PaintingStyle.stroke);
    tp.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _DynamicRouteMapPainter oldDelegate) {
    return oldDelegate.route != route || oldDelegate.zoom != zoom || oldDelegate.pulseValue != pulseValue;
  }
}
