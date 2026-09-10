// =========================================================
// MANDISYNC FLUTTER — SMART LOGISTICS SCREEN
// Fully Dynamic Multi-Corridor Route Mapping Engine
// Matches Reference Image Screen 3 with Live Route Switching
// =========================================================

import 'package:flutter/material.dart';
import '../widgets/route_map_widget.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  final TextEditingController _fromCtrl = TextEditingController(text: "Ludhiana, Punjab");
  final TextEditingController _toCtrl = TextEditingController(text: "Delhi, NCR");

  String _currentOrigin = "Ludhiana, Punjab";
  String _currentDest = "Delhi, NCR";
  bool _isSearching = false;

  void _handleFindRoutes({String? from, String? to}) {
    final newFrom = from ?? _fromCtrl.text.trim();
    final newTo = to ?? _toCtrl.text.trim();

    setState(() {
      _fromCtrl.text = newFrom;
      _toCtrl.text = newTo;
      _currentOrigin = newFrom;
      _currentDest = newTo;
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Optimized shared route mapped for: $newFrom ➔ $newTo"),
            backgroundColor: const Color(0xFF0B7A4B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _bookShipment(String crop, String route, String price) {
    // Also select this route on the map
    final parts = route.split("➔");
    if (parts.length == 2) {
      _handleFindRoutes(from: parts[0].trim(), to: parts[1].trim());
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF0B7A4B)),
            SizedBox(width: 8),
            Text("Confirm Freight Booking"),
          ],
        ),
        content: Text(
          "Book shared transport for $crop on route $route at $price?\n\n"
          "Backhaul matching saves freight cost and guarantees direct delivery to buyer APMC.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Booking confirmed for $crop on route $route!"),
                  backgroundColor: const Color(0xFF0B7A4B),
                ),
              );
            },
            child: const Text("Confirm & Reserve Slot"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Body Wrapper
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER SECTION
                    _buildLogisticsHeader(isDesktop),

                    const SizedBox(height: 18),

                    // 2. ROUTE SEARCH BAR
                    _buildRouteSearchBar(isDesktop),

                    const SizedBox(height: 12),

                    // 3. QUICK CORRIDOR PRESET CHIPS
                    _buildQuickPresetChips(),

                    const SizedBox(height: 18),

                    // 4. DYNAMIC ROUTE MAP & METRICS
                    RouteMapWidget(
                      origin: _currentOrigin,
                      destination: _currentDest,
                    ),

                    const SizedBox(height: 36),

                    // 5. AVAILABLE SHIPMENTS
                    _buildAvailableShipmentsHeader(),
                    const SizedBox(height: 14),
                    _buildAvailableShipmentsList(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // 6. DARK NAVY GOVERNMENT FOOTER
          _buildFooter(isDesktop),
        ],
      ),
    );
  }

  // --- 1. HEADER ---
  Widget _buildLogisticsHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Smart Logistics",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123B2A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Optimized shared transport for higher efficiency,\nlower costs and zero empty trips.",
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.35),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC7EBD7)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                "Live Tracking",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF075B38)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. ROUTE SEARCH BAR ---
  Widget _buildRouteSearchBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    decoration: const InputDecoration(
                      labelText: "From (Origin Mandi)",
                      hintText: "e.g. Nashik, Ludhiana, Indore",
                      prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF0B7A4B)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleFindRoutes(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _toCtrl,
                    decoration: const InputDecoration(
                      labelText: "To (Destination APMC)",
                      hintText: "e.g. Mumbai, Delhi, Ahmedabad",
                      prefixIcon: Icon(Icons.pin_drop_outlined, color: Color(0xFFEF4444)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleFindRoutes(),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : () => _handleFindRoutes(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3E29),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSearching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Find Routes", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                TextField(
                  controller: _fromCtrl,
                  decoration: const InputDecoration(
                    labelText: "From (Origin Mandi)",
                    prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF0B7A4B)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _toCtrl,
                  decoration: const InputDecoration(
                    labelText: "To (Destination APMC)",
                    prefixIcon: Icon(Icons.pin_drop_outlined, color: Color(0xFFEF4444)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : () => _handleFindRoutes(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3E29),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSearching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Find Routes", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }

  // --- 3. QUICK CORRIDOR PRESET CHIPS ---
  Widget _buildQuickPresetChips() {
    final presets = [
      {"label": "🌾 Ludhiana ➔ Delhi", "from": "Ludhiana, Punjab", "to": "Delhi, NCR"},
      {"label": "🍅 Nashik ➔ Mumbai", "from": "Nashik, Maharashtra", "to": "Mumbai, Maharashtra"},
      {"label": "🧅 Indore ➔ Ahmedabad", "from": "Indore, Madhya Pradesh", "to": "Ahmedabad, Gujarat"},
      {"label": "🥔 Jaipur ➔ Delhi", "from": "Jaipur, Rajasthan", "to": "Delhi, NCR"},
      {"label": "🌱 Pune ➔ Mumbai", "from": "Pune, Maharashtra", "to": "Mumbai, Maharashtra"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text("Quick Corridors: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          ...presets.map((p) {
            final isSelected = _currentOrigin.contains(p['from']!.split(',')[0]) && _currentDest.contains(p['to']!.split(',')[0]);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(p['label']!),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF0B7A4B) : const Color(0xFF334155),
                ),
                backgroundColor: isSelected ? const Color(0xFFEAF7F0) : Colors.white,
                side: BorderSide(color: isSelected ? const Color(0xFF0B7A4B) : const Color(0xFFDFE7E2)),
                onPressed: () => _handleFindRoutes(from: p['from'], to: p['to']),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 5. AVAILABLE SHIPMENTS ---
  Widget _buildAvailableShipmentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Available Shipments",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF123B2A)),
        ),
        InkWell(
          onTap: () {},
          child: const Row(
            children: [
              Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B))),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0B7A4B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableShipmentsList() {
    final shipments = [
      {
        "emoji": "🌾",
        "title": "Wheat — 50 MT",
        "route": "Ludhiana ➔ Delhi",
        "departure": "22 Apr 2025",
        "price": "₹ 2,350",
        "unit": "/Quintal",
        "badge": "Shared Load",
      },
      {
        "emoji": "🍅",
        "title": "Tomato — 30 MT",
        "route": "Nashik ➔ Mumbai",
        "departure": "24 Apr 2025",
        "price": "₹ 1,200",
        "unit": "/Quintal",
        "badge": "Shared Load",
      },
      {
        "emoji": "🧅",
        "title": "Onion — 25 MT",
        "route": "Indore ➔ Ahmedabad",
        "departure": "25 Apr 2025",
        "price": "₹ 1,560",
        "unit": "/Quintal",
        "badge": "Shared Load",
      },
    ];

    return Column(
      children: shipments.map((s) => _buildShipmentCard(s)).toList(),
    );
  }

  Widget _buildShipmentCard(Map<String, String> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDFE7E2)),
            ),
            child: Center(
              child: Text(s["emoji"]!, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s["title"]!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF123B2A)),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(s["route"]!, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text("•", style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(width: 8),
                    Text("Departure: ${s['departure']}", style: TextStyle(color: Colors.grey[500], fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    s["price"]!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF123B2A)),
                  ),
                  Text(
                    " ${s['unit']}",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  Text(
                    s["badge"]!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF075B38), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () => _bookShipment(s['title']!, s['route']!, s['price']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3E29),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  child: const Text("Book"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. DARK NAVY GOVERNMENT FOOTER ---
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: const Color(0xFF102837),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: isDesktop
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("🏛️", style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Government of India", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Text("Ministry of Agriculture & Farmers Welfare", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Privacy Policy", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        Text("   |   ", style: TextStyle(color: Color(0xFF475569))),
                        Text("Terms of Service", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        Text("   |   ", style: TextStyle(color: Color(0xFF475569))),
                        Text("Contact Us", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ],
                )
              : const Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("🏛️", style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Government of India", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Text("Ministry of Agriculture & Farmers Welfare", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
